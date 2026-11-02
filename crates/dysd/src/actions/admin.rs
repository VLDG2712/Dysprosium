//! Processes / Services / System settings calls (see crate::admin for the design).

use dys_core::pb::control_service_request::Action as SvcAction;
use dys_core::pb::signal_process_request::Signal;
use dys_core::pb::{
    AdminReply, ControlServiceRequest, GetSystemSettingsRequest, ProcessList, ServiceDetail, ServiceList,
    SetSystemSettingRequest, SignalProcessRequest, SystemSettings,
};
use tonic::Status;
use tracing::info;

use super::Actions;
use crate::admin::{processes, services, settings};

fn sysconf(name: libc::c_int, default: u64) -> u64 {
    // SAFETY: sysconf has no preconditions.
    let v = unsafe { libc::sysconf(name) };
    if v > 0 { v as u64 } else { default }
}

impl Actions {
    fn admin_read(&self, rel: &str) -> String {
        std::fs::read_to_string(self.admin.paths.path(rel)).unwrap_or_default()
    }

    fn btime(&self) -> u64 {
        self.admin_read("/proc/stat")
            .lines()
            .find_map(|l| l.strip_prefix("btime ")?.trim().parse().ok())
            .unwrap_or(0)
    }

    // ---- processes ----------------------------------------------------------------------------

    pub async fn list_processes(&self, lan: bool) -> ProcessList {
        let passwd = self.admin_read("/etc/passwd");
        let login_defs = self.admin_read("/etc/login.defs");
        let proc = self.admin.paths.proc();
        let processes = processes::list(processes::ListInput {
            proc: &proc,
            passwd: &passwd,
            login_defs: &login_defs,
            page_size: sysconf(libc::_SC_PAGESIZE, 4096),
            clk_tck: sysconf(libc::_SC_CLK_TCK, 100),
        })
        .await;
        ProcessList { access: Some(self.admin.access(lan)), processes }
    }

    pub async fn signal_process(&self, r: SignalProcessRequest, lan: bool) -> Result<AdminReply, Status> {
        self.admin.check_can_change(lan)?;
        let sig = match Signal::try_from(r.signal) {
            Ok(Signal::Term) => "TERM",
            Ok(Signal::Kill) => "KILL",
            _ => return Err(Status::invalid_argument("signal must be TERM or KILL")),
        };
        if r.pid <= 1 {
            return Err(Status::invalid_argument("bad pid"));
        }
        // Friendly answers first; the root script checks all of this again.
        let dir = self.admin.paths.proc().join(r.pid.to_string());
        let st = std::fs::read_to_string(dir.join("stat"))
            .ok()
            .and_then(|t| processes::parse_stat(&t))
            .ok_or_else(|| Status::not_found(format!("process {} is gone", r.pid)))?;
        if st.start_ticks != r.start_ticks {
            return Err(Status::not_found(format!("process {} is gone (the PID now belongs to another process)", r.pid)));
        }
        let (lo, hi) = processes::uid_range(&self.admin_read("/etc/login.defs"));
        let uids = std::fs::read_to_string(dir.join("status")).ok().and_then(|t| processes::parse_uids(&t));
        if !uids.is_some_and(|u| u.iter().all(|x| (lo..=hi).contains(x))) {
            return Err(Status::permission_denied(format!(
                "{} runs as a system user: only your own processes can be ended here (use Services for system ones)",
                st.name
            )));
        }
        let _g = self.admin_lock.lock().await;
        let message = self.admin.request(self.runner.as_ref(), &format!("kill {} {} {sig}", r.pid, r.start_ticks)).await?;
        info!(pid = r.pid, name = %st.name, sig, "process signalled");
        Ok(AdminReply { message })
    }

    // ---- services -----------------------------------------------------------------------------

    pub async fn list_services(&self, lan: bool) -> Result<ServiceList, Status> {
        let mut v = services::list(self.runner.as_ref()).await?;
        for s in &mut v {
            s.protected = self.admin.unit_protected(&s.name);
        }
        Ok(ServiceList { access: Some(self.admin.access(lan)), services: v })
    }

    pub async fn get_service(&self, name: &str, log_lines: u32, lan: bool) -> Result<ServiceDetail, Status> {
        let mut d = services::detail(self.runner.as_ref(), name, log_lines, self.btime()).await?;
        if let Some(i) = d.info.as_mut() {
            i.protected = self.admin.unit_protected(name) || self.admin.unit_protected(&i.name);
        }
        d.access = Some(self.admin.access(lan));
        Ok(d)
    }

