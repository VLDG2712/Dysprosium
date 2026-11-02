Fake `nvidia-smi`, `systemctl`, `busctl`, `loginctl`, `ip`, `checkupdates`, `yay`, `timedatectl`,
`hostnamectl` and `kill` for the e2e tests. The test puts this
directory first in dysd's PATH, so nothing real is ever started. State lives in `$FAKE_STATE`.

busctl is faked so the power tests never reach the real logind (they would really reboot/shut
down the PC). The e2e harness refuses to start if any script here isn't executable, because a
non-executable fake is skipped in PATH and the real tool would run instead.

For the Processes / Services / System settings tests, the fake `systemctl` runs the real root script
(`packaging/libexec/admin`) for `dysd-admin@` requests, against the fake root in
`$DYSD_ADMIN_TEST_ROOT` only; it refuses without that variable.
