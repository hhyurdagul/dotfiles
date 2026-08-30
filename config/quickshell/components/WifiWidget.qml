import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

DropdownWidget {
    id: wifiWidget
    popupWidth: 260
    popupHeight: Math.min(wifiNetworks.length * 40 + 70, 360)
    popupXOffset: 250

    property string wifiSSID: ""
    property int wifiSignal: 0
    property bool wifiConnected: false
    property var wifiNetworks: []
    property bool wifiEnabled: true

    // Network speed tracking
    property real downloadSpeed: 0  // bytes per second
    property real uploadSpeed: 0
    property real lastRxBytes: 0
    property real lastTxBytes: 0

    function formatSpeed(bytesPerSec) {
        if (bytesPerSec < 1024) return bytesPerSec.toFixed(0) + " B/s"
        if (bytesPerSec < 1024 * 1024) return (bytesPerSec / 1024).toFixed(0) + " K/s"
        return (bytesPerSec / 1024 / 1024).toFixed(1) + " M/s"
    }

    onOpened: wifiScanProc.running = true

    // WiFi current connection via nmcli
    Process {
        id: wifiCurrentProc
        command: ["sh", "-c", "nmcli -t -f ACTIVE,SSID,SIGNAL,SECURITY dev wifi 2>/dev/null | awk -F: '$1==\"yes\" { print $2 \"\\t\" $3 \"\\t\" $4; exit }'"]
        stdout: SplitParser {
            onRead: data => {
                if (!data || !data.trim()) {
                    wifiWidget.wifiConnected = false
                    wifiWidget.wifiSSID = ""
                    wifiWidget.wifiSignal = 0
                    return
                }
                var parts = data.trim().split('\t')
                if (parts.length >= 2) {
                    wifiWidget.wifiConnected = true
                    wifiWidget.wifiSSID = parts[0]
                    wifiWidget.wifiSignal = parseInt(parts[1]) || 0
                }
            }
        }
        Component.onCompleted: running = true
    }

    // WiFi radio state check
    Process {
        id: wifiRadioProc
        command: ["sh", "-c", "nmcli radio wifi 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => {
                if (data) {
                    wifiWidget.wifiEnabled = data.trim() === "enabled"
                }
            }
        }
        Component.onCompleted: running = true
    }

    // WiFi network scan via nmcli
    Process {
        id: wifiScanProc
        property string output: ""
        command: ["sh", "-c", "nmcli -t -f SSID,SIGNAL,SECURITY dev wifi list --rescan auto 2>/dev/null | awk -F: '$1!=\"\" { print $1 \"\\t\" $2 \"\\t\" $3 }' | sort -u -k1,1 | sort -t \"$(printf '\\t')\" -k2,2nr | head -15"]
        stdout: SplitParser {
            onRead: data => {
                if (data) wifiScanProc.output += data + "\n"
            }
        }
        onRunningChanged: {
            if (running) {
                output = ""
            } else if (output) {
                var lines = output.trim().split('\n')
                var networks = []
                var seen = {}
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split('\t')
                    if (parts.length >= 2 && parts[0] && !seen[parts[0]]) {
                        seen[parts[0]] = true
                        networks.push({
                            ssid: parts[0],
                            signal: parseInt(parts[1]) || 0,
                            security: parts[2] || ""
                        })
                    }
                }
                wifiWidget.wifiNetworks = networks
            }
        }
    }

    // WiFi connect process
    Process {
        id: wifiConnectProc
        property string targetSSID: ""
        command: ["sh", "-c", "nmcli dev wifi connect \"$1\"", "nmcli-connect", targetSSID]
        onExited: {
            wifiScanDelay.restart()
        }
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

    // Network speed process
    Process {
        id: netSpeedProc
        command: ["sh", "-c", "cat /proc/net/dev | grep -E 'wl|en' | head -1"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split(/\s+/)
                if (parts.length >= 10) {
                    var rxBytes = parseFloat(parts[1]) || 0
                    var txBytes = parseFloat(parts[9]) || 0

                    if (wifiWidget.lastRxBytes > 0) {
                        wifiWidget.downloadSpeed = rxBytes - wifiWidget.lastRxBytes
                        wifiWidget.uploadSpeed = txBytes - wifiWidget.lastTxBytes
                    }
                    wifiWidget.lastRxBytes = rxBytes
                    wifiWidget.lastTxBytes = txBytes
                }
            }
        }
        Component.onCompleted: running = true
    }

    // Periodic Update timer
    Timer {
        interval: 2000
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
                    color: mouseArea.containsMouse ? Qt.rgba(255, 255, 255, 0.1) : "transparent"
                    radius: 6

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 6
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
