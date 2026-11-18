pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// CPU and RAM usage for every bar, sampled once from /proc regardless of how
// many screens show them. No subprocesses.
QtObject {
    id: stats

    property int cpuUsage: 0
    property real lastCpuIdle: 0
    property real lastCpuTotal: 0

    property int memUsage: 0
    property real memUsedBytes: 0
    property real memTotalBytes: 0

    function parseStat(text) {
        var line = text.split("\n").find(row => row.startsWith("cpu "))
        if (!line) return
        // user nice system idle iowait irq softirq steal
        var parts = line.trim().split(/\s+/).slice(1, 9).map(value => Number(value) || 0)
        var total = parts.reduce((sum, value) => sum + value, 0)
        var idle = parts[3] + parts[4]
        var totalDiff = total - lastCpuTotal
        if (lastCpuTotal > 0 && totalDiff > 0)
            cpuUsage = Math.round(100 * (totalDiff - (idle - lastCpuIdle)) / totalDiff)
        lastCpuTotal = total
        lastCpuIdle = idle
    }

    function parseMeminfo(text) {
        var values = {}
        for (var row of text.split("\n")) {
            var match = row.match(/^(\w+):\s+(\d+)/)
            if (match) values[match[1]] = Number(match[2]) * 1024
        }
        if (!values.MemTotal || values.MemAvailable === undefined) return
        // Same definition as `free`: used = total - available.
        memTotalBytes = values.MemTotal
        memUsedBytes = values.MemTotal - values.MemAvailable
        memUsage = Math.round(100 * memUsedBytes / memTotalBytes)
    }

    property var statFile: FileView {
        id: statFile
        path: "/proc/stat"
        onLoaded: stats.parseStat(text())
    }

    property var meminfoFile: FileView {
        id: meminfoFile
        path: "/proc/meminfo"
        onLoaded: stats.parseMeminfo(text())
    }

    property var sampleTimer: Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            statFile.reload()
            meminfoFile.reload()
        }
    }
}
