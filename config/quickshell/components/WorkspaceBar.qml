import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import ".."

RowLayout {
    id: workspaceBar
    spacing: 3

    // Hyprland 0.56 uses workspace addresses instead of numeric ids.
    property var workspaceList: []
    property int activeWorkspaceId: 0

    function workspaceId(workspace) {
        if (!workspace) return 0
        var value = workspace.id ?? workspace.address
        return /^\d+$/.test(String(value)) ? Number(value) : 0
    }

    function focusWorkspace(workspace) {
        Quickshell.execDetached(["hyprctl", "eval",
            "hl.dispatch(hl.dsp.focus({ workspace = " + JSON.stringify(String(workspace)) + " }))"])
    }

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

    // Icons are indexed by workspace, including workspace 10 (Super+0).
    property var workspaceIcons: ({})

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
        command: ["sh", "-c", "hyprctl -j --batch 'activeworkspace;workspaces;clients' | jq -sc '{active: .[0], workspaces: .[1], clients: .[2]}'"]
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
                    var state = JSON.parse(output)
                    if (!state.active || !Array.isArray(state.workspaces) || !Array.isArray(state.clients)) return
                    workspaceBar.activeWorkspaceId = workspaceBar.workspaceId(state.active)
                    workspaceBar.workspaceList = state.workspaces
                    var clients = state.clients
                    for (var i = 0; i < clients.length; i++) {
                        var wsId = workspaceBar.workspaceId(clients[i].workspace)
                        var windowClass = clients[i].class || clients[i].initialClass || ""
                        if (wsId > 0 && wsId <= 10) {
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
                var icons = {}
                for (var id in wsIcons) icons[id] = wsIcons[id].icons.slice(0, 3).join(" ")
                workspaceBar.workspaceIcons = icons
            }
        }
        Component.onCompleted: running = true
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "openwindow" || event.name === "closewindow"
                    || event.name === "movewindow" || event.name === "workspace"
                    || event.name === "workspacev2" || event.name === "movewindowv2"
                    || event.name === "focusedmon" || event.name === "focusedmonv2"
                    || event.name === "createworkspace" || event.name === "destroyworkspace") {
                windowsProc.running = true
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: windowsProc.running = true
    }

    property int maxWorkspaceWithWindows: {
        var max = 0
        for (var i = 0; i < workspaceList.length; i++) {
            var id = workspaceId(workspaceList[i])
            if (id > max && id <= 10) max = id
        }
        return max
    }

    property int workspacesToShow: Math.max(5, maxWorkspaceWithWindows, activeWorkspaceId)

    property real lastWheelTime: 0
    function switchWorkspaceByWheel(deltaY) {
        var now = Date.now()
        if (now - lastWheelTime < 220) return
        lastWheelTime = now
        if (deltaY > 0) {
            focusWorkspace("e-1")
        } else if (deltaY < 0) {
            focusWorkspace("e+1")
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
            property var workspace: workspaceBar.workspaceList.find(ws => workspaceBar.workspaceId(ws) === wsId) ?? null
            property bool isActive: workspaceBar.activeWorkspaceId === wsId
            property bool hasWindows: workspace !== null
            property string windowIconsStr: workspaceBar.workspaceIcons[wsId] || ""

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
                        workspaceBar.focusWorkspace(wsRect.wsId)
                    }
                }
                onWheel: wheel => {
                    workspaceBar.switchWorkspaceByWheel(wheel.angleDelta.y)
                }
            }
        }
    }
}
