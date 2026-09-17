import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import ".."

DropdownWidget {
    id: btWidget
    popupWidth: 360
    popupHeight: 390

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool btPowered: adapter?.enabled ?? false
    readonly property var devices: adapter?.devices.values ?? []
    readonly property bool btConnected: devices.some(device => device.connected)
    property bool showAll: false
    property string statusMessage: ""
    property bool actionFailed: false
    property string targetAddress: ""

    // Keep each BlueZ record available, but collapse repeated names by default.
    // Prefer the connected record, then a paired record, without deleting bonds.
    readonly property var visibleDevices: {
        var sorted = devices.slice().sort((a, b) =>
            Number(b.connected) - Number(a.connected)
            || Number(b.paired) - Number(a.paired)
            || a.name.localeCompare(b.name)
            || a.address.localeCompare(b.address))
        if (showAll) return sorted
        var seen = {}
        return sorted.filter(device => {
            var key = device.name || device.address
            if (seen[key]) return false
            seen[key] = true
            return true
        })
    }

    property string action: ""
    property string actionPhase: ""

    function runAction(device) {
        if (actionProc.running) return
        targetAddress = device.address
        action = device.connected ? "disconnect" : device.paired ? "connect" : "pair"
        actionPhase = "agent"
        actionFailed = false
        statusMessage = (device.connected ? "Disconnecting " : device.paired ? "Connecting " : "Pairing ") + device.name + "…"
        actionProc.running = true
        actionTimeout.restart()
    }

    function finishAction(success, message) {
        if (actionPhase === "done") return
        actionFailed = !success
        statusMessage = message
        actionPhase = "done"
        actionProc.write("quit\n")
    }

    function handleActionOutput(data) {
        var line = data.replace(/\x1b\[[0-9;?]*[A-Za-z]/g, "").trim()
        if (actionPhase === "done") return
        if (/failed|error|not available|not ready/i.test(line)) {
            finishAction(false, line)
        } else if (actionPhase === "agent" && line.includes("Agent registered")) {
            // One-shot bluetoothctl commands skip agent registration. Keep this
            // interactive process alive through pairing, trust and connection.
            if (action === "disconnect") {
                actionPhase = "disconnect"
                actionProc.write("disconnect " + targetAddress + "\n")
            } else if (action === "pair") {
                actionPhase = "pairable"
                actionProc.write("pairable on\n")
            } else {
                actionPhase = "trust"
                actionProc.write("trust " + targetAddress + "\n")
            }
        } else if (actionPhase === "pairable" && line.includes("Changing pairable on succeeded")) {
            actionPhase = "pair"
            actionProc.write("pair " + targetAddress + "\n")
        } else if (actionPhase === "pair" && line.includes("Pairing successful")) {
            actionPhase = "trust"
            actionProc.write("trust " + targetAddress + "\n")
        } else if (actionPhase === "trust" && line.includes("trust succeeded")) {
            actionPhase = "connect"
            actionProc.write("connect " + targetAddress + "\n")
        } else if (actionPhase === "connect" && line.includes("Connection successful")) {
            finishAction(true, "Connected.")
        } else if (actionPhase === "disconnect" && line.includes("Successful disconnected")) {
            finishAction(true, "Disconnected.")
        }
    }

    Process {
        id: actionProc
        command: ["bluetoothctl", "--agent", "NoInputNoOutput"]
        stdinEnabled: true
        stdout: SplitParser { onRead: data => btWidget.handleActionOutput(data) }
        stderr: StdioCollector { id: actionError }
        onExited: (exitCode, exitStatus) => {
            actionTimeout.stop()
            if (btWidget.actionPhase !== "done") {
                btWidget.actionFailed = true
                btWidget.statusMessage = actionError.text.trim() || "Bluetooth request ended before completion. Try again."
            }
            btWidget.targetAddress = ""
        }
    }

    Timer {
        id: actionTimeout
        interval: 65000
        onTriggered: {
            btWidget.actionFailed = true
            btWidget.statusMessage = "Bluetooth request timed out. Check pairing mode and try again."
            btWidget.actionPhase = "done"
            actionProc.running = false
        }
    }

    Timer {
        id: scanTimer
        interval: 30000
        onTriggered: if (btWidget.adapter) btWidget.adapter.discovering = false
    }

    onDropdownOpenChanged: {
        if (!dropdownOpen && scanTimer.running) {
            scanTimer.stop()
            if (adapter) adapter.discovering = false
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: !btWidget.btPowered ? "󰂲" : btWidget.btConnected ? "󰂱" : "󰂯"
        color: !btWidget.btPowered ? Theme.colMuted : btWidget.btConnected ? Theme.colBluetoothConnected : Theme.colBluetooth
        font.pixelSize: Theme.fontSize + 4
        font.family: Theme.fontFamily
        font.bold: true
    }

    popupContent: Component {
        ColumnLayout {
            spacing: Theme.densePadding

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Bluetooth"
                    color: Theme.colFg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                    Layout.fillWidth: true
                }
                Rectangle {
                    implicitWidth: 60
                    implicitHeight: 26
                    radius: Theme.itemRadius
                    color: btWidget.btPowered ? Theme.colBluetooth : Theme.colSurface
                    Text {
                        anchors.centerIn: parent
                        text: btWidget.btPowered ? "On" : "Off"
                        color: btWidget.btPowered ? Theme.colBg : Theme.colFg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: btWidget.adapter !== null && !actionProc.running
                        cursorShape: Qt.PointingHandCursor
                        onClicked: btWidget.adapter.enabled = !btWidget.btPowered
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 28
                    color: scanMouse.containsMouse ? Theme.colHover : Theme.colSurface
                    radius: Theme.itemRadius
                    Text {
                        anchors.centerIn: parent
                        text: btWidget.adapter?.discovering ? "Stop scan" : "Scan for devices"
                        color: btWidget.btPowered ? Theme.colBluetooth : Theme.colMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                    }
                    MouseArea {
                        id: scanMouse
                        anchors.fill: parent
                        enabled: btWidget.btPowered && !actionProc.running
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (btWidget.adapter.discovering) {
                                btWidget.adapter.discovering = false
                                scanTimer.stop()
                            } else {
                                btWidget.adapter.discovering = true
                                scanTimer.restart()
                                btWidget.actionFailed = false
                                btWidget.statusMessage = "Put your headphones in pairing mode, then select them below."
                            }
                        }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 28
                    radius: Theme.itemRadius
                    color: allMouse.containsMouse ? Theme.colHover : Theme.colSurface
                    Text {
                        anchors.centerIn: parent
                        text: btWidget.showAll ? "Group names" : "Show all entries"
                        color: Theme.colFg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                    }
                    MouseArea {
                        id: allMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: btWidget.showAll = !btWidget.showAll
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: text.length > 0
                text: !btWidget.adapter ? "No Bluetooth adapter available."
                    : !btWidget.btPowered ? "Turn on Bluetooth to see devices."
                    : btWidget.visibleDevices.length === 0 ? "No devices found. Start a scan to pair headphones." : ""
                wrapMode: Text.WordWrap
                color: Theme.colMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
            }

            ListView {
                id: deviceList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: Theme.densePadding
                model: btWidget.btPowered ? btWidget.visibleDevices : []
                delegate: Rectangle {
                    id: deviceRow
                    required property var modelData
                    width: deviceList.width
                    height: 56
                    radius: Theme.itemRadius
                    color: deviceMouse.containsMouse ? Theme.colHover : Theme.colSurface
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.densePadding
                        spacing: 0
                        Text {
                            Layout.fillWidth: true
                            text: deviceRow.modelData.name || deviceRow.modelData.address
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            color: deviceRow.modelData.connected ? Theme.colBluetoothConnected : Theme.colFg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }
                        Text {
                            Layout.fillWidth: true
                            text: deviceRow.modelData.address + " · "
                                + (btWidget.targetAddress === deviceRow.modelData.address ? "Working…"
                                : deviceRow.modelData.connected ? "Connected · Disconnect"
                                : deviceRow.modelData.paired ? "Paired · Connect" : "Pair & connect")
                            elide: Text.ElideRight
                            color: Theme.colMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                        }
                    }
                    MouseArea {
                        id: deviceMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !actionProc.running
                        cursorShape: Qt.PointingHandCursor
                        onClicked: btWidget.runAction(deviceRow.modelData)
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: btWidget.statusMessage
                textFormat: Text.PlainText
                visible: text.length > 0
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
                color: btWidget.actionFailed ? Theme.colRed : Theme.colMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
            }
        }
    }
}
