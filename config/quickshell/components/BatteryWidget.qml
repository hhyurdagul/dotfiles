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
    popupXOffset: 200

    property int batteryLevel: 95
    property string batteryStatus: "Discharging"
    property bool isPluggedIn: false
    property string currentProfile: "balanced"
    property var availableProfiles: ["performance", "balanced", "power-saver"]

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

    // Battery percentage and status JSON process
    Process {
        id: batteryProc
        command: ["sh", "-c", "cap=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1 || echo 100); st=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1 || echo Full); ac=$(cat /sys/class/power_supply/A*/online /sys/class/power_supply/ucsi*/online 2>/dev/null | grep -q 1 && echo 1 || echo 0); echo \"{\\\"cap\\\": $cap, \\\"status\\\": \\\"$st\\\", \\\"ac\\\": $ac}\""]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                try {
                    var obj = JSON.parse(data.trim())
                    batteryWidget.batteryLevel = parseInt(obj.cap) || 0
                    batteryWidget.batteryStatus = obj.status || "Discharging"
                    batteryWidget.isPluggedIn = (obj.ac === 1 || obj.status === "Charging")
                } catch(e) {}
            }
        }
        Component.onCompleted: running = true
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
        command: ["sh", "-c", "powerprofilesctl set " + targetProfile]
        onRunningChanged: {
            if (!running && targetProfile !== "") {
                profileGetProc.running = true
            }
        }
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        onTriggered: {
            batteryProc.running = true
            profileGetProc.running = true
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
                color: Qt.rgba(255, 255, 255, 0.08)
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
                    radius: 6
                    color: modelData === batteryWidget.currentProfile ? Qt.rgba(255, 255, 255, 0.12) :
                           (profileMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.06) : "transparent")

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