    pub async fn control_service(&self, r: ControlServiceRequest, lan: bool) -> Result<ServiceDetail, Status> {
        self.admin.check_can_change(lan)?;
        if !services::valid_name(&r.name) {
            return Err(Status::invalid_argument(format!("not a service/timer/socket/path unit: {}", r.name)));
        }
        if self.admin.unit_protected(&r.name) {
            return Err(Status::permission_denied(format!("{} is protected and can't be changed from the phone", r.name)));
        }
        let verb = match (SvcAction::try_from(r.action), r.now) {
            (Ok(SvcAction::Start), _) => "start",
            (Ok(SvcAction::Stop), _) => "stop",
            (Ok(SvcAction::Restart), _) => "restart",
            (Ok(SvcAction::Reload), _) => "reload",
            (Ok(SvcAction::Enable), false) => "enable",
            (Ok(SvcAction::Enable), true) => "enable-now",
            (Ok(SvcAction::Disable), false) => "disable",
            (Ok(SvcAction::Disable), true) => "disable-now",
            (Ok(SvcAction::ResetFailed), _) => "reset-failed",
            _ => return Err(Status::invalid_argument("unknown action")),
        };
        let message = {
            let _g = self.admin_lock.lock().await;
            self.admin.request(self.runner.as_ref(), &format!("unit {verb} {}", r.name)).await?
        };
        let mut d = self.get_service(&r.name, 0, lan).await?;
        d.message = message;
        Ok(d)
    }

    // ---- system settings ----------------------------------------------------------------------

    async fn timezones(&self) -> &[String] {
        self.tz_cache
            .get_or_init(|| async {
                match self.runner.run("timedatectl", &super::runner::args(&["list-timezones"]), super::SHORT).await {
                    Ok(o) if o.ok() => o.stdout.lines().map(str::trim).filter(|l| !l.is_empty()).map(str::to_owned).collect(),
                    _ => Vec::new(),
                }
            })
            .await
    }

    async fn collect_settings(&self, all_sysctl: bool, extra_keys: &[String]) -> Vec<dys_core::pb::SettingGroup> {
        let deny = |k: &str| self.admin.sysctl_protected(k);
        let tz = self.timezones().await;
        settings::collect(settings::Inputs {
            paths: &self.admin.paths,
            runner: self.runner.as_ref(),
            deny_sysctl: &deny,
            timezones: tz,
            all_sysctl,
            extra_keys,
        })
        .await
    }

    pub async fn system_settings(&self, r: GetSystemSettingsRequest, lan: bool) -> SystemSettings {
        let groups = self.collect_settings(r.all_sysctl, &r.sysctl_keys).await;
        SystemSettings { access: Some(self.admin.access(lan)), groups, message: String::new() }
    }

    pub async fn set_system_setting(&self, r: SetSystemSettingRequest, lan: bool) -> Result<SystemSettings, Status> {
        self.admin.check_can_change(lan)?;
        let extra: Vec<String> = r.id.strip_prefix("sysctl:").map(|k| vec![k.to_owned()]).unwrap_or_default();
        if let Some(k) = extra.first()
            && !settings::valid_sysctl_key(k)
        {
            return Err(Status::invalid_argument(format!("bad sysctl key: {k}")));
        }
        let message = {
            let _g = self.admin_lock.lock().await;
            let groups = self.collect_settings(false, &extra).await;
            let current = settings::find(&groups, &r.id)
                .ok_or_else(|| Status::not_found(format!("no such setting on this PC: {}", r.id)))?
                .clone();
            let plan = settings::plan(&current, &r.value, r.persist, r.restore)?;
            let mut message = String::new();
            for (i, req) in plan.requests.iter().enumerate() {
                message = self.admin.request(self.runner.as_ref(), req).await?;
                if i == 0 {
                    let orig = &self.admin.paths.originals;
                    if r.restore {
                        settings::forget_original(orig, &plan.original_id)?;
                    } else {
                        settings::remember_original(orig, &plan.original_id, &current.value)?;
                    }
                }
            }
            info!(id = %r.id, restore = r.restore, persist = r.persist, "setting changed");
            message
        };
        let groups = self.collect_settings(false, &extra).await;
        Ok(SystemSettings { access: Some(self.admin.access(lan)), groups, message })
    }
}
