# silver-hour update helpers. Available via `blujust <recipe>`.
#
# The two update recipes exist so the notification/tray path can be exercised in
# the VM without waiting for the 15-minute timer.

# Refresh the silver-hour update status now (writes
# /run/silver-hour/update-status.json) and trigger the notification service.
silver-hour-update-status:
    #!/usr/bin/bash
    set -euo pipefail
    sudo /usr/libexec/silver-hour-update-status
    systemctl --user start silver-hour-update-notify.service || true

# Simulate a staged update to preview the desktop notification and the tray
# indicator. Optional argument: a version string (default: test-1.0).
silver-hour-test-update version="test-1.0":
    #!/usr/bin/bash
    set -euo pipefail
    sudo /usr/libexec/silver-hour-update-simulate "{{ version }}"
    rm -f "${XDG_STATE_HOME:-$HOME/.local/state}/silver-hour/update-notify.staged"
    systemctl --user start silver-hour-update-notify.service || true

# Clear a simulated update and re-run the real status check.
silver-hour-clear-update:
    #!/usr/bin/bash
    set -euo pipefail
    sudo /usr/libexec/silver-hour-update-status
