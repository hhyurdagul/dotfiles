#!/usr/bin/env bash
set -euo pipefail

lock-screen
exec niri msg action quit --skip-confirmation
