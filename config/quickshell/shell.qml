//@ pragma UseQApplication
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import "components"

ShellRoot {
    id: root

    // Top Bar across all screens
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: rootBarWindow
            property var modelData
            screen: modelData

            signal closeAllPopups

            // Listen to Hyprland events to close popups when focus changes
            Connections {
                target: Hyprland
                function onRawEvent(event) {
                    // Close popups when active window changes or layer closes
                    if (event.name === "activewindow" || event.name === "activewindowv2") {
                        rootBarWindow.closeAllPopups();
                    }
                }
            }

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 34
            color: Theme.colBg

            margins {
                top: 0
                bottom: -4
                left: 0
                right: 0
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.colBg

                // Empty bar space closes popups; controls above receive input directly.
                MouseArea {
                    anchors.fill: parent
                    propagateComposedEvents: true
                    onClicked: mouse => {
                        rootBarWindow.closeAllPopups();
                        mouse.accepted = false;
                    }
                }

                // ==========================================
                // LEFT SECTION: Workspaces & Window Title
                // ==========================================
                RowLayout {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    spacing: 0

                    WorkspaceBar {
                        Layout.preferredHeight: parent.height
                    }

                    Separator {}

                    WindowInfo {
                        Layout.preferredHeight: parent.height
                        Layout.preferredWidth: 300
                    }
                }

                // ==========================================
                // CENTER SECTION: True Screen Center!
                // ==========================================
                RowLayout {
                    anchors.centerIn: parent
                    height: parent.height
                    spacing: 6

                    CenterInfo {
                        barWindow: rootBarWindow
                        Layout.preferredHeight: parent.height
                    }

                    CameraIndicatorWidget {
                        Layout.preferredHeight: parent.height
                    }

                    IdleIndicatorWidget {
                        Layout.preferredHeight: parent.height
                    }
                }

                // ==========================================
                // RIGHT SECTION: Status, Media, Clock, Power
                // ==========================================
                RowLayout {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    spacing: 0

                    SystemTrayWidget {
                        barWindow: rootBarWindow
                    }

                    Separator {}

                    CpuWidget {
                        barWindow: rootBarWindow
                    }

                    Separator {}

                    MemoryWidget {
                        barWindow: rootBarWindow
                    }

                    Separator {}

                    VolumeWidget {
                        barWindow: rootBarWindow
                    }

                    Separator {}

                    BatteryWidget {
                        barWindow: rootBarWindow
                    }

                    Separator {}

                    WifiWidget {
                        barWindow: rootBarWindow
                    }

                    Separator {}

                    BluetoothWidget {
                        barWindow: rootBarWindow
                    }

                    Separator {}

                    Clock {}

                    Separator {}

                    PowerWidget {
                        barWindow: rootBarWindow
                    }
                }
            }
        }
    }

    // System-wide floating notification toasts
    NotificationToasts {}
    OnScreenDisplay {}
}
