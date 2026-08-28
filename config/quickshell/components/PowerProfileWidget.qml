import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

DropdownWidget {
    id: powerWidget
    popupWidth: 180
    popupHeight: 165
    popupXOffset: 200

    property string currentProfile: "balanced"
    property var availableProfiles: ["performance", "balanced", "power-saver"]

    // Profile icons (using nf-md icons)
    function getProfileIcon(profile) {
        switch(profile) {
            case "performance": return "󰓅"  // nf-md-speedometer
            case "balanced": return "󰾅"     // nf-md-scale_balance
            case "power-saver": return "󰌪"  // nf-md-leaf
            default: return "󰾅"
        }
    }

    function getProfileColor(profile) {
        switch(profile) {
            case "performance": return "#f9e2af"  // yellow
            case "balanced": return "#cdd6f4"     // white
            case "power-saver": return "#a6e3a1"  // green
            default: return Theme.colFg
        }
    }

    // Get current profile
    Process {
        id: profileGetProc
        command: ["powerprofilesctl", "get"]
        stdout: SplitParser {
            onRead: data => {
                if (data && data.trim()) {
                    powerWidget.currentProfile = data.trim()
                }
            }
        }
        Component.onCompleted: running = true
    }

    // Set profile process
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

    // Update timer
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: profileGetProc.running = true
    }

    // Icon content
    Text {
        id: powerText
        anchors.verticalCenter: parent.verticalCenter
        text: getProfileIcon(currentProfile)
        color: getProfileColor(currentProfile)
        font.pixelSize: Theme.fontSize + 2
        font.family: Theme.fontFamily
        font.bold: true
    }

    // Popup content
    popupContent: Component {
        Column {
            spacing: 6

            // Header
            Text {
                text: "󰾅 Power Profile"
                color: Theme.colFg
                font.pixelSize: Theme.fontSize
                font.family: Theme.fontFamily
                font.bold: true
                width: parent.width
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.colMuted
            }

            // Profile list
            Repeater {
                model: powerWidget.availableProfiles

                Rectangle {
                    width: parent.width
                    height: 32
                    color: profileMouseArea.containsMouse ? Qt.rgba(255, 255, 255, 0.1) : "transparent"
                    radius: 6

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 8

                        Text {
                            text: powerWidget.getProfileIcon(modelData)
                            color: powerWidget.getProfileColor(modelData)
                            font.pixelSize: Theme.fontSize
                            font.family: Theme.fontFamily
                        }

                        Text {
                            text: modelData.charAt(0).toUpperCase() + modelData.slice(1).replace("-", " ")
                            color: modelData === powerWidget.currentProfile ? powerWidget.getProfileColor(modelData) : Theme.colFg
                            font.pixelSize: Theme.fontSize - 1
                            font.family: Theme.fontFamily
                            font.bold: modelData === powerWidget.currentProfile
                            Layout.fillWidth: true
                        }

                        Text {
                            text: modelData === powerWidget.currentProfile ? "󰄬" : ""
                            color: powerWidget.getProfileColor(modelData)
                            font.pixelSize: Theme.fontSize
                            font.family: Theme.fontFamily
                        }
                    }

                    MouseArea {
                        id: profileMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData !== powerWidget.currentProfile) {
                                // Update UI immediately
                                powerWidget.currentProfile = modelData
                                // Then run the command
                                profileSetProc.targetProfile = modelData
                                profileSetProc.running = true
                            }
                            powerWidget.dropdownOpen = false
                        }
                    }
                }
            }
        }
    }
}
