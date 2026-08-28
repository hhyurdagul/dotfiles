import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray

Item {
    id: trayWidget

    required property var barWindow

    implicitWidth: trayRow.implicitWidth
    implicitHeight: parent ? parent.height : trayRow.implicitHeight
    visible: trayRow.implicitWidth > 0

    RowLayout {
        id: trayRow
        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: SystemTray.items

            delegate: Item {
                id: trayItem

                required property var modelData

                readonly property bool shown: modelData.status !== Status.Passive

                visible: shown
                Layout.preferredWidth: shown ? 20 : 0
                Layout.preferredHeight: shown ? 20 : 0

                Image {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: trayItem.modelData.icon
                    sourceSize.width: 32
                    sourceSize.height: 32
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) {
                            if (trayItem.modelData.hasMenu) {
                                trayMenu.open()
                            } else {
                                trayItem.modelData.secondaryActivate()
                            }
                        } else if (mouse.button === Qt.MiddleButton) {
                            trayItem.modelData.secondaryActivate()
                        } else if (trayItem.modelData.onlyMenu && trayItem.modelData.hasMenu) {
                            trayMenu.open()
                        } else {
                            trayItem.modelData.activate()
                        }
                    }

                    onWheel: wheel => {
                        trayItem.modelData.scroll(wheel.angleDelta.y, false)
                    }
                }

                QsMenuAnchor {
                    id: trayMenu
                    menu: trayItem.modelData.menu
                    anchor.window: trayWidget.barWindow
                    anchor.item: trayItem
                    anchor.edges: Edges.Bottom
                    anchor.gravity: Edges.Top
                }
            }
        }
    }
}
