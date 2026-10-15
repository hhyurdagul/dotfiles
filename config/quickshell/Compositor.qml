pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// One IPC owner for every bar, title, overlay and notification focus request.
QtObject {
    id: compositor
    readonly property string desktop: (Quickshell.env("XDG_CURRENT_DESKTOP") || "").toLowerCase()
    readonly property bool isNiri: desktop.includes("niri")
        || (!desktop.includes("hyprland") && !!Quickshell.env("NIRI_SOCKET"))
    readonly property string session: isNiri ? "niri" : "hyprland"
    property var workspaces: []
    property var windows: []
    property string focusedOutput: ""
    readonly property string activeWorkspaceName: workspaces.find(ws => ws.focused)?.name || ""
    readonly property var activeWindow: windows.find(window => window.focused) || null
    readonly property string activeWindowTitle: activeWindow?.title || ""
    property string lastFocusKey: ""
    property var lastWindowId: null
    signal focusChanged()

    function notifyFocus() {
        // Grabbing a popup temporarily clears the focused application. Do not
        // immediately dismiss that same popup in response to its own grab.
        if (activeWindow) lastWindowId = activeWindow.id
        var key = activeWorkspaceName + ":" + String(lastWindowId ?? "")
        if (key !== lastFocusKey) {
            lastFocusKey = key
            focusChanged()
        }
    }

    function focusWorkspace(name) {
        if (isNiri) {
            // CLI numeric strings mean output-local indices; IPC Name is unambiguous.
            sendNiri({ FocusWorkspace: { reference: { Name: String(name) } } })
        } else {
            Quickshell.execDetached(["hyprctl", "eval",
                "hl.dispatch(hl.dsp.focus({ workspace = " + JSON.stringify(String(name)) + " }))"])
            hyprRefresh.restart()
        }
    }

    function stepWorkspace(delta) {
        if (isNiri) {
            var current = Number(activeWorkspaceName)
            var next = Math.max(1, Math.min(10, (current >= 1 && current <= 10 ? current : 1) + delta))
            focusWorkspace(String(next))
        } else {
            focusWorkspace(delta < 0 ? "e-1" : "e+1")
        }
    }

    function focusWindow(window) {
        if (!window) return
        if (isNiri && Number.isSafeInteger(window.id) && window.id >= 0) {
            sendNiri({ FocusWindow: { id: window.id } })
        } else if (!isNiri && /^0x[0-9a-f]+$/i.test(String(window.id))) {
            Quickshell.execDetached(["hyprctl", "eval",
                'hl.dispatch(hl.dsp.focus({ window = "address:' + window.id + '" }))'])
            hyprRefresh.restart()
        }
    }

    property var pendingActions: []
    function sendNiri(action) {
        var request = JSON.stringify({ Action: action }) + "\n"
        if (actionSocket.connected) {
            actionSocket.write(request)
            actionSocket.flush()
        } else {
            pendingActions = pendingActions.concat([request])
            actionSocket.connected = true
        }
    }

    property var actionConnection: Socket {
        id: actionSocket
        path: Quickshell.env("NIRI_SOCKET") || ""
        connected: compositor.isNiri
        onConnectedChanged: {
            if (!connected) return
            for (var request of compositor.pendingActions) write(request)
            flush()
            compositor.pendingActions = []
        }
        parser: SplitParser {
            onRead: data => {
                try {
                    var reply = JSON.parse(data)
                    if (reply.Err) console.warn("Niri action failed:", reply.Err)
                } catch (e) { console.warn("Invalid Niri action reply:", e) }
            }
        }
    }

    property var niriWorkspaces: []
    property var niriWindows: []

    function publishNiri() {
        workspaces = niriWorkspaces.map(ws => ({
            id: ws.id, name: ws.name || "", output: ws.output || "",
            active: ws.is_active, focused: ws.is_focused
        }))
        var focused = workspaces.find(ws => ws.focused)
        focusedOutput = focused?.output || ""
        windows = niriWindows.map(window => ({
            id: window.id, title: window.title || "", appId: window.app_id || "",
            initialAppId: "", focused: window.is_focused,
            workspaceName: workspaces.find(ws => ws.id === window.workspace_id)?.name || "",
            focusRank: window.focus_timestamp
                ? -(window.focus_timestamp.secs + window.focus_timestamp.nanos / 1000000000) : 0
        }))
        notifyFocus()
    }

    function handleNiri(event) {
        if (event.WorkspacesChanged) {
            niriWorkspaces = event.WorkspacesChanged.workspaces
        } else if (event.WorkspaceActivated) {
            var activated = event.WorkspaceActivated
            var target = niriWorkspaces.find(ws => ws.id === activated.id)
            niriWorkspaces = niriWorkspaces.map(ws => Object.assign({}, ws, {
                is_active: target && ws.output === target.output ? ws.id === activated.id : ws.is_active,
                is_focused: activated.focused ? ws.id === activated.id : ws.is_focused
            }))
        } else if (event.WindowsChanged) {
            niriWindows = event.WindowsChanged.windows
        } else if (event.WindowOpenedOrChanged) {
            var updated = event.WindowOpenedOrChanged.window
            var list = niriWindows.filter(window => window.id !== updated.id)
            if (updated.is_focused) list = list.map(window => Object.assign({}, window, { is_focused: false }))
            niriWindows = list.concat([updated])
        } else if (event.WindowClosed) {
            niriWindows = niriWindows.filter(window => window.id !== event.WindowClosed.id)
        } else if (event.WindowFocusChanged) {
            niriWindows = niriWindows.map(window => Object.assign({}, window, {
                is_focused: window.id === event.WindowFocusChanged.id
            }))
        } else if (event.WindowFocusTimestampChanged) {
            var timestamp = event.WindowFocusTimestampChanged
            niriWindows = niriWindows.map(window => window.id === timestamp.id
                ? Object.assign({}, window, { focus_timestamp: timestamp.focus_timestamp }) : window)
        } else {
            return
        }
        publishNiri()
    }

    property var eventConnection: Socket {
        id: eventSocket
        path: Quickshell.env("NIRI_SOCKET") || ""
        connected: compositor.isNiri
        onConnectedChanged: {
            if (!connected) return
            // Each subscription begins with complete workspace and window state.
            write('"EventStream"\n')
            flush()
        }
        parser: SplitParser {
            onRead: data => {
                try { compositor.handleNiri(JSON.parse(data)) }
                catch (e) { console.warn("Invalid Niri event:", e) }
            }
        }
    }

    property var reconnectTimer: Timer {
        interval: 1000
        repeat: true
        running: compositor.isNiri && (!eventSocket.connected || !actionSocket.connected)
        onTriggered: {
            if (!eventSocket.connected) eventSocket.connected = true
            if (!actionSocket.connected) actionSocket.connected = true
        }
    }

    function hyprWorkspaceName(workspace) {
        if (!workspace) return ""
        var value = workspace.id ?? workspace.address
        return /^\d+$/.test(String(value)) ? String(Number(value)) : String(workspace.name || "")
    }

    // Hyprland fallback deliberately avoids importing/initializing Hyprland QML
    // modules under Niri. All widgets share this one snapshot and timer.
    property var hyprSnapshot: Process {
        id: hyprProc
        command: ["sh", "-c", "hyprctl -j --batch 'activeworkspace;workspaces;clients;activewindow;monitors' | jq -sc '{active: .[0], workspaces: .[1], clients: .[2], window: .[3], monitors: .[4]}'"]
        running: !compositor.isNiri
        stdout: StdioCollector { id: hyprOutput }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) return
            try {
                var state = JSON.parse(hyprOutput.text)
                if (!state.active || !Array.isArray(state.workspaces) || !Array.isArray(state.clients)
                        || !Array.isArray(state.monitors)) return
                var activeName = compositor.hyprWorkspaceName(state.active)
                compositor.workspaces = state.workspaces.map(ws => ({
                    id: ws.id ?? ws.address, name: compositor.hyprWorkspaceName(ws),
                    output: ws.monitor || "", active: compositor.hyprWorkspaceName(ws) === activeName,
                    focused: compositor.hyprWorkspaceName(ws) === activeName
                }))
                compositor.focusedOutput = state.monitors.find(monitor => monitor.focused)?.name || ""
                compositor.windows = state.clients.filter(client => client.mapped !== false).map(client => ({
                    id: client.address, title: client.title || "", appId: client.class || "",
                    initialAppId: client.initialClass || "", focused: client.address === state.window?.address,
                    workspaceName: compositor.hyprWorkspaceName(client.workspace), focusRank: client.focusHistoryID ?? 9999
                }))
                compositor.notifyFocus()
            } catch (e) { console.warn("Invalid Hyprland snapshot:", e) }
        }
    }

    property var hyprRefreshTimer: Timer {
        id: hyprRefresh
        interval: 100
        onTriggered: if (!hyprProc.running) hyprProc.running = true
    }
    property var hyprPollTimer: Timer {
        interval: 1000
        repeat: true
        running: !compositor.isNiri
        onTriggered: if (!hyprProc.running) hyprProc.running = true
    }
}
