import QtQuick
import ".."

Text {
    id: clockText
    text: " " + Qt.formatDateTime(new Date(), "hh:mm")
    color: Theme.colClock
    font.pixelSize: Theme.fontSize
    font.family: Theme.fontFamily
    font.bold: true

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clockText.text = " " + Qt.formatDateTime(new Date(), "hh:mm")
    }
}
