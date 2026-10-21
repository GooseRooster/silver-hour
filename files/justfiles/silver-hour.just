# silver-hour update helpers. Available via `blujust <recipe>`.
#
# The update recipes exist so the notification/tray path can be exercised in
# the VM without waiting for the timers.

# Refresh the silver-hour update status now (writes
# /run/silver-hour/update-status.json) and trigger the notification service.
silver-hour-update-status:
    #!/usr/bin/bash
    set -euo pipefail
    sudo /usr/libexec/silver-hour-update-status
    systemctl --user start silver-hour-update-notify.service || true

# Show what the unprivileged staged-deployment probe sees: the queued
# deployment checksum, or nothing when no deployment is staged.
silver-hour-staged-probe:
    #!/usr/bin/bash
    set -euo pipefail
    staged="$(/usr/libexec/silver-hour-staged-deployment 2>/dev/null || true)"
    if [ -n "$staged" ]; then
      echo "staged deployment: $staged"
    else
      echo "staged deployment: (none)"
    fi
    echo "--- ostree admin status ---"
    ostree admin status --json 2>/dev/null \
      | jq -r '.deployments[]? | "  \(.checksum[0:12]) booted=\(.booted) staged=\(.staged) rollback=\(.rollback)"' \
      || true

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
