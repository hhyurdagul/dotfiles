import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."

DropdownWidget {
    id: memWidget
    popupWidth: 280
    popupHeight: 300

    property int memUsage: 0
    property string memUsedStr: ""
    property string memTotalStr: ""
    property var topMemProcesses: []
    function formatBytes(bytes) {
        if (bytes < 1024 * 1024 * 1024) {
            return (bytes / 1024 / 1024).toFixed(0) + " MiB"
        }
        return (bytes / 1024 / 1024 / 1024).toFixed(1) + " GiB"
    }


    onOpened: topMemProc.running = true

    // RAM usage statistics. `free` is parsed one line at a time because
    // SplitParser emits one callback per line.
    Process {
        id: memProc
        command: ["free", "-b"]
        stdout: SplitParser {
            onRead: data => {
                if (!data || !data.startsWith("Mem:")) return

                var parts = data.trim().split(/\s+/)
                if (parts.length < 3) return

                var total = parseInt(parts[1]) || 1
                var used = parseInt(parts[2]) || 0
                memWidget.memTotalStr = memWidget.formatBytes(total)
                memWidget.memUsedStr = memWidget.formatBytes(used)
                memWidget.memUsage = Math.round(100 * used / total)
            }
        }
        Component.onCompleted: running = true
    }

    // Top memory consuming processes
    Process {
        id: topMemProc
        property string output: ""
        command: ["sh", "-c", "ps -eo pid,comm,%mem,rss --sort=-rss --no-headers | awk '$2!=\"ps\" { printf \"%s\\t%s\\t%s\\t%.1f MB\\n\", $1, $2, $3, $4/1024 }' | head -10"]
        stdout: SplitParser {
            onRead: data => {
                if (data) topMemProc.output += data + "\n"
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
                    if (parts.length >= 4 && parts[1]) {
                        procs.push({
                            pid: parts[0].trim(),
                            name: parts[1].trim(),
                            memPct: parseFloat(parts[2]) || 0,
                            memRss: parts[3].trim()
                        })
                    }
                }
                memWidget.topMemProcesses = procs
            }
        }
    }

    Process {
        id: btopProc
        command: ["kitty", "-e", "btop"]
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            memProc.running = true
            if (memWidget.dropdownOpen) {
                topMemProc.running = true
            }
        }
    }

    // Top bar icon content
    Text {
        id: memText
        anchors.verticalCenter: parent.verticalCenter
        text: `󰾆 ${memWidget.memUsage}%`
        color: memWidget.memUsage > 85 ? Theme.colRed : (memWidget.memUsage > 70 ? Theme.colOrange : Theme.colMem)
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
                    text: `󰾆 RAM: ${memWidget.memUsedStr} / ${memWidget.memTotalStr} (${memWidget.memUsage}%)`
                    color: Theme.colFg
                    font.pixelSize: Theme.fontSize - 1
                    font.family: Theme.fontFamily
                    font.bold: true
                    Layout.fillWidth: true
                }

                Text {
                    text: topMemProc.running ? "󰑐" : "󰑓"
                    color: Theme.colMem
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: topMemProc.running = true
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
                    text: "RAM"
                    color: Theme.colMuted
                    font.pixelSize: 10
                    font.family: Theme.fontFamily
                    font.bold: true
                    Layout.preferredWidth: 64
                    horizontalAlignment: Text.AlignRight
                }
            }

            // Scrollable process list
            ListView {
                id: memListView
                width: parent.width
                height: parent.height - 75
                clip: true
                model: memWidget.topMemProcesses
                spacing: 3

                delegate: Rectangle {
                    width: memListView.width
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
                            Layout.preferredWidth: 64
                            height: 20
                            radius: Theme.tinyRadius
                            color: Theme.colMemSurface

                            Text {
                                anchors.centerIn: parent
                                text: modelData.memRss
                                color: Theme.colMem
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
                        memWidget.dropdownOpen = false
                    }
                }
            }
        }
    }
}
