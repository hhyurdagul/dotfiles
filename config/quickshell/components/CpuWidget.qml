import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."

DropdownWidget {
    id: cpuWidget
    popupWidth: 280
    popupHeight: 300

    property int cpuUsage: 0
    property var lastCpuIdle: 0
    property var lastCpuTotal: 0
    property var topCpuProcesses: []

    onOpened: topCpuProc.running = true

    // Calculate live total CPU usage from /proc/stat
    Process {
        id: cpuProc
        command: ["cat", "/proc/stat"]
        stdout: SplitParser {
            onRead: data => {
                if (!data || !data.startsWith("cpu ")) return
                var parts = data.trim().split(/\s+/)
                var user = parseInt(parts[1]) || 0
                var nice = parseInt(parts[2]) || 0
                var system = parseInt(parts[3]) || 0
                var idle = parseInt(parts[4]) || 0
                var iowait = parseInt(parts[5]) || 0
                var irq = parseInt(parts[6]) || 0
                var softirq = parseInt(parts[7]) || 0

                var total = user + nice + system + idle + iowait + irq + softirq
                var idleTime = idle + iowait

                if (cpuWidget.lastCpuTotal > 0) {
                    var totalDiff = total - cpuWidget.lastCpuTotal
                    var idleDiff = idleTime - cpuWidget.lastCpuIdle
                    if (totalDiff > 0) {
                        cpuWidget.cpuUsage = Math.round(100 * (totalDiff - idleDiff) / totalDiff)
                    }
                }
                cpuWidget.lastCpuTotal = total
                cpuWidget.lastCpuIdle = idleTime
            }
        }
        Component.onCompleted: running = true
    }

    // Top CPU consuming processes
    Process {
        id: topCpuProc
        property string output: ""
        command: ["sh", "-c", "ps -eo pid,comm,%cpu,%mem --sort=-%cpu --no-headers | awk '$2!=\"ps\" { printf \"%s\\t%s\\t%s\\t%s\\n\", $1, $2, $3, $4 }' | head -10"]
        stdout: SplitParser {
            onRead: data => {
                if (data) topCpuProc.output += data + "\n"
            }
        }
        onRunningChanged: {
            if (running) {
                output = ""
            } else if (output) {
                var lines = output.trim().split('\n')
                var procs = []
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split('\t')
                    if (parts.length >= 3 && parts[1]) {
                        procs.push({
                            pid: parts[0].trim(),
                            name: parts[1].trim(),
                            cpu: parseFloat(parts[2]) || 0,
                            mem: parseFloat(parts[3]) || 0
                        })
                    }
                }
                cpuWidget.topCpuProcesses = procs
            }
        }
    }

    // Process to launch btop / terminal monitor
    Process {
        id: btopProc
        command: ["kitty", "-e", "btop"]
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            cpuProc.running = true
            if (cpuWidget.dropdownOpen) {
                topCpuProc.running = true
            }
        }
    }

    // Top bar icon content
    Text {
        id: cpuText
        anchors.verticalCenter: parent.verticalCenter
        text: `󰍛 ${cpuWidget.cpuUsage}%`
        color: cpuWidget.cpuUsage > 80 ? Theme.colRed : (cpuWidget.cpuUsage > 50 ? Theme.colOrange : Theme.colCpu)
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
        font.bold: true
    }

    // Dropdown popup content
    popupContent: Component {
        Column {
            spacing: 8
            width: parent.width

            // Header
            RowLayout {
                width: parent.width

                Text {
                    text: `󰍛 CPU Usage: ${cpuWidget.cpuUsage}%`
                    color: Theme.colFg
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                    font.bold: true
                    Layout.fillWidth: true
                }

                Text {
                    text: topCpuProc.running ? "󰑐" : "󰑓"
                    color: Theme.colCpu
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: topCpuProc.running = true
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.colDivider
            }

            // Table Header
            RowLayout {
                width: parent.width
                spacing: 6

                Text {
                    text: "PROCESS"
                    color: Theme.colMuted
                    font.pixelSize: 10
                    font.family: Theme.fontFamily
                    font.bold: true
                    Layout.fillWidth: true
                }

                Text {
                    text: "PID"
                    color: Theme.colMuted
                    font.pixelSize: 10
                    font.family: Theme.fontFamily
                    font.bold: true
                    Layout.preferredWidth: 46
                    horizontalAlignment: Text.AlignRight
                }

                Text {
                    text: "CPU"
                    color: Theme.colMuted
                    font.pixelSize: 10
                    font.family: Theme.fontFamily
                    font.bold: true
                    Layout.preferredWidth: 46
                    horizontalAlignment: Text.AlignRight
                }
            }

            // Scrollable process list
            ListView {
                id: cpuListView
                width: parent.width
                height: parent.height - 75
                clip: true
                model: cpuWidget.topCpuProcesses
                spacing: 3

                delegate: Rectangle {
                    width: cpuListView.width
                    height: 28
                    radius: Theme.compactRadius
                    color: itemMouse.containsMouse ? Theme.colHover : Theme.colSurfaceFaint

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        spacing: 6

                        Text {
                            text: modelData.name
                            color: Theme.colFg
                            font.pixelSize: Theme.fontSize - 1
                            font.family: Theme.fontFamily
                            font.bold: true
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: modelData.pid
                            color: Theme.colMuted
                            font.pixelSize: Theme.fontSize - 3
                            font.family: Theme.fontFamily
                            Layout.preferredWidth: 46
                            horizontalAlignment: Text.AlignRight
                        }

                        Rectangle {
                            Layout.preferredWidth: 46
                            height: 20
                            radius: Theme.tinyRadius
                            color: modelData.cpu > 50 ? Theme.colDangerSurface : Theme.colCpuSurface

                            Text {
                                anchors.centerIn: parent
                                text: `${modelData.cpu.toFixed(1)}%`
                                color: modelData.cpu > 50 ? Theme.colRed : Theme.colCpu
                                font.pixelSize: 10
                                font.family: Theme.fontFamily
                                font.bold: true
                            }
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                    }
                }
            }

            // Bottom action: Open btop
            Rectangle {
                width: parent.width
                height: 24
                radius: Theme.compactRadius
                color: btopMouse.containsMouse ? Theme.colSelected : Theme.colSurface

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        text: "󰍹"
                        color: Theme.colFg
                        font.pixelSize: 11
                        font.family: Theme.fontFamily
                    }
                    Text {
                        text: "Open System Monitor"
                        color: Theme.colFg
                        font.pixelSize: 11
                        font.family: Theme.fontFamily
                    }
                }

                MouseArea {
                    id: btopMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        btopProc.running = true
                        cpuWidget.dropdownOpen = false
                    }
                }
            }
        }
    }
}
