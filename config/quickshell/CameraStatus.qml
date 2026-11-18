pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Whether any process holds a /dev/video* node open. Event-driven and shared
// by every bar: inotify open/close events on the nodes trigger a single
// `fuser` check; nothing polls.
QtObject {
    id: camera

    property bool active: false
    property bool checkPending: false

    function requestCheck() {
        if (checkProc.running) checkPending = true
        else checkProc.running = true
    }

    property var checkProcess: Process {
        id: checkProc
        command: ["sh", "-c", "fuser /dev/video* >/dev/null 2>&1"]
        onExited: (exitCode, exitStatus) => {
            camera.active = exitCode === 0
            if (camera.checkPending) {
                camera.checkPending = false
                checkDelay.restart()
            }
        }
    }

    // Apps open and close the node several times while negotiating a stream.
    property var checkDelayTimer: Timer {
        id: checkDelay
        interval: 250
        onTriggered: camera.requestCheck()
    }

    // Exits immediately when no camera exists; the hotplug watcher restarts it.
    property var useWatcher: Process {
        id: useWatcher
        command: ["sh", "-c", "exec inotifywait -m -q -e open,close /dev/video*"]
        running: true
        stdout: SplitParser {
            onRead: data => checkDelay.restart()
        }
    }

    // A camera plugged in or removed: watch the new set of nodes once udev
    // has applied their permissions.
    property var hotplugWatcher: Process {
        command: ["inotifywait", "-m", "-q", "-e", "create,delete", "--include", "video[0-9]+$", "/dev"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                useWatcher.running = false
                rewatchDelay.restart()
            }
        }
    }

    property var rewatchDelayTimer: Timer {
        id: rewatchDelay
        interval: 500
        onTriggered: {
            useWatcher.running = true
            camera.requestCheck()
        }
    }

    Component.onCompleted: requestCheck()
}
