import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

RowLayout {
    id: workspaceBar
    spacing: 3

    property var workspaceList: Compositor.workspaces
    property int activeWorkspaceId: Number(Compositor.activeWorkspaceName) || 0

    function workspaceId(workspace) {
        return workspace && /^\d+$/.test(workspace.name) ? Number(workspace.name) : 0
    }

    function focusWorkspace(workspace) {
        Compositor.focusWorkspace(String(workspace))
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

    property var workspaceIcons: {
        var icons = {}
        for (var window of Compositor.windows) {
            var name = window.workspaceName
            if (!icons[name]) icons[name] = []
            var icon = getWindowIcon(window.appId || window.initialAppId)
            if (!icons[name].includes(icon) && icons[name].length < 3) icons[name].push(icon)
        }
        var labels = {}
        for (var name in icons) labels[name] = icons[name].join(" ")
        return labels
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


    property int maxWorkspaceWithWindows: {
        var max = 0
        for (var i = 0; i < workspaceList.length; i++) {
            var id = workspaceId(workspaceList[i])
            if (id > max && id <= 10) max = id
        }
        return max
    }

    property var workspaceNames: {
        var count = Compositor.isNiri ? 10 : Math.max(5, maxWorkspaceWithWindows, activeWorkspaceId)
        var names = []
        for (var i = 1; i <= count; i++) names.push(String(i))
        return names
    }

    property real lastWheelTime: 0
    function switchWorkspaceByWheel(deltaY) {
        var now = Date.now()
        if (now - lastWheelTime < 220) return
        lastWheelTime = now
        if (deltaY !== 0) Compositor.stepWorkspace(deltaY > 0 ? -1 : 1)
    }

    Repeater {
        model: workspaceBar.workspaceNames

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

            property string wsName: modelData
            property bool isActive: Compositor.activeWorkspaceName === wsName
            property bool hasWindows: Compositor.windows.some(window => window.workspaceName === wsName)
            property string windowIconsStr: workspaceBar.workspaceIcons[wsName] || ""

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            Row {
                id: wsContent
                anchors.centerIn: parent
                spacing: 4

                // Workspace number
                Text {
                    text: wsRect.wsName
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
                    if (!wsRect.isActive) {
                        workspaceBar.focusWorkspace(wsRect.wsName)
                    }
                }
                onWheel: wheel => {
                    workspaceBar.switchWorkspaceByWheel(wheel.angleDelta.y)
                }
            }
        }
    }
}
