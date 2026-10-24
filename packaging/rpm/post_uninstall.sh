# dysprosium %postun: reload units. State in /var/lib/dysd is kept (rpm has no purge).
if [ -d /run/systemd/system ]; then
    systemctl daemon-reload || :
fi
