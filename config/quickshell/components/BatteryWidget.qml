import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."

DropdownWidget {
    id: batteryWidget
    popupWidth: 230
    popupHeight: 200

    property int batteryLevel: 95
    property string batteryStatus: "Discharging"
    property bool isPluggedIn: false
    property string currentProfile: "balanced"
    property var availableProfiles: ["performance", "balanced", "power-saver"]
    onOpened: profileGetProc.running = true


    function getBatteryIcon(level, status, plugged) {
        if (status === "Charging") {
            if (level >= 95) return "󰂄"
            if (level >= 85) return "󰂋"
            if (level >= 75) return "󰂊"
            if (level >= 65) return "󰂉"
            if (level >= 55) return "󰂈"
            if (level >= 45) return "󰂇"
            if (level >= 35) return "󰂆"
            if (level >= 25) return "󰢝"
            if (level >= 15) return "󰢜"
            return "󰂅"
        }
        if (plugged && (status === "Full" || level >= 95)) {
            return "󰂄"
        }
        if (plugged && status !== "Discharging") {
            return "󰂄"
        }
        // Discharging
        if (level <= 10) return "󰂎"
        if (level <= 20) return "󰁺"
        if (level <= 30) return "󰁻"
        if (level <= 40) return "󰁼"
        if (level <= 50) return "󰁽"
        if (level <= 60) return "󰁾"
        if (level <= 70) return "󰁿"
        if (level <= 80) return "󰂀"
        if (level <= 90) return "󰂁"
        if (level < 100) return "󰂂"
        return "󰁹"
    }

    function getProfileIcon(profile) {
        switch(profile) {
            case "performance": return "󰓅"
            case "balanced": return "󰾅"
            case "power-saver": return "󰌪"
            default: return "󰾅"
        }
    }

    function getProfileColor(profile) {
        switch(profile) {
            case "performance": return Theme.colOrange
            case "balanced": return Theme.colFg
            case "power-saver": return Theme.colGreen
            default: return Theme.colFg
        }
    }

    function syncBatteryState() {
        var level = parseInt(capacityFile.text().trim())
        var status = statusFile.text().trim()
        var online = parseInt(adapterFile.text().trim()) === 1

        batteryWidget.batteryLevel = Number.isNaN(level) ? 100 : level
        batteryWidget.batteryStatus = status || "Unknown"
        batteryWidget.isPluggedIn = online || status === "Charging"
    }

    property var capacityFile: FileView {
        id: capacityFile
        path: "/sys/class/power_supply/BAT0/capacity"
        blockLoading: true
        printErrors: false
        onTextChanged: batteryWidget.syncBatteryState()
    }

    property var statusFile: FileView {
        id: statusFile
        path: "/sys/class/power_supply/BAT0/status"
        blockLoading: true
        printErrors: false
        onTextChanged: batteryWidget.syncBatteryState()
    }

    property var adapterFile: FileView {
        id: adapterFile
        path: "/sys/class/power_supply/ADP1/online"
        blockLoading: true
        printErrors: false
        onTextChanged: batteryWidget.syncBatteryState()
    }

    // Power Profile getter
    Process {
        id: profileGetProc
        command: ["powerprofilesctl", "get"]
        stdout: SplitParser {
            onRead: data => {
                if (data && data.trim()) {
                    batteryWidget.currentProfile = data.trim()
                }
            }
        }
        Component.onCompleted: running = true
    }

    // Power Profile setter
    Process {
        id: profileSetProc
        property string targetProfile: ""
        command: ["powerprofilesctl", "set", targetProfile]
        onRunningChanged: {
            if (!running && targetProfile !== "") {
                profileGetProc.running = true
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: {
            capacityFile.reload()
            statusFile.reload()
            adapterFile.reload()
        }
    }

    // Top bar icon content
    Text {
        id: batteryText
        anchors.verticalCenter: parent.verticalCenter
        text: `${batteryWidget.getBatteryIcon(batteryWidget.batteryLevel, batteryWidget.batteryStatus, batteryWidget.isPluggedIn)} ${batteryWidget.batteryLevel}%`
        color: (batteryWidget.batteryLevel <= 15 && batteryWidget.batteryStatus !== "Charging") ? Theme.colBatteryLow :
               (batteryWidget.batteryLevel <= 30 && batteryWidget.batteryStatus !== "Charging") ? Theme.colBatteryWarn :
               (batteryWidget.batteryStatus === "Charging" || batteryWidget.isPluggedIn) ? Theme.colBatteryCharging :
               Theme.colBattery
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
                    text: `${batteryWidget.getBatteryIcon(batteryWidget.batteryLevel, batteryWidget.batteryStatus, batteryWidget.isPluggedIn)} Battery: ${batteryWidget.batteryLevel}%`
                    color: Theme.colFg
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                    font.bold: true
                    Layout.fillWidth: true
                }

                Text {
                    text: batteryWidget.batteryStatus === "Charging" ? "Charging" :
                          (batteryWidget.batteryStatus === "Full" ? (batteryWidget.isPluggedIn ? "Plugged In (Full)" : "Full") :
                          (batteryWidget.isPluggedIn ? "Plugged In" : "Discharging"))
                    color: batteryWidget.isPluggedIn ? Theme.colGreen : Theme.colMuted
                    font.pixelSize: Theme.fontSize - 2
                    font.family: Theme.fontFamily
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.colDivider
            }

            // Power Profile Header
            Text {
                text: "Power Profile"
                color: Theme.colMuted
                font.pixelSize: 11
                font.family: Theme.fontFamily
                font.bold: true
            }

            // Profile list
            Repeater {
                model: batteryWidget.availableProfiles

                Rectangle {
                    width: parent.width
                    height: 30
                    radius: Theme.itemRadius
                    color: modelData === batteryWidget.currentProfile ? Theme.colSelected :
                           (profileMouse.containsMouse ? Theme.colSurface : "transparent")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            text: batteryWidget.getProfileIcon(modelData)
                            color: batteryWidget.getProfileColor(modelData)
                            font.pixelSize: Theme.fontSize
                            font.family: Theme.fontFamily
                        }

                        Text {
                            text: modelData.charAt(0).toUpperCase() + modelData.slice(1).replace("-", " ")
                            color: modelData === batteryWidget.currentProfile ? batteryWidget.getProfileColor(modelData) : Theme.colFg
                            font.pixelSize: Theme.fontSize - 1
                            font.family: Theme.fontFamily
                            font.bold: modelData === batteryWidget.currentProfile
                            Layout.fillWidth: true
                        }

                        Text {
                            text: modelData === batteryWidget.currentProfile ? "󰄬" : ""
                            color: batteryWidget.getProfileColor(modelData)
                            font.pixelSize: Theme.fontSize
                            font.family: Theme.fontFamily
                        }
                    }

                    MouseArea {
                        id: profileMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData !== batteryWidget.currentProfile) {
                                batteryWidget.currentProfile = modelData
                                profileSetProc.targetProfile = modelData
                                profileSetProc.running = true
                            }
                            batteryWidget.dropdownOpen = false
                        }
                    }
                }
            }
        }
    }
}
