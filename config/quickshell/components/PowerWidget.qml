import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

DropdownWidget {
    id: powerWidget
    popupWidth: 170
    popupHeight: 205
    stemAlignment: "right"
    property string pendingAction: ""

    // Power actions run detached: the locker and session-exit must survive a
    // Quickshell restart, and session-exit ends Quickshell itself.
    function confirmAction(action, command) {
        if (pendingAction === action) {
            pendingAction = ""
            dropdownOpen = false
            Quickshell.execDetached(command)
            return
        }
        pendingAction = action
        confirmTimer.restart()
    }

    onDropdownOpenChanged: {
        if (!dropdownOpen) pendingAction = ""
    }

    Timer {
        id: confirmTimer
        interval: 4000
        onTriggered: powerWidget.pendingAction = ""
    }

    // Icon with spacing
    Item {
        width: powerIcon.width
        height: parent.height

        Text {
            id: powerIcon
            anchors.centerIn: parent
            text: "󰐥"
            color: dropdownOpen ? Theme.colRed : Theme.colFg
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
                color: lockMouse.containsMouse ? Theme.colHover : "transparent"
                radius: Theme.itemRadius

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
                        Quickshell.execDetached(["lock-screen"])
                    }
                }
            }

            // Sleep
            Rectangle {
                width: parent.width
                height: 32
                color: sleepMouse.containsMouse ? Theme.colHover : "transparent"
                radius: Theme.itemRadius

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    spacing: 10

                    Text {
                        text: "󰤄"
                        color: Theme.colFg
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                    }
                    Text {
                        text: "Sleep"
                        color: Theme.colFg
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                    }
                }

                MouseArea {
                    id: sleepMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        powerWidget.dropdownOpen = false
                        Quickshell.execDetached(["systemctl", "suspend"])
                    }
                }
            }

            // Logout
            Rectangle {
                width: parent.width
                height: 32
                color: logoutMouse.containsMouse ? Theme.colHover : "transparent"
                radius: Theme.itemRadius

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
                        Quickshell.execDetached(["session-exit"])
                    }
                }
            }

            // Reboot
            Rectangle {
                width: parent.width
                height: 32
                color: rebootMouse.containsMouse || powerWidget.pendingAction === "reboot" ? Theme.colDangerSurface : "transparent"
                radius: Theme.itemRadius

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    spacing: 10

                    Text {
                        text: "󰜉"
                        color: Theme.colOrange
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                    }
                    Text {
                        text: powerWidget.pendingAction === "reboot" ? "Confirm reboot" : "Reboot"
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
                    onClicked: powerWidget.confirmAction("reboot", ["systemctl", "reboot"])
                }
            }

            // Shutdown
            Rectangle {
                width: parent.width
                height: 32
                color: shutdownMouse.containsMouse || powerWidget.pendingAction === "shutdown" ? Theme.colDangerSurface : "transparent"
                radius: Theme.itemRadius

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    spacing: 10

                    Text {
                        text: "󰐥"
                        color: Theme.colRed
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                    }
                    Text {
                        text: powerWidget.pendingAction === "shutdown" ? "Confirm power off" : "Shutdown"
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
                    onClicked: powerWidget.confirmAction("shutdown", ["systemctl", "poweroff"])
                }
            }
        }
    }
}
