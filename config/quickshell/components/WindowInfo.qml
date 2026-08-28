import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Hyprland
import ".."

RowLayout {
    id: windowInfo
    spacing: 0

    property string activeWindow: ""

    // Active window title
    Process {
        id: windowProc
        command: ["sh", "-c", "hyprctl activewindow -j | jq -r '.title // empty'"]
        stdout: SplitParser {
            onRead: data => {
                if (data && data.trim()) {
                    windowInfo.activeWindow = data.trim()
                }
            }
        }
        Component.onCompleted: running = true
    }

    // Event-based updates for window (instant)
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            windowProc.running = true
        }
    }

    // Backup timer for window (catches edge cases)
    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: windowProc.running = true
    }

    Text {
        text: activeWindow
        color: Theme.colWindow
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
        font.bold: true
        Layout.leftMargin: 8
        Layout.maximumWidth: 300
        elide: Text.ElideRight
        maximumLineCount: 1
        visible: activeWindow.length > 0
    }
}
