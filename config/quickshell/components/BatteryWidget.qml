import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

Text {
    id: batteryWidget

    property int batteryLevel: 0
    property bool batteryCharging: false

    text: batteryCharging ? " " + batteryLevel + "%" :
          batteryLevel <= 10 ? "󰂎 " + batteryLevel + "%" :
          batteryLevel <= 20 ? "󰁺 " + batteryLevel + "%" :
          batteryLevel <= 30 ? "󰁻 " + batteryLevel + "%" :
          batteryLevel <= 40 ? "󰁼 " + batteryLevel + "%" :
          batteryLevel <= 50 ? "󰁽 " + batteryLevel + "%" :
          batteryLevel <= 60 ? "󰁾 " + batteryLevel + "%" :
          batteryLevel <= 70 ? "󰁿 " + batteryLevel + "%" :
          batteryLevel <= 80 ? "󰂀 " + batteryLevel + "%" :
          batteryLevel <= 90 ? "󰂁 " + batteryLevel + "%" :
          batteryLevel < 100 ? "󰂂 " + batteryLevel + "%" :
          "󰁹 " + batteryLevel + "%"
    color: batteryLevel <= 15 ? "#f53c3c" : "#32CD32"
    font.pixelSize: Theme.fontSize
    font.family: Theme.fontFamily
    font.bold: true

    // Battery level
    Process {
        id: batteryProc
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo 100"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                batteryWidget.batteryLevel = parseInt(data.trim()) || 0
            }
        }
        Component.onCompleted: running = true
    }

    // Battery charging status
    Process {
        id: batteryStatusProc
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo Full"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                batteryWidget.batteryCharging = (data.trim() === "Charging" || data.trim() === "Full")
            }
        }
        Component.onCompleted: running = true
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            batteryProc.running = true
            batteryStatusProc.running = true
        }
    }
}
