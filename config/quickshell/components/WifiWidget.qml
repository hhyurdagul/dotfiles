import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

DropdownWidget {
    id: wifiWidget
    popupWidth: 260
    popupHeight: Math.min(wifiNetworks.length * 40 + 70, 360)

    readonly property string wifiSSID: NetworkStatus.ssid
    readonly property int wifiSignal: NetworkStatus.strength
    readonly property bool wifiConnected: NetworkStatus.connected
    readonly property var wifiNetworks: NetworkStatus.networks
    readonly property bool wifiEnabled: NetworkStatus.radioEnabled
    readonly property real downloadSpeed: NetworkStatus.downloadSpeed
    readonly property real uploadSpeed: NetworkStatus.uploadSpeed

    function formatSpeed(bytesPerSec) {
        if (bytesPerSec < 1024) return bytesPerSec.toFixed(0) + " B/s"
        if (bytesPerSec < 1024 * 1024) return (bytesPerSec / 1024).toFixed(0) + " K/s"
        return (bytesPerSec / 1024 / 1024).toFixed(1) + " M/s"
    }

    onOpened: NetworkStatus.scan()

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
                    text: NetworkStatus.scanning ? "󰑐" : "󰑓"
                    color: Theme.colNetwork
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NetworkStatus.scan()
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
                            NetworkStatus.connectTo(modelData.ssid)
                            wifiWidget.dropdownOpen = false
                        }
                    }
                }
            }
        }
    }
}
