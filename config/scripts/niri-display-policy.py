#!/usr/bin/env python3
"""Apply HDMI hotplug policy and keep numbered Niri workspaces ordered."""

import json
import os
import select
import socket
import time

# Niri answers "Handled" to actions while the session is locked but drops them,
# and has no lock event. Hotplug usually happens locked (DPMS wake, resume), so
# re-check on a timer until the order sticks, which is right after unlock.
RETRY_SECONDS = 1


class Niri:
    def __init__(self):
        self.socket = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.socket.connect(os.environ["NIRI_SOCKET"])
        # Own buffer instead of makefile(): select() can't see buffered lines.
        self.buffer = b""

    def readline(self, timeout=None):
        """Return the next message, or None if none arrives within timeout."""
        while b"\n" not in self.buffer:
            if not select.select([self.socket], [], [], timeout)[0]:
                return None
            chunk = self.socket.recv(65536)
            if not chunk:
                raise ConnectionError("Niri closed its IPC socket")
            self.buffer += chunk
        line, self.buffer = self.buffer.split(b"\n", 1)
        return json.loads(line)

    def request(self, request):
        self.socket.sendall(json.dumps(request).encode() + b"\n")
        reply = self.readline()
        if "Err" in reply:
            raise RuntimeError(reply["Err"])
        return reply["Ok"]


def order_workspaces(niri):
    """Sort numbered workspaces per output; return whether any move was needed."""
    # Query current state, not a queued event that our own moves may have obsoleted.
    workspaces = niri.request("Workspaces")["Workspaces"]
    moved = False
    outputs = {workspace["output"] for workspace in workspaces} - {None}
    for output in sorted(outputs):
        current = sorted(
            (workspace for workspace in workspaces if workspace["output"] == output),
            key=lambda workspace: workspace["idx"],
        )
        numbered = sorted(
            (
                workspace
                for workspace in current
                if workspace["name"] in map(str, range(1, 11))
            ),
            key=lambda workspace: int(workspace["name"]),
        )
        for index, workspace in enumerate(numbered):
            old_index = current.index(workspace)
            if old_index == index:
                continue
            niri.request(
                {
                    "Action": {
                        "MoveWorkspaceToIndex": {
                            "index": index + 1,
                            "reference": {"Name": workspace["name"]},
                        }
                    }
                }
            )
            current.insert(index, current.pop(old_index))
            moved = True
    return moved


def main():
    niri = Niri()
    events = Niri()
    events.request("EventStream")
    previous_hdmi = None
    retry_at = None
    while True:
        timeout = None if retry_at is None else max(0, retry_at - time.monotonic())
        event = events.readline(timeout)
        # Niri 26.04 has no output event. Output additions/removals and workspace
        # migration emit WorkspacesChanged, including our initial state snapshot.
        # None means the retry timer fired.
        if (
            event is not None
            and "WorkspacesChanged" not in event
            and "ConfigLoaded" not in event
        ):
            continue
        outputs = niri.request("Outputs")["Outputs"]
        hdmi = {
            name: output["logical"] is not None
            for name, output in outputs.items()
            if name.startswith("HDMI-A-")
        }
        # Compare HDMI only: toggling eDP-1 manually must not undo the override.
        # Never switch off the panel before an external output is actually usable.
        if hdmi != previous_hdmi:
            internal = outputs.get("eDP-1")
            enable_internal = not any(hdmi.values())
            if (
                internal is not None
                and (internal["logical"] is not None) != enable_internal
            ):
                niri.request(
                    {
                        "Output": {
                            "output": "eDP-1",
                            "action": "On" if enable_internal else "Off",
                        }
                    }
                )
            previous_hdmi = hdmi
        retry_at = time.monotonic() + RETRY_SECONDS if order_workspaces(niri) else None


if __name__ == "__main__":
    main()
