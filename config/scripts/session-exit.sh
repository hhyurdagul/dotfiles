#!/usr/bin/env bash
set -euo pipefail

lock-screen
desktop=${XDG_CURRENT_DESKTOP:-}
if [[ "${desktop,,}" == *niri* ]]; then
  exec niri msg action quit --skip-confirmation
fi
exec uwsm stop
