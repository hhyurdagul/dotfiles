pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Wi-Fi state and wired/wireless throughput for every bar. One nmcli poll and
// one /proc/net/dev sample per tick, regardless of screen count.
QtObject {
    id: network

    property string ssid: ""
    property int strength: 0
    property bool connected: false
    property bool radioEnabled: true
    property var networks: []
    readonly property bool scanning: scanProc.running

    property real downloadSpeed: 0
    property real uploadSpeed: 0
    property real lastRxBytes: 0
    property real lastTxBytes: 0
    property real lastSampleTime: 0

    function scan() {
        scanProc.running = true
    }

    function connectTo(targetSsid) {
        connectProc.targetSsid = targetSsid
        connectProc.running = true
    }

    function parseNmcliLine(line) {
        var fields = []
        var field = ""
        var escaped = false
        for (var i = 0; i < line.length; i++) {
            var character = line[i]
            if (escaped) {
                field += character
                escaped = false
            } else if (character === "\\") {
                escaped = true
            } else if (character === ":") {
                fields.push(field)
                field = ""
            } else {
                field += character
            }
        }
        fields.push(field)
        return fields
    }

    function parseCurrent(text) {
        var active = text.trim().split("\n").map(parseNmcliLine).find(fields => fields[0] === "yes")
        connected = !!active
        ssid = active ? active[1] || "" : ""
        strength = active ? parseInt(active[2]) || 0 : 0
    }

    function parseScan(text) {
        var seen = {}
        var found = []
        for (var line of text.trim().split("\n")) {
            var fields = parseNmcliLine(line)
            var name = fields[1] || ""
            if (!name || seen[name]) continue
            seen[name] = true
            found.push({ ssid: name, signal: parseInt(fields[2]) || 0, security: fields[3] || "" })
        }
        found.sort((left, right) => right.signal - left.signal)
        networks = found.slice(0, 15)
    }

    function parseNetDev(text) {
        var rx = 0
        var tx = 0
        for (var line of text.split("\n")) {
            var match = line.match(/^\s*(?:wl|en)[^:]*:\s*(.*)$/)
            if (!match) continue
            var parts = match[1].trim().split(/\s+/)
            if (parts.length < 9) continue
            rx += Number(parts[0]) || 0
            tx += Number(parts[8]) || 0
        }
        var now = Date.now()
        if (lastSampleTime > 0 && now > lastSampleTime) {
            var elapsedSeconds = (now - lastSampleTime) / 1000
            downloadSpeed = Math.max(0, rx - lastRxBytes) / elapsedSeconds
            uploadSpeed = Math.max(0, tx - lastTxBytes) / elapsedSeconds
        }
        lastRxBytes = rx
        lastTxBytes = tx
        lastSampleTime = now
    }

    property var currentProcess: Process {
        id: currentProc
        command: ["nmcli", "--terse", "--escape", "yes", "--fields",
                  "ACTIVE,SSID,SIGNAL,SECURITY", "device", "wifi", "list",
                  "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: network.parseCurrent(text)
        }
    }

    property var radioProcess: Process {
        id: radioProc
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: network.radioEnabled = text.trim() === "enabled"
        }
    }

    property var scanProcess: Process {
        id: scanProc
        command: ["nmcli", "--terse", "--escape", "yes", "--fields",
                  "ACTIVE,SSID,SIGNAL,SECURITY", "device", "wifi", "list",
                  "--rescan", "auto"]
        stdout: StdioCollector {
            onStreamFinished: network.parseScan(text)
        }
    }

    property var connectProcess: Process {
        id: connectProc
        property string targetSsid: ""
        command: ["nmcli", "device", "wifi", "connect", targetSsid]
        onExited: (exitCode, exitStatus) => {
            // Unknown secured networks need a password prompt nmcli can't show.
            if (exitCode !== 0) Quickshell.execDetached(["nm-connection-editor"])
            refreshDelay.restart()
        }
    }

    property var refreshDelayTimer: Timer {
        id: refreshDelay
        interval: 1500
        onTriggered: {
            currentProc.running = true
            scanProc.running = true
        }
    }

    property var netDevFile: FileView {
        id: netDevFile
        path: "/proc/net/dev"
        onLoaded: network.parseNetDev(text())
    }

    property var pollTimer: Timer {
        interval: 5000
        running: true
        repeat: true
        // The first throughput sample comes from the FileView's initial load.
        onTriggered: {
            currentProc.running = true
            radioProc.running = true
            netDevFile.reload()
        }
    }

    Component.onCompleted: {
        currentProc.running = true
        radioProc.running = true
    }
}
