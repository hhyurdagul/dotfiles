pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The idle daemon always runs; `idle-toggle` starts or stops
// idle-inhibit.service, which holds a systemd idle inhibitor lock that the
// daemon honors. One status poll for every bar.
QtObject {
    id: idle

    property bool inhibited: false

    function toggle() {
        toggleProc.running = true
    }

    property var statusProcess: Process {
        id: statusProc
        command: ["systemctl", "--user", "is-active", "--quiet", "idle-inhibit.service"]
        running: true
        onExited: (exitCode, exitStatus) => idle.inhibited = exitCode === 0
    }

    property var toggleProcess: Process {
        id: toggleProc
        command: ["idle-toggle"]
        onExited: (exitCode, exitStatus) => statusDelay.restart()
    }

    property var statusDelayTimer: Timer {
        id: statusDelay
        interval: 500
        onTriggered: statusProc.running = true
    }

    // idle-toggle is also bound to a key, so the bar cannot rely on its own clicks.
    property var pollTimer: Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: statusProc.running = true
    }
}
