import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."

Variants {
    id: toastVariants
    model: Quickshell.screens

    PanelWindow {
        id: toastWindow
        property var modelData
        screen: modelData

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            top: true
            right: true
        }

        margins {
            top: 42
            right: 16
        }

        implicitWidth: 320
        implicitHeight: toastCol.implicitHeight
        color: "transparent"

        Column {
            id: toastCol
            width: 320
            spacing: 8

            Repeater {
                model: NotifManager.activeToasts

                Rectangle {
                    id: toastCard
                    width: 320
                    height: Math.max(cardCol.implicitHeight + 16, 64)
                    radius: Theme.cardRadius
                    color: Theme.colBg
                    border.color: Theme.cardBorderColor
                    border.width: Theme.cardBorderWidth

                    // Auto-close timer for floating toast (5 seconds)
                    Timer {
                        id: autoCloseTimer
                        interval: 5000
                        running: !cardMouse.containsMouse && !closeBtnMouse.containsMouse
                        repeat: false
                        onTriggered: {
                            NotifManager.expireToast(modelData.id)
                        }
                    }

                    // Background card click area (Interacts with notification)
                    MouseArea {
                        id: cardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            NotifManager.interactToast(modelData.id)
                        }
                    }

                    Column {
                        id: cardCol
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 4

                        // Header: App name, time, close button
                        RowLayout {
                            width: parent.width

                            Text {
                                text: modelData.app || "Notification"
                                color: Theme.colNetwork
                                font.pixelSize: 11
                                font.family: Theme.fontFamily
                                font.bold: true
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: modelData.time || ""
                                color: Theme.colMuted
                                font.pixelSize: 10
                                font.family: Theme.fontFamily
                            }

                            Rectangle {
                                width: 18
                                height: 18
                                radius: 4
                                color: closeBtnMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    color: closeBtnMouse.containsMouse ? "#ff5555" : Theme.colMuted
                                    font.pixelSize: 10
                                }

                                MouseArea {
                                    id: closeBtnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        NotifManager.dismissToast(modelData.id)
                                    }
                                }
                            }
                        }

                        // Summary / Title
                        Text {
                            text: modelData.summary || ""
                            color: Theme.colFg
                            font.pixelSize: Theme.fontSize
                            font.family: Theme.fontFamily
                            font.bold: true
                            width: parent.width
                            elide: Text.ElideRight
                        }

                        // Body
                        Text {
                            visible: modelData.body !== ""
                            text: modelData.body || ""
                            color: Theme.colMuted
                            font.pixelSize: Theme.fontSize - 2
                            font.family: Theme.fontFamily
                            width: parent.width
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
