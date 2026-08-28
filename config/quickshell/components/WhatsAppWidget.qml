import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: whatsappWidget
    Layout.preferredWidth: iconContainer.width
    Layout.preferredHeight: parent.height
    Layout.rightMargin: 8

    property bool whatsappRunning: false
    property int whatsappUnread: 0

    // WhatsApp running check
    Process {
        id: whatsappRunningProc
        command: ["sh", "-c", "pgrep -f 'whatsapp|WhatsApp' >/dev/null && echo 'running' || echo 'stopped'"]
        stdout: SplitParser {
            onRead: data => {
                if (data) {
                    whatsappWidget.whatsappRunning = data.trim() === "running"
                }
            }
        }
        Component.onCompleted: running = true
    }

    // WhatsApp unread count (from dunst history)
    Process {
        id: whatsappUnreadProc
        command: ["sh", "-c", "dunstctl history | jq '[.data[][] | select(.appname.data | test(\"whatsapp|WhatsApp\"; \"i\"))] | length'"]
        stdout: SplitParser {
            onRead: data => {
                if (data) {
                    whatsappWidget.whatsappUnread = parseInt(data.trim()) || 0
                }
            }
        }
        Component.onCompleted: running = true
    }

    // Open/Focus WhatsApp
    Process {
        id: whatsappOpenProc
        command: ["sh", "-c", "hyprctl dispatch focuswindow class:whatsapp || hyprctl dispatch focuswindow class:WhatsApp || whatsapp-for-linux &"]
    }

    // Update timer
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            whatsappRunningProc.running = true
            whatsappUnreadProc.running = true
        }
    }

    // Icon content - includes badge overlay
    Item {
        id: iconContainer
        anchors.centerIn: parent
        width: whatsappText.width + (whatsappUnread > 0 ? 16 : 0)
        height: parent.height

        Text {
            id: whatsappText
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: whatsappUnread > 0 ? -8 : 0
            text: "󰖣"
            color: whatsappRunning ? Theme.colWhatsapp : Theme.colMuted
            font.pixelSize: Theme.fontSize + 4
            font.family: Theme.fontFamily
            font.bold: true
        }

        // Unread badge
        Rectangle {
            visible: whatsappUnread > 0
            width: 14
            height: 14
            radius: 7
            color: Theme.colWhatsapp
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 6

            Text {
                anchors.centerIn: parent
                text: whatsappUnread > 9 ? "+" : whatsappUnread
                color: "white"
                font.pixelSize: 9
                font.family: Theme.fontFamily
                font.bold: true
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: whatsappOpenProc.running = true
    }
}
