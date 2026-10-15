import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import ".."

// Bottom-center card while Handy records, on the focused screen: pulsing dot,
// input waveform, elapsed time, and a button that cancels the recording.
Scope {
    id: overlay

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            visible: Dictation.recording && (Compositor.focusedOutput === modelData.name
                || (!Quickshell.screens.some(s => s.name === Compositor.focusedOutput) && modelData === Quickshell.screens[0]))
            anchors.bottom: true
            margins.bottom: Theme.dictationBottomMargin
            implicitWidth: Theme.dictationWidth
            implicitHeight: Theme.dictationHeight
            exclusiveZone: 0
            color: "transparent"
            // Only the cancel button takes clicks; the rest passes through.
            mask: Region { item: cancelButton }
            WlrLayershell.namespace: "quickshell-dictation"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Theme.colBg
                border.color: Theme.cardBorderColor
                border.width: Theme.cardBorderWidth

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.popupPadding + 2
                    anchors.rightMargin: Theme.densePadding
                    spacing: Theme.itemPadding

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: 10
                        implicitHeight: 10
                        radius: 5
                        color: Theme.colDictation

                        SequentialAnimation on opacity {
                            running: Dictation.recording
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
                        }
                    }

                    Row {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillWidth: true
                        spacing: 3

                        Repeater {
                            model: Dictation.barCount
                            Rectangle {
                                required property int index
                                // Bars fill from the right, newest last.
                                readonly property real level: {
                                    const i = index - (Dictation.barCount - Dictation.levels.length)
                                    return i >= 0 ? Dictation.levels[i] : 0
                                }
                                anchors.verticalCenter: parent.verticalCenter
                                width: 3
                                height: 3 + Math.min(1, level * 2.5) * 18
                                radius: 1.5
                                color: Theme.colDictation
                                opacity: 0.45 + Math.min(1, level * 2.5) * 0.55
                                Behavior on height { NumberAnimation { duration: 60 } }
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: Math.floor(Dictation.elapsedSeconds / 60) + ":" + String(Dictation.elapsedSeconds % 60).padStart(2, "0")
                        color: Theme.colFgDim
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }

                    Rectangle {
                        id: cancelButton
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: 26
                        implicitHeight: 26
                        radius: 13
                        color: cancelMouse.containsMouse ? Theme.colHoverStrong : Theme.colHover

                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            color: Theme.colFg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }

                        MouseArea {
                            id: cancelMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: cancelProc.running = true
                        }
                    }
                }
            }
        }
    }

    Process {
        id: cancelProc
        command: ["handy", "--cancel"]
    }
}
