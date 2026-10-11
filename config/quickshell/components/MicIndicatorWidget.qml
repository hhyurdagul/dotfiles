import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import ".."

// Microphone icon while any app captures from a real input device: dictation,
// calls, recordings. Sink monitors (visualizers, screen-recorder system audio)
// are sinks, not sources, so they don't count.
Item {
    id: micWidget

    readonly property bool micActive: Pipewire.links.values.some(link =>
        link.source?.type === PwNodeType.AudioSource && link.target?.isStream)

    visible: micActive
    Layout.preferredWidth: micActive ? micPill.width : 0
    Layout.preferredHeight: parent.height

    Rectangle {
        id: micPill
        anchors.centerIn: parent
        height: 24
        width: 28
        radius: Theme.itemRadius
        color: Qt.rgba(Theme.colMic.r, Theme.colMic.g, Theme.colMic.b, 0.2)
        border.color: Theme.colMic
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: "󰍬"
            color: Theme.colMic
            font.pixelSize: Theme.fontSize + 1
            font.family: Theme.fontFamily
            font.bold: true
        }
    }
}
