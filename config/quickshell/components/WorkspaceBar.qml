import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io
import ".."

RowLayout {
    id: workspaceBar
    spacing: 3

    // Window class to icon mapping
    property var windowIcons: ({
        // Browsers
        "firefox": "",
        "org.mozilla.firefox": "",
        "librewolf": "",
        "floorp": "",
        "cachy-browser": "",
        "zen": "󰰷",
        "zen-browser": "󰰷",
        "zen-alpha": "󰰷",
        "microsoft-edge": "",
        "chromium": "",
        "google-chrome": "",
        "brave-browser": "󰖟",
        "vivaldi": "",

        // Terminals
        "kitty": "󰞷",
        "konsole": "󰞷",
        "alacritty": "󰞷",
        "com.mitchellh.ghostty": "󰊠",
        "ghostty": "󰊠",
        "org.wezfurlong.wezterm": "󰞷",
        "foot": "󰞷",
        "xterm": "󰞷",
        "urxvt": "󰞷",

        // Communication
        "telegram-desktop": "󰔁",
        "org.telegram.desktop": "󰔁",
        "discord": "󰙯",
        "webcord": "󰙯",
        "vesktop": "󰙯",
        "slack": "󰒱",
        "Slack": "󰒱",
        "whatsapp": "󰖣",
        "wasistlos": "󰖣",
        "zapzap": "󰖣",
        "thunderbird": "󰇮",

        // Code editors
        "code": "󰨞",
        "code-oss": "󰨞",
        "vscodium": "󰨞",
        "codium": "󰨞",
        "dev.zed.zed": "󰵁",
        "zed": "󰵁",
        "subl": "󰅳",
        "sublime_text": "󰅳",
        "jetbrains-idea": "",
        "neovide": "",

        // Media
        "mpv": "",
        "vlc": "󰕼",
        "spotify": "",
        "cider": "󰎆",
        "celluloid": "",

        // File managers
        "thunar": "󰝰",
        "nemo": "󰝰",
        "nautilus": "󰝰",
        "dolphin": "󰝰",
        "pcmanfm": "󰝰",

        // System
        "pavucontrol": "󱡫",
        "org.pulseaudio.pavucontrol": "󱡫",
        "nwg-look": "",
        "steam": "",
        "obs": "",
        "com.obsproject.studio": "",
        "gimp": "",
        "virt-manager": "",

        // Office
        "onlyoffice-desktopeditors": "󰏆",
        "DesktopEditors": "󰏆",
        "onlyoffice": "󰏆",
        "libreoffice-writer": "",
        "libreoffice-calc": "",
        "libreoffice-startcenter": "󰏆",

        // Claude Code / AI
        "claude": "󰚩",
    })

    // Store windows per workspace
    property string ws1Icons: ""
    property string ws2Icons: ""
    property string ws3Icons: ""
    property string ws4Icons: ""
    property string ws5Icons: ""
    property string ws6Icons: ""
    property string ws7Icons: ""
    property string ws8Icons: ""
    property string ws9Icons: ""

    function getWsIcons(wsId) {
        switch(wsId) {
            case 1: return ws1Icons
            case 2: return ws2Icons
            case 3: return ws3Icons
            case 4: return ws4Icons
            case 5: return ws5Icons
            case 6: return ws6Icons
            case 7: return ws7Icons
            case 8: return ws8Icons
            case 9: return ws9Icons
            default: return ""
        }
    }

    function getWindowIcon(windowClass) {
        if (!windowClass) return ""
        if (windowIcons[windowClass]) return windowIcons[windowClass]
        var lowerClass = windowClass.toLowerCase()
        if (windowIcons[lowerClass]) return windowIcons[lowerClass]
        for (var key in windowIcons) {
            var lowerKey = key.toLowerCase()
            if (lowerClass.includes(lowerKey) || lowerKey.includes(lowerClass)) {
                return windowIcons[key]
            }
        }
        return "󰏗" // default window icon
    }

    // Process to get window list
    Process {
        id: windowsProc
        property string output: ""
        command: ["hyprctl", "clients", "-j"]
        stdout: SplitParser {
            onRead: data => {
                if (data) windowsProc.output += data + "\n"
            }
        }
        onRunningChanged: {
            if (running) {
                output = ""
            } else {
                var wsIcons = {}
                try {
                    var clients = JSON.parse(output)
                    for (var i = 0; i < clients.length; i++) {
                        var wsId = clients[i].workspace ? clients[i].workspace.id : 0
                        var windowClass = clients[i].class || clients[i].initialClass || ""
                        if (wsId > 0 && wsId <= 9) {
                            if (!wsIcons[wsId]) wsIcons[wsId] = {icons: [], seen: {}}
                            var icon = workspaceBar.getWindowIcon(windowClass)
                            if (!wsIcons[wsId].seen[icon]) {
                                wsIcons[wsId].seen[icon] = true
                                wsIcons[wsId].icons.push(icon)
                            }
                        }
                    }
                } catch (e) {
                    console.warn("Unable to parse Hyprland clients:", e)
                }
                workspaceBar.ws1Icons = wsIcons[1] ? wsIcons[1].icons.slice(0, 3).join(" ") : ""
                workspaceBar.ws2Icons = wsIcons[2] ? wsIcons[2].icons.slice(0, 3).join(" ") : ""
                workspaceBar.ws3Icons = wsIcons[3] ? wsIcons[3].icons.slice(0, 3).join(" ") : ""
                workspaceBar.ws4Icons = wsIcons[4] ? wsIcons[4].icons.slice(0, 3).join(" ") : ""
                workspaceBar.ws5Icons = wsIcons[5] ? wsIcons[5].icons.slice(0, 3).join(" ") : ""
                workspaceBar.ws6Icons = wsIcons[6] ? wsIcons[6].icons.slice(0, 3).join(" ") : ""
                workspaceBar.ws7Icons = wsIcons[7] ? wsIcons[7].icons.slice(0, 3).join(" ") : ""
                workspaceBar.ws8Icons = wsIcons[8] ? wsIcons[8].icons.slice(0, 3).join(" ") : ""
                workspaceBar.ws9Icons = wsIcons[9] ? wsIcons[9].icons.slice(0, 3).join(" ") : ""
            }
        }
        Component.onCompleted: running = true
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "openwindow" || event.name === "closewindow"
                    || event.name === "movewindow" || event.name === "workspace"
                    || event.name === "workspacev2") {
                windowsProc.running = true
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: windowsProc.running = true
    }

    property int maxWorkspaceWithWindows: {
        var max = 0
        for (var i = 0; i < Hyprland.workspaces.values.length; i++) {
            var ws = Hyprland.workspaces.values[i]
            if (ws.id > max && ws.id <= 9) max = ws.id
        }
        return max
    }

    property int activeWorkspaceId: Hyprland.focusedWorkspace?.id ?? 1
    property int workspacesToShow: Math.max(5, maxWorkspaceWithWindows, activeWorkspaceId)

    property real lastWheelTime: 0
    function switchWorkspaceByWheel(deltaY) {
        var now = Date.now()
        if (now - lastWheelTime < 220) return
        lastWheelTime = now
        if (deltaY > 0) {
            Hyprland.dispatch("hl.dsp.focus({ workspace = 'e-1' })")
        } else if (deltaY < 0) {
            Hyprland.dispatch("hl.dsp.focus({ workspace = 'e+1' })")
        }
    }

    Repeater {
        model: workspaceBar.workspacesToShow

        Rectangle {
            id: wsRect
            Layout.preferredHeight: 28
            Layout.preferredWidth: wsContent.implicitWidth + 10
            Layout.alignment: Qt.AlignVCenter
            color: isActive ? Qt.rgba(Theme.colWorkspaceActive.r, Theme.colWorkspaceActive.g, Theme.colWorkspaceActive.b, 0.15) :
                   wsMouse.containsMouse ? Theme.colSurface : "transparent"
            radius: Theme.mediumRadius
            border.width: isActive ? 1 : 0
            border.color: Qt.rgba(Theme.colWorkspaceActive.r, Theme.colWorkspaceActive.g, Theme.colWorkspaceActive.b, 0.3)

            property int wsId: index + 1
            property var workspace: Hyprland.workspaces.values.find(ws => ws.id === wsId) ?? null
            property bool isActive: workspaceBar.activeWorkspaceId === wsId
            property bool hasWindows: workspace !== null
            property string windowIconsStr: wsId === 1 ? workspaceBar.ws1Icons :
                                          wsId === 2 ? workspaceBar.ws2Icons :
                                          wsId === 3 ? workspaceBar.ws3Icons :
                                          wsId === 4 ? workspaceBar.ws4Icons :
                                          wsId === 5 ? workspaceBar.ws5Icons :
                                          wsId === 6 ? workspaceBar.ws6Icons :
                                          wsId === 7 ? workspaceBar.ws7Icons :
                                          wsId === 8 ? workspaceBar.ws8Icons :
                                          wsId === 9 ? workspaceBar.ws9Icons : ""

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            Row {
                id: wsContent
                anchors.centerIn: parent
                spacing: 4

                // Workspace number
                Text {
                    text: wsRect.wsId
                    color: wsRect.isActive ? Theme.colWorkspaceActive :
                           wsRect.hasWindows ? Theme.colFg : Theme.colMuted
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                    font.bold: wsRect.isActive
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Separator dot when there are icons
                Rectangle {
                    width: 3
                    height: 3
                    radius: height / 2
                    color: Theme.colMuted
                    visible: wsRect.windowIconsStr.length > 0
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: 0.6
                }

                // Window icons
                Text {
                    text: wsRect.windowIconsStr
                    color: wsRect.isActive ? Theme.colWorkspaceActive : Theme.colFg
                    font.pixelSize: Theme.fontSize - 1
                    font.family: Theme.fontFamily
                    visible: wsRect.windowIconsStr.length > 0
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: wsRect.isActive ? 1.0 : 0.7
                }
            }

            MouseArea {
                id: wsMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (workspaceBar.activeWorkspaceId !== wsRect.wsId) {
                        Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsRect.wsId + " })")
                    }
                }
                onWheel: wheel => {
                    workspaceBar.switchWorkspaceByWheel(wheel.angleDelta.y)
                }
            }
        }
    }
}
