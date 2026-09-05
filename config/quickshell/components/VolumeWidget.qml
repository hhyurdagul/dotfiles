import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import ".."

DropdownWidget {
    id: volumeWidget
    popupWidth: 260
    popupHeight: 180

    property var sink: Pipewire.defaultAudioSink
    property var source: Pipewire.defaultAudioSource
    property int volumeLevel: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0
    property bool volumeMuted: sink && sink.audio ? sink.audio.muted : false
    property int micLevel: source && source.audio ? Math.round(source.audio.volume * 100) : 0
    property bool micMuted: source && source.audio ? source.audio.muted : false
    property string audioSink: detectSinkType(sink)

    function detectSinkType(node) {
        if (!node) return "speaker"
        var details = (node.name + " " + node.description + " " + node.nickname).toLowerCase()
        if (details.includes("headphone") || details.includes("headset")) return "headphone"
        if (details.includes("bluez") || details.includes("bluetooth")) return "bluetooth"
        return "speaker"
    }

    function changeVolume(delta) {
        if (!sink || !sink.audio) return
        sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + delta))
    }

    function setVolume(val) {
        if (!sink || !sink.audio) return
        sink.audio.volume = Math.max(0, Math.min(1, val))
    }

    function setMicVolume(val) {
        if (!source || !source.audio) return
        source.audio.volume = Math.max(0, Math.min(1, val))
    }

    property string volumeIcon: {
        if (volumeMuted) return "󰖁"
        if (audioSink === "headphone") return "󰋋"
        if (audioSink === "bluetooth") return "󰂰"
        if (volumeLevel === 0) return "󰕿"
        if (volumeLevel < 30) return "󰕿"
        if (volumeLevel < 70) return "󰖀"
        return "󰕾"
    }

    property real lastWheelTime: 0
    onWheelScrolled: wheel => {
        var now = Date.now()
        if (now - lastWheelTime < 40) return
        lastWheelTime = now
        // Shift + scroll for fine 1% adjustment, normal scroll for 5%
        var step = (wheel.modifiers & Qt.ShiftModifier) ? 0.01 : 0.05
        volumeWidget.changeVolume(wheel.angleDelta.y > 0 ? step : -step)
    }

    // Top bar icon content
    Text {
        id: volText
        anchors.verticalCenter: parent.verticalCenter
        text: `${volumeWidget.volumeIcon} ${volumeWidget.volumeLevel}%`
        color: volumeWidget.volumeMuted ? Theme.colMuted :
               volumeWidget.audioSink === "headphone" ? Theme.colYellow :
               volumeWidget.audioSink === "bluetooth" ? Theme.colBluetooth :
               Theme.colVol
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
        font.bold: true
    }

    Process {
        id: pavuProc
        command: ["pavucontrol"]
    }

    PwObjectTracker {
        objects: [volumeWidget.sink, volumeWidget.source]
    }

    // Native GUI Quickshell Audio Popup
    popupContent: Component {
        Column {
            spacing: 12
            width: parent.width

            // Header: Output Audio
            Column {
                width: parent.width
                spacing: 6

                RowLayout {
                    width: parent.width

                    Text {
                        text: "󰕾 Output"
                        color: Theme.colFg
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                        font.bold: true
                    }

                    Text {
                        text: volumeWidget.sink ? (volumeWidget.sink.description || volumeWidget.sink.name) : "Default"
                        color: Theme.colMuted
                        font.pixelSize: Theme.fontSize - 3
                        font.family: Theme.fontFamily
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideRight
                    }
                }

                // Volume Slider Row
                RowLayout {
                    width: parent.width
                    spacing: 8

                    // Mute button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: Theme.itemRadius
                        color: muteMouse.containsMouse ? Theme.colHoverStrong : Theme.colDivider

                        Text {
                            anchors.centerIn: parent
                            text: volumeWidget.volumeMuted ? "󰖁" : "󰕾"
                            color: volumeWidget.volumeMuted ? Theme.colRed : Theme.colVol
                            font.pixelSize: Theme.fontSize + 2
                            font.family: Theme.fontFamily
                        }

                        MouseArea {
                            id: muteMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (volumeWidget.sink && volumeWidget.sink.audio) {
                                    volumeWidget.sink.audio.muted = !volumeWidget.sink.audio.muted
                                }
                            }
                        }
                    }

                    // Interactive Slider Track
                    Rectangle {
                        id: sliderTrack
                        Layout.fillWidth: true
                        height: 10
                        radius: height / 2
                        color: Theme.colHover

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * (volumeWidget.volumeLevel / 100)
                            radius: height / 2
                            color: volumeWidget.volumeMuted ? Theme.colMuted : Theme.colVol
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                var newVol = Math.max(0, Math.min(1, mouse.x / width))
                                volumeWidget.setVolume(newVol)
                            }
                            onPositionChanged: mouse => {
                                if (pressed) {
                                    var newVol = Math.max(0, Math.min(1, mouse.x / width))
                                    volumeWidget.setVolume(newVol)
                                }
                            }
                        }
                    }

                    // Percentage Text
                    Text {
                        text: `${volumeWidget.volumeLevel}%`
                        color: Theme.colFg
                        font.pixelSize: Theme.fontSize - 1
                        font.family: Theme.fontFamily
                        font.bold: true
                        Layout.preferredWidth: 36
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.colDivider
            }

            // Input / Microphone Section
            Column {
                width: parent.width
                spacing: 6

                RowLayout {
                    width: parent.width

                    Text {
                        text: "󰍬 Input (Mic)"
                        color: Theme.colFg
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                        font.bold: true
                    }

                    Text {
                        text: volumeWidget.source ? (volumeWidget.source.description || volumeWidget.source.name) : "Default"
                        color: Theme.colMuted
                        font.pixelSize: Theme.fontSize - 3
                        font.family: Theme.fontFamily
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideRight
                    }
                }

                // Mic Slider Row
                RowLayout {
                    width: parent.width
                    spacing: 8

                    // Mic Mute button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: Theme.itemRadius
                        color: micMuteMouse.containsMouse ? Theme.colHoverStrong : Theme.colDivider

                        Text {
                            anchors.centerIn: parent
                            text: volumeWidget.micMuted ? "󰍭" : "󰍬"
                            color: volumeWidget.micMuted ? Theme.colRed : Theme.colCpu
                            font.pixelSize: Theme.fontSize + 2
                            font.family: Theme.fontFamily
                        }

                        MouseArea {
                            id: micMuteMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (volumeWidget.source && volumeWidget.source.audio) {
                                    volumeWidget.source.audio.muted = !volumeWidget.source.audio.muted
                                }
                            }
                        }
                    }

                    // Interactive Mic Track
                    Rectangle {
                        id: micTrack
                        Layout.fillWidth: true
                        height: 10
                        radius: height / 2
                        color: Theme.colHover

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * (volumeWidget.micLevel / 100)
                            radius: height / 2
                            color: volumeWidget.micMuted ? Theme.colMuted : Theme.colCpu
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                var newVol = Math.max(0, Math.min(1, mouse.x / width))
                                volumeWidget.setMicVolume(newVol)
                            }
                            onPositionChanged: mouse => {
                                if (pressed) {
                                    var newVol = Math.max(0, Math.min(1, mouse.x / width))
                                    volumeWidget.setMicVolume(newVol)
                                }
                            }
                        }
                    }

                    // Mic Percentage Text
                    Text {
                        text: `${volumeWidget.micLevel}%`
                        color: Theme.colFg
                        font.pixelSize: Theme.fontSize - 1
                        font.family: Theme.fontFamily
                        font.bold: true
                        Layout.preferredWidth: 36
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }

            // Bottom action: Open mixer
            Rectangle {
                width: parent.width
                height: 26
                radius: Theme.itemRadius
                color: mixerMouse.containsMouse ? Theme.colSelected : Theme.colSurface

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        text: "󰍰"
                        color: Theme.colFg
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                    }
                    Text {
                        text: "Advanced Audio Settings"
                        color: Theme.colFg
                        font.pixelSize: Theme.fontSize - 2
                        font.family: Theme.fontFamily
                    }
                }

                MouseArea {
                    id: mixerMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        pavuProc.running = true
                        volumeWidget.dropdownOpen = false
                    }
                }
            }
        }
    }
}
