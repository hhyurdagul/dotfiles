#!/usr/bin/env bash
set -euo pipefail
# C.UTF-8 keeps "." decimals for awk without tripping Qt's non-UTF-8 warning
# in the quickshell ipc child.
export LC_ALL=C.UTF-8

kind=${1:-}
action=${2:-}
case "$kind:$action" in
  volume:up|volume:down|volume:mute|microphone:mute|brightness:up|brightness:down|brightness:toggle) ;;
  *) printf 'Usage: desktop-control volume up|down|mute / microphone mute / brightness up|down|toggle\n' >&2; exit 2 ;;
esac

# Serialize repeated presses so hardware writes and their readbacks stay ordered.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/desktop-control-$UID-$kind.lock"
flock -w 2 9 || exit 0
desktop=${XDG_CURRENT_DESKTOP:-}
if [[ "${desktop,,}" == *niri* ]]; then
  screen=$(niri msg --json focused-output | jq -r '.name // empty')
else
  screen=$(hyprctl -j monitors | jq -r '[.[] | select(.focused)][0].name // empty')
fi

show_osd() {
  quickshell ipc -c default call osd display "$kind" "$1" "$2" "$screen" "${3:-}" >/dev/null 2>&1 || true
}

fail() {
  show_osd -1 false "$1"
  printf '%s\n' "$1" >&2
  exit 1
}

if [[ "$kind" = volume || "$kind" = microphone ]]; then
  node=@DEFAULT_AUDIO_SINK@
  [[ "$kind" != microphone ]] || node=@DEFAULT_AUDIO_SOURCE@
  case "$action" in
    up) wpctl set-volume -l 1 "$node" 5%+ || fail 'Audio unavailable' ;;
    down) wpctl set-volume "$node" 5%- || fail 'Audio unavailable' ;;
    mute) wpctl set-mute "$node" toggle || fail 'Audio unavailable' ;;
  esac
  state=$(wpctl get-volume "$node") || fail 'Audio unavailable'
  level=$(awk '{ printf "%.0f", $2 * 100 }' <<< "$state")
  muted=false
  [[ "$state" != *MUTED* ]] || muted=true
  show_osd "$level" "$muted"
  exit 0
fi

# Only change the focused display: backlight for a laptop panel, DDC for a monitor.
# Super+mute toggles an external monitor between 0 and 100. The internal panel is ignored.
if [[ "$action" == toggle ]]; then
  case "$screen" in
    eDP-*|LVDS-*|DSI-*) exit 0 ;;
  esac
  bus=""
  for connector in /sys/class/drm/card*-"$screen"; do
    [[ -e "$connector/ddc" ]] || continue
    bus=$(basename "$(readlink -f "$connector/ddc")")
    bus=${bus#i2c-}
    break
  done
  [[ "$bus" =~ ^[0-9]+$ ]] || fail 'Display brightness unavailable'
  state=$(ddcutil --bus "$bus" getvcp 10 --terse) || fail 'Brightness readback failed'
  current=$(awk '$1 == "VCP" && $2 == "10" && $3 == "C" && $5 > 0 { printf "%.0f", $4 }' <<< "$state")
  [[ "$current" =~ ^[0-9]+$ ]] || fail 'Brightness readback failed'
  target=0
  [[ "$current" -eq 0 ]] && target=100
  ddcutil --bus "$bus" --noverify setvcp 10 "$target" >/dev/null || fail 'Monitor brightness failed'
  state=$(ddcutil --bus "$bus" getvcp 10 --terse) || fail 'Brightness readback failed'
  level=$(awk '$1 == "VCP" && $2 == "10" && $3 == "C" && $5 > 0 { printf "%.0f", $4 * 100 / $5 }' <<< "$state")
  [[ "$level" =~ ^[0-9]+$ ]] || fail 'Brightness readback failed'
  show_osd "$level" false
  exit 0
fi

case "$screen" in
  eDP-*|LVDS-*|DSI-*)
    step=5%+
    [[ "$action" != down ]] || step=5%-
    brightnessctl --class=backlight -e4 -n2 set "$step" >/dev/null || fail 'Brightness unavailable'
    state=$(brightnessctl --class=backlight -m) || fail 'Brightness unavailable'
    level=$(awk -F, 'NR == 1 { gsub(/%/, "", $4); print $4 }' <<< "$state")
    ;;
  *)
    bus=""
    for connector in /sys/class/drm/card*-"$screen"; do
      [[ -e "$connector/ddc" ]] || continue
      bus=$(basename "$(readlink -f "$connector/ddc")")
      bus=${bus#i2c-}
      break
    done
    [[ "$bus" =~ ^[0-9]+$ ]] || fail 'Display brightness unavailable'
    sign=+
    [[ "$action" != down ]] || sign=-
    ddcutil --bus "$bus" --noverify setvcp 10 "$sign" 5 >/dev/null || fail 'Monitor brightness failed'
    state=$(ddcutil --bus "$bus" getvcp 10 --terse) || fail 'Brightness readback failed'
    level=$(awk '$1 == "VCP" && $2 == "10" && $3 == "C" && $5 > 0 { printf "%.0f", $4 * 100 / $5 }' <<< "$state")
    ;;
esac
[[ "$level" =~ ^[0-9]+$ ]] || fail 'Brightness readback failed'
show_osd "$level" false
