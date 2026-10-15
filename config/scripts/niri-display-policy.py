#!/usr/bin/env python3
"""Apply HDMI hotplug policy and keep numbered Niri workspaces ordered."""

import json
import os
import socket


class Niri:
    def __init__(self):
        self.socket = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.socket.connect(os.environ["NIRI_SOCKET"])
        self.stream = self.socket.makefile("rw", encoding="utf-8")

    def request(self, request):
        self.stream.write(json.dumps(request) + "\n")
        self.stream.flush()
        line = self.stream.readline()
        if not line:
            raise ConnectionError("Niri closed its IPC socket")
        reply = json.loads(line)
        if "Err" in reply:
            raise RuntimeError(reply["Err"])
        return reply["Ok"]


def order_workspaces(niri):
    # Query current state, not a queued event that our own moves may have obsoleted.
    workspaces = niri.request("Workspaces")["Workspaces"]
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


def main():
    niri = Niri()
    events = Niri()
    events.request("EventStream")
    previous_hdmi = None
    for line in events.stream:
        event = json.loads(line)
        # Niri 26.04 has no output event. Output additions/removals and workspace
        # migration emit WorkspacesChanged, including our initial state snapshot.
        if "WorkspacesChanged" not in event and "ConfigLoaded" not in event:
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
        order_workspaces(niri)
    raise ConnectionError("Niri closed its event stream")


if __name__ == "__main__":
    main()
