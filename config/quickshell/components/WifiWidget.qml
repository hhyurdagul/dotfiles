import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

DropdownWidget {
    id: wifiWidget
    popupWidth: 260
    popupHeight: Math.min(wifiNetworks.length * 40 + 70, 360)

    property string wifiSSID: ""
    property int wifiSignal: 0
    property bool wifiConnected: false
    property var wifiNetworks: []
    property bool wifiEnabled: true
    property real downloadSpeed: 0
    property real uploadSpeed: 0
    property real lastRxBytes: 0
    property real lastTxBytes: 0
    property real lastSampleTime: 0

    function formatSpeed(bytesPerSec) {
        if (bytesPerSec < 1024) return bytesPerSec.toFixed(0) + " B/s"
        if (bytesPerSec < 1024 * 1024) return (bytesPerSec / 1024).toFixed(0) + " K/s"
        return (bytesPerSec / 1024 / 1024).toFixed(1) + " M/s"
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

    onOpened: wifiScanProc.running = true

    Process {
        id: wifiCurrentProc
        property string output: ""
        command: ["nmcli", "--terse", "--escape", "yes", "--fields",
                  "ACTIVE,SSID,SIGNAL,SECURITY", "device", "wifi", "list",
                  "--rescan", "no"]
        stdout: SplitParser {
            onRead: data => {
                if (data) wifiCurrentProc.output += data + "\n"
            }
        }
        onRunningChanged: {
            if (running) {
                output = ""
            } else {
                wifiWidget.wifiConnected = false
                wifiWidget.wifiSSID = ""
                wifiWidget.wifiSignal = 0
                var lines = output.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var fields = wifiWidget.parseNmcliLine(lines[i])
                    if (fields[0] === "yes") {
                        wifiWidget.wifiConnected = true
                        wifiWidget.wifiSSID = fields[1] || ""
                        wifiWidget.wifiSignal = parseInt(fields[2]) || 0
                        break
                    }
                }
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: wifiRadioProc
        command: ["nmcli", "radio", "wifi"]
        stdout: SplitParser {
            onRead: data => {
                if (data) wifiWidget.wifiEnabled = data.trim() === "enabled"
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: wifiScanProc
        property string output: ""
        command: ["nmcli", "--terse", "--escape", "yes", "--fields",
                  "ACTIVE,SSID,SIGNAL,SECURITY", "device", "wifi", "list",
                  "--rescan", "auto"]
        stdout: SplitParser {
            onRead: data => {
                if (data) wifiScanProc.output += data + "\n"
            }
        }
        onRunningChanged: {
            if (running) {
                output = ""
            } else {
                var lines = output.trim().split("\n")
                var networks = []
                var seen = {}
                for (var i = 0; i < lines.length; i++) {
                    var fields = wifiWidget.parseNmcliLine(lines[i])
                    var ssid = fields[1] || ""
                    if (ssid && !seen[ssid]) {
                        seen[ssid] = true
                        networks.push({
                            ssid: ssid,
                            signal: parseInt(fields[2]) || 0,
                            security: fields[3] || ""
                        })
                    }
                }
                networks.sort((left, right) => right.signal - left.signal)
                wifiWidget.wifiNetworks = networks.slice(0, 15)
            }
        }
    }

    Process {
        id: wifiConnectProc
        property string targetSSID: ""
        command: ["nmcli", "device", "wifi", "connect", targetSSID]
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) nmEditorProc.running = true
            wifiScanDelay.restart()
        }
    }

    Process {
        id: nmEditorProc
        command: ["nm-connection-editor"]
    }

    Timer {
        id: wifiScanDelay
        interval: 1500
        repeat: false
        onTriggered: {
            wifiCurrentProc.running = true
            wifiScanProc.running = true
        }
    }

    Process {
        id: netSpeedProc
        property real currentRx: 0
        property real currentTx: 0
        command: ["cat", "/proc/net/dev"]
        stdout: SplitParser {
            onRead: data => {
                var match = data.match(/^\s*(?:wl|en)[^:]*:\s*(.*)$/)
                if (!match) return
                var parts = match[1].trim().split(/\s+/)
                if (parts.length < 9) return
                netSpeedProc.currentRx += parseFloat(parts[0]) || 0
                netSpeedProc.currentTx += parseFloat(parts[8]) || 0
            }
        }
        onRunningChanged: {
            if (running) {
                currentRx = 0
                currentTx = 0
            } else {
                var now = Date.now()
                if (wifiWidget.lastRxBytes > 0 && now > wifiWidget.lastSampleTime) {
                    var elapsedSeconds = (now - wifiWidget.lastSampleTime) / 1000
                    wifiWidget.downloadSpeed = Math.max(0, currentRx - wifiWidget.lastRxBytes) / elapsedSeconds
                    wifiWidget.uploadSpeed = Math.max(0, currentTx - wifiWidget.lastTxBytes) / elapsedSeconds
                }
                wifiWidget.lastRxBytes = currentRx
                wifiWidget.lastTxBytes = currentTx
                wifiWidget.lastSampleTime = now
            }
        }
        Component.onCompleted: running = true
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            wifiCurrentProc.running = true
            netSpeedProc.running = true
            wifiRadioProc.running = true
        }
    }

    // Icon content in top bar
    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Text {
            id: wifiText
            anchors.verticalCenter: parent.verticalCenter
            text: !wifiWidget.wifiEnabled ? "󰤮" :
                  !wifiWidget.wifiConnected ? "󰤭" :
                  wifiWidget.wifiSignal >= 80 ? "󰤨" :
                  wifiWidget.wifiSignal >= 60 ? "󰤥" :
                  wifiWidget.wifiSignal >= 40 ? "󰤢" :
                  wifiWidget.wifiSignal >= 20 ? "󰤟" : "󰤯"
            color: wifiWidget.wifiConnected ? Theme.colNetwork : Theme.colMuted
            font.pixelSize: Theme.fontSize + 4
            font.family: Theme.fontFamily
            font.bold: true
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: wifiWidget.wifiConnected
            text: " " + formatSpeed(downloadSpeed) + "  " + formatSpeed(uploadSpeed)
            color: Theme.colNetwork
            font.pixelSize: Theme.fontSize - 2
            font.family: Theme.fontFamily
        }
    }

    // Popup content
    popupContent: Component {
        Column {
            spacing: 8

            // Header with status & refresh
            RowLayout {
                width: parent.width

                Text {
                    text: wifiWidget.wifiConnected ? "󰤨 " + wifiWidget.wifiSSID : "󰤭 Not Connected"
                    color: Theme.colFg
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                    font.bold: true
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: wifiScanProc.running ? "󰑐" : "󰑓"
                    color: Theme.colNetwork
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: wifiScanProc.running = true
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.colMuted
            }

            // Network list
            ListView {
                id: networkListView
                width: parent.width
                height: parent.height - 48
                clip: true
                model: wifiWidget.wifiNetworks
                spacing: 2

                delegate: Rectangle {
                    width: networkListView.width
                    height: 36
                    color: mouseArea.containsMouse ? Theme.colHover : "transparent"
                    radius: Theme.itemRadius

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.densePadding
                        spacing: 8

                        Text {
                            text: modelData.signal >= 80 ? "󰤨" :
                                  modelData.signal >= 60 ? "󰤥" :
                                  modelData.signal >= 40 ? "󰤢" :
                                  modelData.signal >= 20 ? "󰤟" : "󰤯"
                            color: Theme.colNetwork
                            font.pixelSize: Theme.fontSize
                            font.family: Theme.fontFamily
                        }

                        Text {
                            text: modelData.ssid
                            color: modelData.ssid === wifiWidget.wifiSSID ? Theme.colNetwork : Theme.colFg
                            font.pixelSize: Theme.fontSize - 1
                            font.family: Theme.fontFamily
                            font.bold: modelData.ssid === wifiWidget.wifiSSID
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: modelData.security ? "󰌾" : ""
                            color: Theme.colMuted
                            font.pixelSize: Theme.fontSize - 2
                            font.family: Theme.fontFamily
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            wifiConnectProc.targetSSID = modelData.ssid
                            wifiConnectProc.running = true
                            wifiWidget.dropdownOpen = false
                        }
                    }
                }
            }
        }
    }
}
