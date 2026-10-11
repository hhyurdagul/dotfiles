pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Handy's recording state, for the bottom overlay. Handy holds
// a PipeWire capture stream named alsa_capture.handy exactly while it records.
// Its own overlay can't stand in: WebKitGTK paints only the changed parts of
// its transparent window, so it shows fragments.
Singleton {
    id: dictation

    readonly property var node: Pipewire.nodes.values.find(n => n.name === "alsa_capture.handy") ?? null
    readonly property bool recording: node !== null
    readonly property int barCount: 16
    // Recent input peaks, oldest first, for the overlay waveform.
    property var levels: []
    property int elapsedSeconds: 0

    onRecordingChanged: {
        levels = []
        elapsedSeconds = 0
    }

    PwNodePeakMonitor {
        id: peakMonitor
        node: dictation.node
        enabled: dictation.recording
    }

    Timer {
        interval: 60
        running: dictation.recording
        repeat: true
        onTriggered: dictation.levels = dictation.levels.concat([peakMonitor.peak]).slice(-dictation.barCount)
    }

    Timer {
        interval: 1000
        running: dictation.recording
        repeat: true
        onTriggered: dictation.elapsedSeconds += 1
    }
}
