Fake `nvidia-smi`, `systemctl`, `checkupdates` and `yay` for the e2e tests. The test puts this
directory first in dysd's PATH, so nothing real is ever started. State lives in `$FAKE_STATE`.
