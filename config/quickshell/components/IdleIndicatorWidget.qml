import QtQuick
import QtQuick.Layouts
import ".."

// Idle inhibitor button: highlighted while idle-inhibit.service keeps the
// screen from dimming, turning off, locking and suspending.
Item {
    id: idleWidget

    readonly property bool inhibited: IdleInhibitor.inhibited

    Layout.preferredWidth: 24
    Layout.preferredHeight: parent.height
    Accessible.role: Accessible.Button
    Accessible.name: inhibited ? "Idle inhibitor on: click to allow idle actions"
                               : "Idle inhibitor off: click to keep the screen awake"

    Text {
        anchors.centerIn: parent
        text: idleWidget.inhibited ? "󱫖" : "󰒲"
        color: idleWidget.inhibited ? Theme.colIdle
            : (idleMouse.containsMouse ? Theme.colBlue : Theme.colFgDim)
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
        font.bold: idleWidget.inhibited
    }

    MouseArea {
        id: idleMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: IdleInhibitor.toggle()
    }
}
