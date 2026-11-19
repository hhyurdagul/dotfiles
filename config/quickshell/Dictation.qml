pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// Handy's recording state, for the bottom overlay. Handy holds a PipeWire
// capture stream exactly while it records. Its recorder (cpal over
// PulseAudio) names that stream cpal-pulseaudio-<pid> and sets nothing else
// that identifies Handy, so the PID of handy.service tells it apart from
// other cpal programs.
// Handy's own overlay can't stand in: WebKitGTK paints only the changed
// parts of its transparent window, so it shows fragments.
Singleton {
    id: dictation

    readonly property string streamPrefix: "cpal-pulseaudio-"
    property int handyPid: 0
    readonly property string streamName: handyPid > 0 ? streamPrefix + handyPid : ""
    readonly property var node: Pipewire.nodes.values.find(n => n.isStream && n.name === streamName) ?? null
    readonly property bool recording: node !== null
    // cpal streams that don't match the known PID. A new one means Handy may
    // have restarted under a new PID, so look it up again.
    readonly property string unmatchedStreams: Pipewire.nodes.values
        .filter(n => n.isStream && n.name.startsWith(streamPrefix) && n.name !== streamName)
        .map(n => n.name).join(" ")
    onUnmatchedStreamsChanged: if (unmatchedStreams !== "") pidProc.running = true

    Process {
        id: pidProc
        command: ["systemctl", "--user", "show", "--property=MainPID", "--value", "handy.service"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: dictation.handyPid = parseInt(text.trim()) || 0
        }
    }

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
