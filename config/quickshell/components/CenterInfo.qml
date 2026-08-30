import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import ".."

Item {
    id: centerInfo
    implicitWidth: centerText.implicitWidth + 8
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

    property bool notifVisible: false
    property bool calendarVisible: false
    property bool weatherVisible: false

    // Calendar state (current viewing year & month)
    property var displayDate: new Date()
    property int currentViewYear: displayDate.getFullYear()
    property int currentViewMonth: displayDate.getMonth() // 0-11

    function nextMonth() {
        var d = new Date(currentViewYear, currentViewMonth + 1, 1)
        currentViewYear = d.getFullYear()
        currentViewMonth = d.getMonth()
    }

    function prevMonth() {
        var d = new Date(currentViewYear, currentViewMonth - 1, 1)
        currentViewYear = d.getFullYear()
        currentViewMonth = d.getMonth()
    }

    function resetToToday() {
        var today = new Date()
        currentViewYear = today.getFullYear()
        currentViewMonth = today.getMonth()
    }

    function getMonthName(monthIndex) {
        var months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
        return months[monthIndex] || ""
    }

    function getCalendarDays(year, month) {
        var firstDay = new Date(year, month, 1)
        var lastDay = new Date(year, month + 1, 0)
        var prevMonthLastDay = new Date(year, month, 0)

        // Monday-first: 0 = Mon, ..., 6 = Sun
        var startDay = (firstDay.getDay() + 6) % 7
        var totalDays = lastDay.getDate()
        var prevTotalDays = prevMonthLastDay.getDate()

        var days = []
        var today = new Date()

        // Prev month days
        for (var i = startDay - 1; i >= 0; i--) {
            days.push({
                day: prevTotalDays - i,
                isCurrentMonth: false,
                isToday: false
            })
        }

        // Current month days
        for (var d = 1; d <= totalDays; d++) {
            var isToday = (today.getFullYear() === year && today.getMonth() === month && today.getDate() === d)
            days.push({
                day: d,
                isCurrentMonth: true,
                isToday: isToday
            })
        }

        // Next month padding to fill 42 cells (6 full weeks)
        var remaining = 42 - days.length
        for (var n = 1; n <= remaining; n++) {
            days.push({
                day: n,
                isCurrentMonth: false,
                isToday: false
            })
        }
        return days
    }

    Connections {
        target: barWindow
        function onCloseAllPopups() {
            notifVisible = false
            weatherVisible = false
            calendarVisible = false
        }
    }

    // Get color based on temperature (Celsius)
    function getTempColor(tempStr) {
        var match = tempStr.match(/-?\d+/)
        if (!match) return Theme.colFg
        var temp = parseInt(match[0])
        if (temp <= 0) return "#8be9fd"
        if (temp <= 10) return "#6db3f2"
        if (temp <= 18) return "#50fa7b"
        if (temp <= 25) return "#f1fa8c"
        if (temp <= 32) return "#ffb86c"
        return "#ff5555"
    }

    // Get color based on weather condition
    function getConditionColor(condition) {
        var cond = condition.toLowerCase()
        if (cond.includes("sun") || cond.includes("clear")) return "#f1fa8c"
        if (cond.includes("cloud") || cond.includes("overcast")) return "#94a3b8"
        if (cond.includes("rain") || cond.includes("drizzle") || cond.includes("shower")) return "#8be9fd"
        if (cond.includes("thunder") || cond.includes("storm")) return "#bd93f9"
        if (cond.includes("snow") || cond.includes("sleet") || cond.includes("ice")) return "#f8f8f2"
        if (cond.includes("fog") || cond.includes("mist") || cond.includes("haze")) return "#6272a4"
        if (cond.includes("wind")) return "#50fa7b"
        return Theme.colFg
    }

    // Parse weather JSON and update properties
    function parseWeatherJson(output) {
        try {
            var json = JSON.parse(output)
            centerInfo.weatherText = json.text || ""
            centerInfo.weatherCondition = json.alt || ""

            function stripHtml(str) {
                return str.replace(/<[^>]*>/g, '').trim()
            }

            if (json.tooltip) {
                var tooltip = json.tooltip
                var locMatch = tooltip.match(/<b>([^<]+)<\/b>/)
                if (locMatch) centerInfo.weatherLocation = stripHtml(locMatch[1])

                var feelsMatch = tooltip.match(/Feels like ([^<\n]+)/)
                if (feelsMatch) centerInfo.weatherFeelsLike = stripHtml(feelsMatch[1])

                var iconMatch = tooltip.match(/<big>([^<]+)<\/big>/)
                if (iconMatch) centerInfo.weatherIcon = stripHtml(iconMatch[1])

                var tempMatch = tooltip.match(/([^\t]+)\t\t([^\n<]+)/)
                if (tempMatch) {
                    var lines = tooltip.split('\n')
                    for (var i = 0; i < lines.length; i++) {
                        var line = lines[i]
                        var minMaxMatch = line.match(/\s*([^\t]+)\t\t\s*([^\t\n]+)/)
                        if (minMaxMatch && minMaxMatch[1].includes('°') && minMaxMatch[2].includes('°')) {
                            centerInfo.weatherMinTemp = stripHtml(minMaxMatch[1])
                            centerInfo.weatherMaxTemp = stripHtml(minMaxMatch[2])
                        }
                        if (line.includes('km/h') && line.includes('%')) {
                            var parts = line.split('\t').filter(p => p.trim())
                            if (parts.length >= 2) {
                                centerInfo.weatherWind = parts[0].trim()
                                centerInfo.weatherHumidity = parts[1].trim()
                            }
                        }
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
        spacing: 4

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

        // Notification Bell Pill (Left-click: notification popup, Right-click: toggle DND)
        Rectangle {
            id: notifPill
            color: notifVisible ? Qt.rgba(255, 255, 255, 0.1) : "transparent"
            radius: 6
            height: 24
            width: bellRow.implicitWidth + 12
            anchors.verticalCenter: parent.verticalCenter

            Row {
                id: bellRow
                anchors.centerIn: parent
                spacing: 3

                Text {
                    text: NotifManager.dndEnabled ? "󰂛" : (NotifManager.history.length > 0 ? "󰂞" : "󰂚")
                    color: NotifManager.dndEnabled ? "#ff5555" :
                           (NotifManager.history.length > 0 ? "#f9e2af" :
                           (notifMouse.containsMouse ? Theme.colFg : Theme.colMuted))
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    visible: NotifManager.history.length > 0 && !NotifManager.dndEnabled
                    text: `${NotifManager.history.length}`
                    color: "#f9e2af"
                    font.pixelSize: Theme.fontSize - 3
                    font.family: Theme.fontFamily
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: notifMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        NotifManager.toggleDnd()
                    } else {
                        centerInfo.notifVisible = !centerInfo.notifVisible
                        centerInfo.calendarVisible = false
                        centerInfo.weatherVisible = false
                    }
                }
            }
        }

        // Clickable Date Pill (opens Calendar view)
        Rectangle {
            id: datePill
            color: calendarVisible ? Qt.rgba(255, 255, 255, 0.1) : "transparent"
            radius: 6
            height: 24
            width: dateTextItem.implicitWidth + 12
            anchors.verticalCenter: parent.verticalCenter

            Text {
                id: dateTextItem
                anchors.centerIn: parent
                text: centerDate
                color: dateMouse.containsMouse ? Theme.colNetwork : Theme.colFg
                font.pixelSize: Theme.fontSize
                font.family: Theme.fontFamily
                font.bold: true
            }

            MouseArea {
                id: dateMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    centerInfo.resetToToday()
                    centerInfo.calendarVisible = !centerInfo.calendarVisible
                    centerInfo.notifVisible = false
                    centerInfo.weatherVisible = false
                }
            }
        }

        // Separator
        Text {
            visible: weatherText !== ""
            text: "|"
            color: Theme.colMuted
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            anchors.verticalCenter: parent.verticalCenter
        }

        // Weather pill (opens Weather view)
        Rectangle {
            id: weatherPill
            visible: weatherText !== ""
            color: weatherVisible ? Qt.rgba(255, 255, 255, 0.1) : "transparent"
            radius: 6
            height: 24
            width: weatherRow.implicitWidth + 12
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

            MouseArea {
                id: weatherMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    centerInfo.weatherVisible = !centerInfo.weatherVisible
                    centerInfo.calendarVisible = false
                    centerInfo.notifVisible = false
                }
            }
        }
    }

    // Weather process
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
                    saveWeatherCache(output)
                }
            }
        }
        Component.onCompleted: cacheReadProc.running = true
    }

    function saveWeatherCache(data) {
        var escaped = data.replace(/'/g, "'\\''")
        cacheWriteProc.command = ["sh", "-c", "mkdir -p ~/.cache/quickshell && printf '%s' '" + escaped + "' > ~/.cache/quickshell/weather.json"]
        cacheWriteProc.running = true
    }

    Process { id: cacheWriteProc }

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
                if (output) parseWeatherJson(output)
                weatherProc.running = true
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: centerDate = Qt.formatDateTime(new Date(), "ddd, MMM d")
    }

    Timer {
        interval: 3600000
        running: true
        repeat: true
        onTriggered: weatherProc.running = true
    }

    HyprlandFocusGrab {
        id: popupFocusGrab
        windows: [notifPopup, calendarPopup, weatherPopup]
        active: centerInfo.notifVisible || centerInfo.calendarVisible || centerInfo.weatherVisible
        onCleared: {
            centerInfo.notifVisible = false
            centerInfo.calendarVisible = false
            centerInfo.weatherVisible = false
        }
    }

    // ==========================================
    // NATIVE NOTIFICATION DROPDOWN POPUP
    // ==========================================
    PopupWindow {
        id: notifPopup
        visible: centerInfo.notifVisible
        anchor.window: barWindow
        anchor.item: notifPill
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        implicitWidth: 300
        implicitHeight: Math.min(Math.max(NotifManager.history.length * 68 + 60, 140), 360) + Theme.popupTopMargin
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: Theme.popupTopMargin
            color: Theme.colBg
            radius: Theme.cardRadius
            border.color: Theme.cardBorderColor
            border.width: Theme.cardBorderWidth

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                // Header
                RowLayout {
                    width: parent.width

                    Text {
                        text: "󰂚 Notifications"
                        color: Theme.colFg
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    // DND Toggle Button
                    Rectangle {
                        width: 26
                        height: 26
                        radius: 5
                        color: dndBtnMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : (NotifManager.dndEnabled ? Qt.rgba(255/255, 85/255, 85/255, 0.2) : Qt.rgba(255, 255, 255, 0.05))

                        Text {
                            anchors.centerIn: parent
                            text: NotifManager.dndEnabled ? "󰂛" : "󰂚"
                            color: NotifManager.dndEnabled ? "#ff5555" : Theme.colFg
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: dndBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NotifManager.toggleDnd()
                        }
                    }

                    // Clear All Button
                    Rectangle {
                        visible: NotifManager.history.length > 0
                        width: 26
                        height: 26
                        radius: 5
                        color: clearBtnMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.05)

                        Text {
                            anchors.centerIn: parent
                            text: "󰃢"
                            color: Theme.colFg
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: clearBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NotifManager.clearHistory()
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.rgba(255, 255, 255, 0.08)
                }

                // Empty state
                Item {
                    visible: NotifManager.history.length === 0
                    width: parent.width
                    height: parent.height - 45

                    Column {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "󰂚"
                            color: Theme.colMuted
                            font.pixelSize: 28
                            font.family: Theme.fontFamily
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "No new notifications"
                            color: Theme.colMuted
                            font.pixelSize: Theme.fontSize - 1
                            font.family: Theme.fontFamily
                        }
                    }
                }

                // Notification list
                ListView {
                    visible: NotifManager.history.length > 0
                    id: notifListView
                    width: parent.width
                    height: parent.height - 45
                    clip: true
                    model: NotifManager.history
                    spacing: 6

                    delegate: Rectangle {
                        width: notifListView.width
                        height: Math.max(notifCol.implicitHeight + 12, 54)
                        radius: 8
                        color: notifItemMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(255, 255, 255, 0.04)

                        Column {
                            id: notifCol
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 3

                            RowLayout {
                                width: parent.width

                                Text {
                                    text: modelData.app
                                    color: Theme.colNetwork
                                    font.pixelSize: 10
                                    font.family: Theme.fontFamily
                                    font.bold: true
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: modelData.time
                                    color: Theme.colMuted
                                    font.pixelSize: 9
                                    font.family: Theme.fontFamily
                                }

                                Text {
                                    text: "✕"
                                    color: closeMouse.containsMouse ? "#ff5555" : Theme.colMuted
                                    font.pixelSize: 10
                                    MouseArea {
                                        id: closeMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: NotifManager.dismissFromHistory(index)
                                    }
                                }
                            }

                            Text {
                                text: modelData.summary
                                color: Theme.colFg
                                font.pixelSize: Theme.fontSize - 1
                                font.family: Theme.fontFamily
                                font.bold: true
                                width: parent.width
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: modelData.body !== ""
                                text: modelData.body
                                color: Theme.colMuted
                                font.pixelSize: Theme.fontSize - 2
                                font.family: Theme.fontFamily
                                width: parent.width
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: notifItemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }
                }
            }
        }
    }

    // ==========================================
    // CALENDAR VIEW POPUP
    // ==========================================
    PopupWindow {
        id: calendarPopup
        visible: centerInfo.calendarVisible
        anchor.window: barWindow
        anchor.item: datePill
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        implicitWidth: 280
        implicitHeight: 310 + Theme.popupTopMargin
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: Theme.popupTopMargin
            color: Theme.colBg
            radius: Theme.cardRadius
            border.color: Theme.cardBorderColor
            border.width: Theme.cardBorderWidth

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                // Header with Month/Year and navigation
                RowLayout {
                    width: parent.width

                    // Previous Month Button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 6
                        color: prevMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.05)

                        Text {
                            anchors.centerIn: parent
                            text: "❮"
                            color: Theme.colFg
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: prevMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: centerInfo.prevMonth()
                        }
                    }

                    // Month & Year Label
                    Text {
                        text: centerInfo.getMonthName(centerInfo.currentViewMonth) + " " + centerInfo.currentViewYear
                        color: Theme.colFg
                        font.pixelSize: Theme.fontSize + 1
                        font.family: Theme.fontFamily
                        font.bold: true
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    // Today / Reset Button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 6
                        color: todayMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.05)

                        Text {
                            anchors.centerIn: parent
                            text: "󰃭"
                            color: Theme.colNetwork
                            font.pixelSize: 14
                            font.family: Theme.fontFamily
                        }

                        MouseArea {
                            id: todayMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: centerInfo.resetToToday()
                        }
                    }

                    // Next Month Button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 6
                        color: nextMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.05)

                        Text {
                            anchors.centerIn: parent
                            text: "❯"
                            color: Theme.colFg
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: nextMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: centerInfo.nextMonth()
                        }
                    }
                }

                // Days of week header
                RowLayout {
                    width: parent.width
                    spacing: 0

                    Repeater {
                        model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                        Text {
                            text: modelData
                            color: (modelData === "Sa" || modelData === "Su") ? Theme.colNetwork : Theme.colMuted
                            font.pixelSize: 11
                            font.family: Theme.fontFamily
                            font.bold: true
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.rgba(255, 255, 255, 0.08)
                }

                // Days Grid (6 rows x 7 cols)
                Grid {
                    width: parent.width
                    columns: 7
                    rowSpacing: 4
                    columnSpacing: 0

                    Repeater {
                        model: centerInfo.getCalendarDays(centerInfo.currentViewYear, centerInfo.currentViewMonth)

                        Item {
                            width: (parent.width) / 7
                            height: 28

                            Rectangle {
                                anchors.centerIn: parent
                                width: 26
                                height: 26
                                radius: 13
                                color: modelData.isToday ? Theme.colNetwork : (cellMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.1) : "transparent")

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.day
                                    color: modelData.isToday ? "#1e1e2e" :
                                           modelData.isCurrentMonth ? Theme.colFg : Theme.colMuted
                                    font.pixelSize: 11
                                    font.family: Theme.fontFamily
                                    font.bold: modelData.isToday || modelData.isCurrentMonth
                                }
                            }

                            MouseArea {
                                id: cellMouse
                                anchors.fill: parent
                                hoverEnabled: true
                            }
                        }
                    }
                }
            }
        }
    }

    // ==========================================
    // WEATHER VIEW POPUP
    // ==========================================
    PopupWindow {
        id: weatherPopup
        visible: centerInfo.weatherVisible && centerInfo.weatherText !== ""
        anchor.window: barWindow
        anchor.item: weatherPill
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        implicitWidth: 280
        implicitHeight: contentColumn.implicitHeight + 36 + Theme.popupTopMargin
        color: "transparent"

        Rectangle {
            id: weatherCard
            anchors.fill: parent
            anchors.topMargin: Theme.popupTopMargin
            color: Theme.colBg
            radius: Theme.cardRadius
            border.color: Theme.cardBorderColor
            border.width: Theme.cardBorderWidth

            Column {
                id: contentColumn
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8

                // Large icon centered
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: centerInfo.weatherIcon || "󰖐"
                    color: getConditionColor(centerInfo.weatherCondition)
                    font.pixelSize: 52
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
                    font.pixelSize: 30
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

                    Item { width: 1; height: 4 }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Rain Chance"
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
}
