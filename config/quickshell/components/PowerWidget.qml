import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

DropdownWidget {
    id: powerWidget
    popupWidth: 140
    popupHeight: 165
    stemAlignment: "right"

    // Power actions
    Process {
        id: lockProc
        command: ["loginctl", "lock-session"]
    }

    Process {
        id: logoutProc
        command: ["hyprctl", "dispatch", "exit"]
    }

    Process {
        id: rebootProc
        command: ["systemctl", "reboot"]
    }

    Process {
        id: shutdownProc
        command: ["systemctl", "poweroff"]
    }

    // Icon with spacing
    Item {
        width: powerIcon.width + 16
        height: parent.height

        Text {
            id: powerIcon
            anchors.centerIn: parent
            text: "󰐥"
            color: dropdownOpen ? "#ff5555" : Theme.colFg
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
        }
    }

    popupContent: Component {
        Column {
            spacing: 4

            // Lock
            Rectangle {
                width: parent.width
                height: 32
                color: lockMouse.containsMouse ? Qt.rgba(Theme.colFg.r, Theme.colFg.g, Theme.colFg.b, 0.1) : "transparent"
                radius: 6

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    spacing: 10

                    Text {
                        text: "󰌾"
                        color: Theme.colFg
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                    }
                    Text {
                        text: "Lock"
                        color: Theme.colFg
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                    }
                }

                MouseArea {
                    id: lockMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        powerWidget.dropdownOpen = false
                        lockProc.running = true
                    }
                }
            }

            // Logout
            Rectangle {
                width: parent.width
                height: 32
                color: logoutMouse.containsMouse ? Qt.rgba(Theme.colFg.r, Theme.colFg.g, Theme.colFg.b, 0.1) : "transparent"
                radius: 6

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    spacing: 10

                    Text {
                        text: "󰍃"
                        color: Theme.colFg
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                    }
                    Text {
                        text: "Logout"
                        color: Theme.colFg
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                    }
                }

                MouseArea {
                    id: logoutMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        powerWidget.dropdownOpen = false
                        logoutProc.running = true
                    }
                }
            }

            // Reboot
            Rectangle {
                width: parent.width
                height: 32
                color: rebootMouse.containsMouse ? Qt.rgba(Theme.colFg.r, Theme.colFg.g, Theme.colFg.b, 0.1) : "transparent"
                radius: 6

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    spacing: 10

                    Text {
                        text: "󰜉"
                        color: "#ffb86c"
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                    }
                    Text {
                        text: "Reboot"
                        color: Theme.colFg
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                    }
                }

                MouseArea {
                    id: rebootMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        powerWidget.dropdownOpen = false
                        rebootProc.running = true
                    }
                }
            }

            // Shutdown
            Rectangle {
                width: parent.width
                height: 32
                color: shutdownMouse.containsMouse ? Qt.rgba(Theme.colFg.r, Theme.colFg.g, Theme.colFg.b, 0.1) : "transparent"
                radius: 6

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    spacing: 10

                    Text {
                        text: "󰐥"
                        color: "#ff5555"
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                    }
                    Text {
                        text: "Shutdown"
                        color: Theme.colFg
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                    }
                }

                MouseArea {
                    id: shutdownMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        powerWidget.dropdownOpen = false
                        shutdownProc.running = true
                    }
                }
            }
        }
    }
}
