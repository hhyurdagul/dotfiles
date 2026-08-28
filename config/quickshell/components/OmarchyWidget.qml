import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

Item {
    id: omarchyWidget

    Layout.preferredWidth: 28
    Layout.preferredHeight: parent.height

    Text {
        anchors.centerIn: parent
        text: "\ue900"
        color: omarchyMouse.containsMouse ? Theme.colNetwork : Theme.colFg
        font.pixelSize: Theme.fontSize + 4
        font.family: "omarchy"
    }

    MouseArea {
        id: omarchyMouse
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                terminalProc.startDetached()
            } else {
                menuProc.startDetached()
            }
        }
    }

    Process {
        id: menuProc
        command: ["omarchy-menu"]
    }

    Process {
        id: terminalProc
        command: ["xdg-terminal-exec"]
    }
}
