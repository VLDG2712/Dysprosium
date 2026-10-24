# shellcheck disable=SC2016  # $USER is meant literally in the printed hint
# dysprosium %post: user/group, log dir, reload; not enabled automatically (needs the PC's
# addresses in the server certificate first, see README "Install as a service").
systemd-sysusers dysd.conf || :
systemd-tmpfiles --create dysd.conf || :
if [ -d /run/systemd/system ]; then
    systemctl daemon-reload || :
    systemctl try-restart dysd.service || :
fi
if [ "$1" -eq 1 ]; then
    echo '==> Dysprosium installed. Next: sudo usermod -aG dys "$USER"; sudo systemctl enable --now dysd;'
    echo '    sudo -u dysd dysd --state-dir /var/lib/dysd init --san <lan-ip>; sudo systemctl restart dysd; dys pair'
    echo '    Fedora: open the port for the phone: sudo firewall-cmd --permanent --add-port=50051/tcp && sudo firewall-cmd --reload'
fi
