# Invoked by smartd's documented -M exec hook. No desktop session is required:
# record the alert first; the user service delivers it on the next graphical login.
if [[ $EUID -ne 0 ]]; then
  echo 'maintenance-smart-alert must run as root (smartd hook)' >&2
  exit 1
fi

state=/var/lib/workstation-maintenance/smart
install -d -m 0755 "$state"
device=${SMARTD_DEVICESTRING:-${SMARTD_DEVICE:-unknown-device}}
message=${SMARTD_MESSAGE:-${SMARTD_FULLMESSAGE:-No smartd message supplied}}
failtype=${SMARTD_FAILTYPE:-unknown}
key=$(printf '%s\n%s' "$device" "$failtype" | sha256sum)
key=${key%% *}
temporary=$(mktemp "$state/.alert.XXXXXXXX")
trap 'rm -f "$temporary"' EXIT
jq -n \
  --arg time "$(date --utc --iso-8601=seconds)" \
  --arg device "$device" \
  --arg message "$message" \
  --arg details "${SMARTD_FULLMESSAGE:-$message}" \
  --arg failtype "$failtype" \
  '{time: $time, device: $device, message: $message, details: $details, failtype: $failtype}' \
  > "$temporary"
chmod 0644 "$temporary"
mv -f "$temporary" "$state/$key.json"
logger --priority daemon.warning --tag maintenance-smart-alert -- \
  "$device: $message; persistent event: $state/$key.json"
