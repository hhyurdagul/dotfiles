import QtQuick
import Quickshell.Io
import Quickshell.Services.Pipewire
import ".."

Text {
    id: volumeWidget

    property var sink: Pipewire.defaultAudioSink
    property int volumeLevel: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0
    property bool volumeMuted: sink && sink.audio ? sink.audio.muted : false
    property string audioSink: detectSinkType(sink)

    function detectSinkType(node) {
        if (!node) return "speaker"

        var details = (node.name + " " + node.description + " " + node.nickname).toLowerCase()
        if (details.includes("headphone") || details.includes("headset")) return "headphone"
        if (details.includes("bluez") || details.includes("bluetooth")) return "bluetooth"
        if (details.includes("hdmi") || details.includes("displayport")) return "hdmi"
        return "speaker"
    }

    function changeVolume(delta) {
        if (!sink || !sink.audio) return
        sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + delta))
    }

    property string volumeIcon: {
        if (volumeMuted) return "󰖁"
        if (audioSink === "headphone") return "󰋋"
        if (audioSink === "bluetooth") return "󰂰"
        if (audioSink === "hdmi") return "󰡁"
        if (volumeLevel === 0) return "󰕿"
        if (volumeLevel < 30) return "󰕿"
        if (volumeLevel < 70) return "󰖀"
        return "󰕾"
    }

    text: `${volumeIcon} ${volumeLevel}%`
    color: volumeMuted ? Theme.colMuted :
           audioSink === "headphone" ? "#f1fa8c" :
           audioSink === "bluetooth" ? Theme.colBluetooth :
           Theme.colVol
    font.pixelSize: Theme.fontSize
    font.family: Theme.fontFamily
    font.bold: true

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                wiremixProc.running = true
            } else if (volumeWidget.sink && volumeWidget.sink.audio) {
                volumeWidget.sink.audio.muted = !volumeWidget.sink.audio.muted
            }
        }
        onWheel: wheel => {
            volumeWidget.changeVolume(wheel.angleDelta.y > 0 ? 0.05 : -0.05)
        }
    }

    Process {
        id: wiremixProc
        command: ["xdg-terminal-exec", "wiremix"]
    }

    PwObjectTracker {
        objects: [volumeWidget.sink]
    }
}
