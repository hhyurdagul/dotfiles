#!/usr/bin/env python3
"""Show recorded SMART alerts. This does not update, build, or activate NixOS."""

import contextlib
import datetime
import fcntl
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile


STATE = (
    Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "disk-health"
)
SMART = Path("/var/lib/workstation-maintenance/smart")


def timestamp():
    return datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds")


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True).encode()).hexdigest()


def load_json(path, default=None):
    try:
        return json.loads(path.read_text())
    except FileNotFoundError:
        return default


def save_json(path, value):
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as stream:
        temporary = Path(stream.name)
        try:
            json.dump(value, stream)
            stream.write("\n")
            stream.flush()
            os.fsync(stream.fileno())
        except BaseException:
            temporary.unlink(missing_ok=True)
            raise
    temporary.replace(path)


@contextlib.contextmanager
def lock():
    STATE.mkdir(mode=0o700, parents=True, exist_ok=True)
    with (STATE / "notify.lock").open("a") as stream:
        try:
            fcntl.flock(stream, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as error:
            raise RuntimeError("Disk-health notification is already running") from error
        yield


def notify(title, body):
    try:
        subprocess.run(
            [
                "notify-send",
                "--app-name=Disk health",
                "--icon=dialog-warning",
                "--urgency=critical",
                title,
                body,
            ],
            check=True,
            timeout=10,
            capture_output=True,
            text=True,
        )
    except (OSError, subprocess.SubprocessError) as error:
        detail = getattr(error, "stderr", None) or str(error)
        print(
            f"Desktop delivery failed; alert remains pending: {detail.strip()}",
            file=sys.stderr,
        )
        return False
    return True


def events():
    monitor = subprocess.run(
        [
            "systemctl",
            "show",
            "smartd.service",
            "--property=LoadState,ActiveState,Result",
        ],
        check=True,
        capture_output=True,
        text=True,
        timeout=5,
    )
    state = dict(
        line.split("=", 1) for line in monitor.stdout.splitlines() if "=" in line
    )
    if state.get("LoadState") != "loaded" or state.get("ActiveState") in {
        "failed",
        "inactive",
    }:
        yield (
            "smartd-service",
            digest(state),
            "Disk health monitoring is not running",
            f"smartd state: {state}. Inspect sudo systemctl status smartd "
            "and sudo journalctl -u smartd. Hardware health is unknown.",
        )
    if SMART.exists():
        for path in sorted(SMART.glob("*.json")):
            event = load_json(path)
            if event is None:
                continue
            yield (
                f"smart:{path.stem}",
                digest([event["device"], event["failtype"], event["message"]]),
                f"Disk health alert: {event['device']}",
                f"{event['message']}\nRecorded {event['time']}. "
                "Inspect sudo journalctl -u smartd and sudo smartctl -a DEVICE. "
                f"Full event: {path}",
            )


def main():
    failed = False
    with lock():
        delivered_path = STATE / "delivered.json"
        delivered = load_json(delivered_path, {})
        seen = set()
        for key, fingerprint, title, body in events():
            seen.add(key)
            if delivered.get(key, {}).get("fingerprint") == fingerprint:
                continue
            if not notify(title, body):
                failed = True
                continue
            delivered[key] = {"fingerprint": fingerprint, "time": timestamp()}
            save_json(delivered_path, delivered)
        for key in [
            key for key in delivered if key not in seen and key != "smartd-service"
        ]:
            delivered.pop(key, None)
        if "smartd-service" not in seen:
            delivered.pop("smartd-service", None)
        save_json(delivered_path, delivered)
    return int(failed)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, RuntimeError, subprocess.SubprocessError, ValueError) as error:
        print(f"Disk-health notification error: {error}", file=sys.stderr)
        sys.exit(1)
