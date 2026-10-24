# dysprosium %preun: stop and disable dysd on removal (not on upgrade: $1 is 1 then).
if [ "$1" -eq 0 ] && [ -d /run/systemd/system ]; then
    systemctl disable --now dysd.service || :
fi
