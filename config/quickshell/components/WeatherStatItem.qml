import QtQuick
import QtQuick.Layouts
import ".."

RowLayout {
    id: statItem
    spacing: 6
    Layout.fillWidth: true

    property string icon: ""
    property string label: ""
    property string value: ""
    property color valueColor: Theme.colFg

    Text {
        text: icon
        color: Theme.colMuted
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
    }

    Column {
        Layout.fillWidth: true
        spacing: 0

        Text {
            text: statItem.label
            color: Qt.rgba(Theme.colMuted.r, Theme.colMuted.g, Theme.colMuted.b, 0.7)
            font.pixelSize: Theme.fontSize - 3
            font.family: Theme.fontFamily
        }

        Text {
            text: statItem.value
            color: statItem.valueColor
            font.pixelSize: Theme.fontSize - 1
            font.family: Theme.fontFamily
            font.bold: true
        }
    }
}
