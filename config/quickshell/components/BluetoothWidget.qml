import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

DropdownWidget {
    id: btWidget
    popupWidth: 240
    popupHeight: Math.max(btDevices.length * 40 + 100, 150)

    property bool btPowered: false
    property bool btConnected: false
    property string btConnectedDevice: ""
    property string btConnectedMac: ""
    property var btDevices: []

    function refreshStatus() {
        btStatusProc.running = true
        btConnectedProc.running = true
    }

    onOpened: {
        btDevicesProc.running = true
        refreshStatus()
    }

    Process {
        id: btStatusProc
        property string output: ""
        command: ["bluetoothctl", "show"]
        stdout: SplitParser {
            onRead: data => {
                if (data) btStatusProc.output += data + "\n"
            }
        }
        onRunningChanged: {
            if (running) {
                output = ""
            } else {
                btWidget.btPowered = output.includes("Powered: yes")
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: btConnectedProc
        property string output: ""
        command: ["bluetoothctl", "devices", "Connected"]
        stdout: SplitParser {
            onRead: data => {
                if (data) btConnectedProc.output += data + "\n"
            }
        }
        onRunningChanged: {
            if (running) {
                output = ""
            } else {
                var match = output.match(/Device\s+([0-9A-F:]+)\s+(.+)/)
                btWidget.btConnected = match !== null
                btWidget.btConnectedMac = match ? match[1] : ""
                btWidget.btConnectedDevice = match ? match[2].trim() : ""
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: btDevicesProc
        property string output: ""
        command: ["bluetoothctl", "devices", "Paired"]
        stdout: SplitParser {
            onRead: data => {
                if (data) btDevicesProc.output += data + "\n"
            }
        }
        onRunningChanged: {
            if (running) {
                output = ""
            } else {
                var lines = output.trim().split("\n")
                var devices = []
                for (var i = 0; i < lines.length; i++) {
                    var match = lines[i].match(/Device\s+([0-9A-F:]+)\s+(.+)/)
                    if (match) {
                        devices.push({ mac: match[1], name: match[2] })
                    }
                }
                btWidget.btDevices = devices
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: btConnectProc
        property string targetMAC: ""
        command: ["bluetoothctl", "connect", targetMAC]
        onExited: btWidget.refreshStatus()
    }

    Process {
        id: btDisconnectProc
        property string targetMAC: ""
        command: ["bluetoothctl", "disconnect", targetMAC]
        onExited: btWidget.refreshStatus()
    }

    Process {
        id: btPowerProc
        property bool powerOn: true
        command: ["bluetoothctl", "power", powerOn ? "on" : "off"]
        onExited: btWidget.refreshStatus()
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: btWidget.refreshStatus()
    }

    // Icon content
    Text {
        id: btText
        anchors.verticalCenter: parent.verticalCenter
        text: !btPowered ? "󰂲" :
              btConnected ? "󰂱" : "󰂯"
        color: !btPowered ? Theme.colMuted :
               btConnected ? Theme.colBluetoothConnected : Theme.colBluetooth
        font.pixelSize: Theme.fontSize + 4
        font.family: Theme.fontFamily
        font.bold: true
    }

    // Popup content
    popupContent: Component {
        Column {
            spacing: 4

            // Header with power toggle
            RowLayout {
                width: parent.width
                spacing: 8

                Text {
                    text: btWidget.btPowered ? (btWidget.btConnected ? "󰂱 " + btWidget.btConnectedDevice : "󰂯 Bluetooth") : "󰂲 Bluetooth Off"
                    color: Theme.colFg
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                    font.bold: true
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 40
                    height: 20
                    radius: height / 2
                    color: btWidget.btPowered ? Theme.colBluetooth : Theme.colMuted

                    Rectangle {
                        width: 16
                        height: 16
                        radius: height / 2
                        color: Theme.colFg
                        x: btWidget.btPowered ? parent.width - width - 2 : 2
                        anchors.verticalCenter: parent.verticalCenter

                        Behavior on x {
                            NumberAnimation { duration: 150 }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            btPowerProc.powerOn = !btWidget.btPowered
                            btPowerProc.running = true
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.colMuted
            }

            // Paired devices header
            Text {
                text: "Paired Devices"
                color: Theme.colMuted
                font.pixelSize: Theme.fontSize - 2
                font.family: Theme.fontFamily
                visible: btWidget.btPowered
            }

            // Device list
            ListView {
                id: btDeviceListView
                width: parent.width
                height: parent.height - 80
                clip: true
                model: btWidget.btDevices
                spacing: 2
                visible: btWidget.btPowered

                delegate: Rectangle {
                    width: btDeviceListView.width
                    height: 36
                    color: btMouseArea.containsMouse ? Theme.colHover : "transparent"
                    radius: Theme.itemRadius

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.densePadding
                        spacing: 8

                        Text {
                            text: "󰂯"
                            color: Theme.colBluetooth
                            font.pixelSize: Theme.fontSize
                            font.family: Theme.fontFamily
                        }

                        Text {
                            text: modelData.name
                            color: modelData.mac === btWidget.btConnectedMac ? Theme.colBluetooth : Theme.colFg
                            font.pixelSize: Theme.fontSize - 1
                            font.family: Theme.fontFamily
                            font.bold: modelData.mac === btWidget.btConnectedMac
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: modelData.mac === btWidget.btConnectedMac ? "Connected" : ""
                            color: Theme.colBluetooth
                            font.pixelSize: Theme.fontSize - 3
                            font.family: Theme.fontFamily
                        }
                    }

                    MouseArea {
                        id: btMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.mac === btWidget.btConnectedMac) {
                                btDisconnectProc.targetMAC = modelData.mac
                                btDisconnectProc.running = true
                            } else {
                                btConnectProc.targetMAC = modelData.mac
                                btConnectProc.running = true
                            }
                            btWidget.dropdownOpen = false
                        }
                    }
                }
            }

            // Empty state
            Text {
                text: btWidget.btPowered ? "No paired devices" : "Turn on Bluetooth to see devices"
                color: Theme.colMuted
                font.pixelSize: Theme.fontSize - 2
                font.family: Theme.fontFamily
                visible: btWidget.btDevices.length === 0
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
