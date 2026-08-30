import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: slackWidget
    Layout.preferredWidth: iconContainer.width
    Layout.preferredHeight: parent.height
    Layout.rightMargin: 8

    property bool slackRunning: false
    property int slackUnread: 0

    // Slack running check
    Process {
        id: slackRunningProc
        command: ["sh", "-c", "pgrep -x slack >/dev/null && echo 'running' || echo 'stopped'"]
        stdout: SplitParser {
            onRead: data => {
                if (data) {
                    slackWidget.slackRunning = data.trim() === "running"
                }
            }
        }
        Component.onCompleted: running = true
    }

    // Slack unread count (from dunst history)
    Process {
        id: slackUnreadProc
        command: ["sh", "-c", "dunstctl history | jq '[.data[][] | select(.appname.data == \"Slack\")] | length'"]
        stdout: SplitParser {
            onRead: data => {
                if (data) {
                    slackWidget.slackUnread = parseInt(data.trim()) || 0
                }
            }
        }
        Component.onCompleted: running = true
    }

    // Open/Focus Slack
    Process {
        id: slackOpenProc
        command: ["sh", "-c", "hyprctl dispatch focuswindow class:Slack || slack &"]
    }

    // Update timer
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            slackRunningProc.running = true
            slackUnreadProc.running = true
        }
    }

    // Icon content - includes badge overlay
    Item {
        id: iconContainer
        anchors.centerIn: parent
        width: slackText.width + (slackUnread > 0 ? 16 : 0)
        height: parent.height

        Text {
            id: slackText
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: slackUnread > 0 ? -8 : 0
            text: "󰒱"
            color: slackRunning ? Theme.colFg : Theme.colMuted
            font.pixelSize: Theme.fontSize + 4
            font.family: Theme.fontFamily
            font.bold: true
        }

        // Unread badge
        Rectangle {
            visible: slackUnread > 0
            width: 14
            height: 14
            radius: 7
            color: "#e01e5a"
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 6

            Text {
                anchors.centerIn: parent
                text: slackUnread > 9 ? "+" : slackUnread
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
        onClicked: slackOpenProc.running = true
    }
}
