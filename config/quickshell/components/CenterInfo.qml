import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import ".."

Item {
    id: centerInfo
    implicitWidth: centerText.implicitWidth
    implicitHeight: parent.height

    required property var barWindow

    property string centerDate: Qt.formatDateTime(new Date(), "ddd, MMM d")
    property string weatherText: ""
    property string weatherIcon: ""
    property string weatherCondition: ""
    property string weatherLocation: ""
    property string weatherFeelsLike: ""
    property string weatherMinTemp: ""
    property string weatherMaxTemp: ""
    property string weatherWind: ""
    property string weatherHumidity: ""
    property string weatherVisibility: ""
    property string weatherAqi: ""
    property var hourlyRain: []

    property bool popupVisible: false
    property bool dndEnabled: false

    // Native Quickshell notification server. DND drops incoming notifications
    // instead of handing notification policy to an external daemon.
    NotificationServer {
        id: notificationServer
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: notification => {
            notification.tracked = !centerInfo.dndEnabled
        }
    }

    // Get color based on temperature (Celsius)
    function getTempColor(tempStr) {
        var match = tempStr.match(/-?\d+/)
        if (!match) return Theme.colFg
        var temp = parseInt(match[0])
        if (temp <= 0) return "#8be9fd"      // Freezing - cyan
        if (temp <= 10) return "#6db3f2"     // Cold - light blue
        if (temp <= 18) return "#50fa7b"     // Cool - green
        if (temp <= 25) return "#f1fa8c"     // Warm - yellow
        if (temp <= 32) return "#ffb86c"     // Hot - orange
        return "#ff5555"                      // Very hot - red
    }

    // Get color based on weather condition
    function getConditionColor(condition) {
        var cond = condition.toLowerCase()
        if (cond.includes("sun") || cond.includes("clear")) return "#f1fa8c"  // Yellow
        if (cond.includes("cloud") || cond.includes("overcast")) return "#94a3b8"  // Gray
        if (cond.includes("rain") || cond.includes("drizzle") || cond.includes("shower")) return "#8be9fd"  // Cyan
        if (cond.includes("thunder") || cond.includes("storm")) return "#bd93f9"  // Purple
        if (cond.includes("snow") || cond.includes("sleet") || cond.includes("ice")) return "#f8f8f2"  // White
        if (cond.includes("fog") || cond.includes("mist") || cond.includes("haze")) return "#6272a4"  // Muted blue
        if (cond.includes("wind")) return "#50fa7b"  // Green
        return Theme.colFg
    }

    // Parse weather JSON and update properties
    function parseWeatherJson(output) {
        try {
            var json = JSON.parse(output)
            centerInfo.weatherText = json.text || ""
            centerInfo.weatherCondition = json.alt || ""

            // Helper to strip HTML tags
            function stripHtml(str) {
                return str.replace(/<[^>]*>/g, '').trim()
            }

            // Parse tooltip for detailed data
            if (json.tooltip) {
                var tooltip = json.tooltip
                // Extract location (first line, inside <b> tags)
                var locMatch = tooltip.match(/<b>([^<]+)<\/b>/)
                if (locMatch) centerInfo.weatherLocation = stripHtml(locMatch[1])

                // Extract feels like
                var feelsMatch = tooltip.match(/Feels like ([^<\n]+)/)
                if (feelsMatch) centerInfo.weatherFeelsLike = stripHtml(feelsMatch[1])

                // Extract icon (big text after condition)
                var iconMatch = tooltip.match(/<big>([^<]+)<\/big>/)
                if (iconMatch) centerInfo.weatherIcon = stripHtml(iconMatch[1])

                // Extract min/max temps (line with two temps)
                var tempMatch = tooltip.match(/([^\t]+)\t\t([^\n<]+)/)
                if (tempMatch) {
                    // Look for the line with min/max
                    var lines = tooltip.split('\n')
                    for (var i = 0; i < lines.length; i++) {
                        var line = lines[i]
                        // Match pattern like "  1°		  3°"
                        var minMaxMatch = line.match(/\s*([^\t]+)\t\t\s*([^\t\n]+)/)
                        if (minMaxMatch && minMaxMatch[1].includes('°') && minMaxMatch[2].includes('°')) {
                            centerInfo.weatherMinTemp = stripHtml(minMaxMatch[1])
                            centerInfo.weatherMaxTemp = stripHtml(minMaxMatch[2])
                        }
                        // Wind and humidity line
                        if (line.includes('km/h') && line.includes('%')) {
                            var parts = line.split('\t').filter(p => p.trim())
                            if (parts.length >= 2) {
                                centerInfo.weatherWind = parts[0].trim()
                                centerInfo.weatherHumidity = parts[1].trim()
                            }
                        }
                        // Visibility and AQI
                        if (line.includes('km') && line.includes('AQI')) {
                            var visParts = line.split('\t').filter(p => p.trim())
                            if (visParts.length >= 2) {
                                centerInfo.weatherVisibility = visParts[0].trim()
                                var aqiMatch = line.match(/AQI\s*(\d+)/)
                                if (aqiMatch) centerInfo.weatherAqi = aqiMatch[1]
                            }
                        }
                    }
                }

                // Extract hourly rain chances
                var rainMatch = tooltip.match(/Rain drop (\d+)%/g)
                if (rainMatch) {
                    var rainArr = []
                    for (var j = 0; j < rainMatch.length && j < 5; j++) {
                        var pct = rainMatch[j].match(/(\d+)/)
                        if (pct) rainArr.push(parseInt(pct[1]))
                    }
                    centerInfo.hourlyRain = rainArr
                }
            }
            return true
        } catch (e) {
            return false
        }
    }

    Row {
        id: centerText
        anchors.centerIn: parent
        spacing: 0

        // Weather text parts extracted from weatherText (format: "icon temp° location")
        property string barIcon: {
            if (!weatherText) return ""
            var match = weatherText.match(/^(\S+)\s/)
            return match ? match[1] : ""
        }
        property string barTemp: {
            if (!weatherText) return ""
            var match = weatherText.match(/-?\d+°/)
            return match ? match[0] : ""
        }
        property string barLocation: {
            if (!weatherText) return ""
            var match = weatherText.match(/-?\d+°\s*(.+)$/)
            return match ? match[1] : ""
        }

        // DND toggle
        Text {
            text: dndEnabled ? "󰂛  " : "󰂚  "
            color: dndEnabled ? "#ff5555" : Theme.colMuted
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: centerInfo.dndEnabled = !centerInfo.dndEnabled
            }
        }

        Text {
            text: centerDate
            color: Theme.colFg
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
        }

        // Separator with spacing
        Text {
            visible: weatherText !== ""
            text: " |"
            color: Theme.colMuted
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            anchors.verticalCenter: parent.verticalCenter
        }

        // Weather pill with matching background (only when open)
        Rectangle {
            id: weatherPill
            visible: weatherText !== ""
            color: popupVisible ? Theme.colBg : "transparent"
            radius: 8
            height: 26
            width: weatherRow.implicitWidth + 16
            anchors.verticalCenter: parent.verticalCenter

            Row {
                id: weatherRow
                anchors.centerIn: parent
                spacing: 0

                Text {
                    visible: centerText.barIcon !== ""
                    text: centerText.barIcon + " "
                    color: getTempColor(weatherText)
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    visible: centerText.barTemp !== ""
                    text: centerText.barTemp
                    color: getTempColor(weatherText)
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    visible: centerText.barLocation !== ""
                    text: " " + centerText.barLocation
                    color: Theme.colFg
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    // Weather process - fetch full JSON
    Process {
        id: weatherProc
        property string output: ""
        command: ["sh", "-c", "$HOME/.config/quickshell/scripts/weather.py 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => {
                if (data) weatherProc.output += data
            }
        }
        onRunningChanged: {
            if (running) {
                output = ""
            } else if (output) {
                if (parseWeatherJson(output)) {
                    // Save to cache on successful fetch
                    saveWeatherCache(output)
                }
            }
            // If no output (offline), cached data remains displayed
        }
        Component.onCompleted: {
            // First load from cache, then fetch fresh data
            cacheReadProc.running = true
        }
    }

    // Function to save weather cache
    function saveWeatherCache(data) {
        // Escape single quotes in JSON for shell
        var escaped = data.replace(/'/g, "'\\''")
        cacheWriteProc.command = ["sh", "-c", "mkdir -p ~/.cache/quickshell && printf '%s' '" + escaped + "' > ~/.cache/quickshell/weather.json"]
        cacheWriteProc.running = true
    }

    // Cache write process
    Process {
        id: cacheWriteProc
    }

    // Cache read process
    Process {
        id: cacheReadProc
        property string output: ""
        command: ["sh", "-c", "cat ~/.cache/quickshell/weather.json 2>/dev/null || true"]
        stdout: SplitParser {
            onRead: data => {
                if (data) cacheReadProc.output += data
            }
        }
        onRunningChanged: {
            if (running) {
                output = ""
            } else {
                // Load cached data first
                if (output) {
                    parseWeatherJson(output)
                }
                // Then try to fetch fresh data
                weatherProc.running = true
            }
        }
    }

    // Date update timer
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: centerDate = Qt.formatDateTime(new Date(), "ddd, MMM d")
    }

    // Weather timer (hourly updates)
    Timer {
        interval: 3600000
        running: true
        repeat: true
        onTriggered: {
            weatherProc.running = true
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: weatherText ? Qt.PointingHandCursor : Qt.ArrowCursor

        onClicked: {
            if (weatherText) {
                centerInfo.popupVisible = !centerInfo.popupVisible
            }
        }
    }

    HyprlandFocusGrab {
        id: weatherFocusGrab
        windows: [weatherPopup]
        active: centerInfo.popupVisible
        onCleared: centerInfo.popupVisible = false
    }

    // Weather popup
    PopupWindow {
        id: weatherPopup
        visible: centerInfo.popupVisible && centerInfo.weatherText
        anchor.window: barWindow
        anchor.rect.x: centerInfo.x + centerText.x + weatherPill.x + weatherPill.width/2 - width/2
        anchor.rect.y: 32
        implicitWidth: 280
        implicitHeight: contentColumn.implicitHeight + 12 + 32
        color: "transparent"

        // Main card with notch corners
        Canvas {
            id: cardRect
            anchors.fill: parent

            property int stemWidth: weatherPill.width  // match weather widget width
            property int stemHeight: 12     // height of narrow top section
            property int notchRadius: 10    // radius of the concave notch curves
            property int cardRadius: 12     // radius of main card corners

            onPaint: {
                var ctx = getContext("2d")
                ctx.fillStyle = Theme.colBg

                var sw = stemWidth
                var sh = stemHeight
                var nr = notchRadius
                var r = cardRadius
                var w = width
                var h = height
                var cx = w / 2

                // Calculate stem edges
                var stemLeft = cx - sw/2
                var stemRight = cx + sw/2

                ctx.beginPath()
                // Start at top-left of stem
                ctx.moveTo(stemLeft + r, 0)
                // Top edge of stem
                ctx.lineTo(stemRight - r, 0)
                // Top-right corner of stem
                ctx.arcTo(stemRight, 0, stemRight, r, r)
                // Right edge of stem down
                ctx.lineTo(stemRight, sh - nr)
                // Notch curve (concave) - right side
                ctx.arcTo(stemRight, sh, stemRight + nr, sh, nr)
                // Top edge to right card corner
                ctx.lineTo(w - r, sh)
                // Top-right corner of card
                ctx.arcTo(w, sh, w, sh + r, r)
                // Right edge of card
                ctx.lineTo(w, h - r)
                // Bottom-right corner
                ctx.arcTo(w, h, w - r, h, r)
                // Bottom edge
                ctx.lineTo(r, h)
                // Bottom-left corner
                ctx.arcTo(0, h, 0, h - r, r)
                // Left edge of card
                ctx.lineTo(0, sh + r)
                // Top-left corner of card
                ctx.arcTo(0, sh, r, sh, r)
                // Top edge to left notch
                ctx.lineTo(stemLeft - nr, sh)
                // Notch curve (concave) - left side
                ctx.arcTo(stemLeft, sh, stemLeft, sh - nr, nr)
                // Left edge of stem up
                ctx.lineTo(stemLeft, r)
                // Top-left corner of stem
                ctx.arcTo(stemLeft, 0, stemLeft + r, 0, r)
                ctx.closePath()
                ctx.fill()
            }
        }

        MouseArea {
            id: popupMouse
            anchors.fill: parent
        }

        Column {
            id: contentColumn
            anchors.fill: cardRect
            anchors.topMargin: cardRect.stemHeight + 16
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.bottomMargin: 16
            spacing: 8

            // Large icon centered
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: centerInfo.weatherIcon || "󰖐"
                color: getConditionColor(centerInfo.weatherCondition)
                font.pixelSize: 56
                font.family: Theme.fontFamily
            }

            // Temperature large
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                property string temp: {
                    var match = centerInfo.weatherText.match(/-?\d+/)
                    return match ? match[0] + "°C" : ""
                }
                text: temp
                color: getTempColor(centerInfo.weatherText)
                font.pixelSize: 32
                font.family: Theme.fontFamily
                font.bold: true
            }

            // Condition
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: centerInfo.weatherCondition
                color: Theme.colMuted
                font.pixelSize: Theme.fontSize
                font.family: Theme.fontFamily
            }

            // Location
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: centerInfo.weatherLocation || ""
                color: Qt.rgba(Theme.colMuted.r, Theme.colMuted.g, Theme.colMuted.b, 0.6)
                font.pixelSize: Theme.fontSize - 2
                font.family: Theme.fontFamily
                elide: Text.ElideRight
                visible: centerInfo.weatherLocation !== ""
            }

            // Spacer
            Item { width: 1; height: 4 }

            // Min/Max row
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16
                visible: centerInfo.weatherMinTemp !== "" || centerInfo.weatherMaxTemp !== ""

                Text {
                    text: " " + centerInfo.weatherMinTemp
                    color: getTempColor(centerInfo.weatherMinTemp)
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                }
                Text {
                    text: " " + centerInfo.weatherMaxTemp
                    color: getTempColor(centerInfo.weatherMaxTemp)
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                }
            }

            // Feels like
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: centerInfo.weatherFeelsLike ? "Feels " + centerInfo.weatherFeelsLike : ""
                color: Theme.colMuted
                font.pixelSize: Theme.fontSize - 2
                font.family: Theme.fontFamily
                visible: centerInfo.weatherFeelsLike !== ""
            }

            // Hourly rain forecast
            Column {
                width: parent.width
                spacing: 6
                visible: centerInfo.hourlyRain.length > 0

                // Spacer
                Item { width: 1; height: 4 }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: " Rain"
                    color: Theme.colMuted
                    font.pixelSize: Theme.fontSize - 2
                    font.family: Theme.fontFamily
                }

                RowLayout {
                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: centerInfo.hourlyRain

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28
                            color: Qt.rgba(Theme.colNetwork.r, Theme.colNetwork.g, Theme.colNetwork.b, 0.15)
                            radius: 4

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: parent.height * (modelData / 100)
                                color: Qt.rgba(Theme.colNetwork.r, Theme.colNetwork.g, Theme.colNetwork.b, 0.4 + (modelData / 200))
                                radius: 4
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modelData + "%"
                                color: Theme.colFg
                                font.pixelSize: 9
                                font.family: Theme.fontFamily
                                font.bold: true
                            }
                        }
                    }
                }
            }
        }
    }
}
