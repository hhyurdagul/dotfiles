import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

Item {
    id: idleWidget

    property bool idleDisabled: false

    visible: true
    Layout.preferredWidth: 24
    Layout.preferredHeight: parent.height

    Text {
        anchors.centerIn: parent
        text: idleWidget.idleDisabled ? "󱫖" : "󰒲"
        color: idleMouse.containsMouse 
            ? (idleWidget.idleDisabled ? Theme.colIdle : Theme.colBlue) 
            : (idleWidget.idleDisabled ? Theme.colIdle : Theme.colFgDim)
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
        font.bold: idleWidget.idleDisabled
    }

    MouseArea {
        id: idleMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: toggleProc.running = true
    }

    Process {
        id: statusProc
        command: ["pgrep", "-x", "hypridle"]
        onExited: (exitCode, exitStatus) => {
            idleWidget.idleDisabled = exitCode !== 0
        }
        Component.onCompleted: running = true
    }

    Process {
        id: toggleProc
        command: ["sh", "-c", "$HOME/.config/scripts/idle-toggle.sh"]
        onExited: {
            statusDelay.restart()
        }
    }

    Timer {
        id: statusDelay
        interval: 500
        repeat: false
        onTriggered: statusProc.running = true
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: statusProc.running = true
    }
}
