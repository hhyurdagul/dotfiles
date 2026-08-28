import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

Item {
    id: updateWidget

    property bool updateAvailable: false

    visible: updateAvailable
    Layout.preferredWidth: updateAvailable ? 24 : 0
    Layout.preferredHeight: parent.height

    Text {
        anchors.centerIn: parent
        text: ""
        color: updateMouse.containsMouse ? Theme.colNetwork : Theme.colFg
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
        font.bold: true
    }

    MouseArea {
        id: updateMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            updateWidget.updateAvailable = false
            updateProc.startDetached()
            postUpdateCheck.restart()
        }
    }

    Process {
        id: availableProc
        command: ["omarchy-update-available"]
        onRunningChanged: {
            if (running) {
                updateWidget.updateAvailable = false
            }
        }
        onExited: (exitCode, exitStatus) => {
            updateWidget.updateAvailable = exitCode === 0
        }
        Component.onCompleted: running = true
    }

    Process {
        id: updateProc
        command: [
            "omarchy-launch-floating-terminal-with-presentation",
            "omarchy-update"
        ]
    }

    Timer {
        id: postUpdateCheck
        interval: 60000
        repeat: false
        onTriggered: availableProc.running = true
    }

    Timer {
        interval: 21600000
        running: true
        repeat: true
        onTriggered: availableProc.running = true
    }
}
