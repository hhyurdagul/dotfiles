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

    readonly property int cpuUsage: SystemStats.cpuUsage
    property var topCpuProcesses: []

    onOpened: topCpuProc.running = true

    // Top CPU consumers right now. `top` reports usage since the previous
    // iteration, so only the second one (one second later) is current; the
    // first, like `ps %cpu`, is a lifetime average.
    Process {
        id: topCpuProc
        command: ["sh", "-c", "LC_ALL=C top -b -n2 -d1 -o %CPU -w 512 | awk '/^top -/ { n++ } n == 2 && header && NF >= 12 && $12 != \"top\" { cmd = $12; for (i = 13; i <= NF; i++) cmd = cmd \" \" $i; printf \"%s\\t%s\\t%s\\t%s\\n\", $1, cmd, $9, $10; if (++count == 10) exit } n == 2 && $1 == \"PID\" { header = 1 }'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var procs = []
                for (var line of text.trim().split("\n")) {
                    var parts = line.split("\t")
                    if (parts.length < 4 || !parts[1]) continue
                    procs.push({
                        pid: parts[0].trim(),
                        name: parts[1].trim(),
                        cpu: parseFloat(parts[2]) || 0,
                        mem: parseFloat(parts[3]) || 0
                    })
                }
                cpuWidget.topCpuProcesses = procs
            }
        }
    }

    Timer {
        interval: 3000
        running: cpuWidget.dropdownOpen
        repeat: true
        onTriggered: topCpuProc.running = true
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
                        Quickshell.execDetached(["kitty", "-e", "btop"])
                        cpuWidget.dropdownOpen = false
                    }
                }
            }
        }
    }
}
