import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

Item {
    id: cameraWidget

    property bool cameraActive: false

    visible: cameraActive
    Layout.preferredWidth: cameraActive ? cameraRow.implicitWidth + 12 : 0
    Layout.preferredHeight: parent.height

    Rectangle {
        id: cameraPill
        anchors.centerIn: parent
        height: 24
        width: cameraRow.implicitWidth + 12
        radius: Theme.itemRadius
        color: Qt.rgba(Theme.colCamera.r, Theme.colCamera.g, Theme.colCamera.b, 0.2)
        border.color: Theme.colCamera
        border.width: 1

        Row {
            id: cameraRow
            anchors.centerIn: parent
            spacing: 4

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰄀"
                color: Theme.colCamera
                font.pixelSize: Theme.fontSize + 1
                font.family: Theme.fontFamily
                font.bold: true
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "REC"
                color: Theme.colCamera
                font.pixelSize: Theme.fontSize - 3
                font.family: Theme.fontFamily
                font.bold: true
            }
        }
    }

    // Check if any process is actively using /dev/video*
    Process {
        id: checkCameraProc
        command: ["sh", "-c", "fuser /dev/video* 2>/dev/null | grep -q '[0-9]' && echo 'active' || echo 'inactive'"]
        stdout: SplitParser {
            onRead: data => {
                if (data) {
                    cameraWidget.cameraActive = data.trim() === "active"
                }
            }
        }
        Component.onCompleted: running = true
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: checkCameraProc.running = true
    }
}
