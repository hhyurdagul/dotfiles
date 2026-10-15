import QtQuick
import QtQuick.Layouts
import ".."

RowLayout {
    id: windowInfo
    spacing: 0

    property string activeWindow: Compositor.activeWindowTitle

    Text {
        text: activeWindow
        textFormat: Text.PlainText
        color: Theme.colWindow
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
        font.bold: true
        Layout.leftMargin: 8
        Layout.maximumWidth: 300
        elide: Text.ElideRight
        maximumLineCount: 1
        visible: activeWindow.length > 0
    }
}
