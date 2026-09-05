import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."

Item {
    id: root
    Layout.preferredWidth: iconContainer.width
    Layout.preferredHeight: parent.height

    required property var barWindow
    property int popupWidth: 200
    property int popupHeight: 150
    property bool dropdownOpen: false
    property string stemAlignment: "center"  // "left", "center", or "right"
    property alias popupContent: popupLoader.sourceComponent

    signal opened()
    signal wheelScrolled(var wheel)

    default property alias iconContent: iconContainer.data

    Connections {
        target: barWindow
        function onCloseAllPopups() {
            dropdownOpen = false
        }
    }

    Row {
        id: iconContainer
        anchors.centerIn: parent
        height: parent.height
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            dropdownOpen = !dropdownOpen
            if (dropdownOpen) {
                root.opened()
            }
        }
        onWheel: wheel => {
            root.wheelScrolled(wheel)
        }
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [popup]
        active: dropdownOpen
        onCleared: dropdownOpen = false
    }

    PopupWindow {
        id: popup
        visible: dropdownOpen
        anchor.window: barWindow
        anchor.item: root
        anchor.edges: Edges.Bottom
        anchor.gravity: root.stemAlignment === "right" ? (Edges.Bottom | Edges.Left) :
                        (root.stemAlignment === "left" ? (Edges.Bottom | Edges.Right) : Edges.Bottom)
        implicitWidth: popupWidth
        implicitHeight: popupHeight + Theme.popupTopMargin
        color: "transparent"

        // Floating rounded card with top margin from bar
        Rectangle {
            id: cardRect
            anchors.fill: parent
            anchors.topMargin: Theme.popupTopMargin
            color: Theme.colBg
            radius: Theme.cardRadius
            border.color: Theme.cardBorderColor
            border.width: Theme.cardBorderWidth
        }

        MouseArea {
            anchors.fill: parent
        }

        Loader {
            id: popupLoader
            anchors.fill: cardRect
            anchors.margins: Theme.popupPadding
        }

        onVisibleChanged: {
            if (!visible) {
                dropdownOpen = false
            }
        }
    }
}
