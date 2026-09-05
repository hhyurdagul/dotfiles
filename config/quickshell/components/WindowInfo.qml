import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Hyprland
import ".."

RowLayout {
    id: windowInfo
    spacing: 0

    property string activeWindow: ""

    Process {
        id: windowProc
        property string output: ""
        command: ["hyprctl", "activewindow", "-j"]
        stdout: SplitParser {
            onRead: data => {
                if (data) windowProc.output += data
            }
        }
        onRunningChanged: {
            if (running) {
                output = ""
            } else {
                try {
                    var active = JSON.parse(output)
                    windowInfo.activeWindow = active.title || ""
                } catch (e) {
                    windowInfo.activeWindow = ""
                }
            }
        }
        Component.onCompleted: running = true
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activewindow" || event.name === "activewindowv2"
                    || event.name === "openwindow" || event.name === "closewindow") {
                windowProc.running = true
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: windowProc.running = true
    }

    Text {
        text: activeWindow
        textFormat: Text.PlainText
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
