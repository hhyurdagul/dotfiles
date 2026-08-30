pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Hyprland

QtObject {
    id: notifManager

    property bool dndEnabled: false
    property var history: []
    property var activeToasts: []

    // Native Quickshell Notification Server
    property var server: NotificationServer {
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: notif => {
            var item = {
                id: notif.id || (Date.now() + Math.random()),
                app: notif.appName || "Notification",
                summary: notif.summary || "Alert",
                body: notif.body || "",
                time: Qt.formatTime(new Date(), "hh:mm"),
                desktopEntry: notif.desktopEntry || "",
                hints: notif.hints || {},
                notification: notif
            }

            // Add to history (accumulate even during DND)
            var hist = notifManager.history.slice()
            hist.unshift(item)
            if (hist.length > 50) hist.pop()
            notifManager.history = hist

            // Show floating popup on screen only if DND is disabled
            if (!notifManager.dndEnabled) {
                var toasts = notifManager.activeToasts.slice()
                toasts.unshift(item)
                if (toasts.length > 5) toasts.pop() // keep max 5 floating on screen
                notifManager.activeToasts = toasts
            }
        }
    }

    // Auto-close timer expired (not interacted / dismissed) -> removed from screen, stays in history
    function expireToast(toastId) {
        removeToastOnly(toastId)
    }

    // Interacted with floating toast -> focus window + remove from history + dismiss
    function interactToast(toastId) {
        var item = findToast(toastId)
        removeToastOnly(toastId)
        removeHistoryById(toastId)

        if (item) {
            invokeNotificationAction(item)
            focusSourceWindow(item)
        }
    }

    // Clicked X on floating toast -> remove from history + dismiss + no focus
    function dismissToast(toastId) {
        var item = findToast(toastId)
        removeToastOnly(toastId)
        removeHistoryById(toastId)

        if (item && item.notification && typeof item.notification.dismiss === "function") {
            try {
                item.notification.dismiss()
            } catch (e) {}
        }
    }

    // Interacted with item from dropdown history -> focus window + remove from history
    function interactHistory(index) {
        var hist = notifManager.history.slice()
        if (index >= 0 && index < hist.length) {
            var item = hist[index]
            hist.splice(index, 1)
            notifManager.history = hist

            if (item && item.id) {
                removeToastOnly(item.id)
            }

            if (item) {
                invokeNotificationAction(item)
                focusSourceWindow(item)
            }
        }
    }

    function dismissFromHistory(index) {
        var hist = notifManager.history.slice()
        if (index >= 0 && index < hist.length) {
            var item = hist[index]
            hist.splice(index, 1)
            notifManager.history = hist

            if (item && item.notification && typeof item.notification.dismiss === "function") {
                try {
                    item.notification.dismiss()
                } catch (e) {}
            }
        }
    }

    function clearHistory() {
        notifManager.history = []
    }

    function toggleDnd() {
        notifManager.dndEnabled = !notifManager.dndEnabled
    }

    // Helper functions
    function findToast(toastId) {
        for (var i = 0; i < notifManager.activeToasts.length; i++) {
            if (notifManager.activeToasts[i].id === toastId) {
                return notifManager.activeToasts[i]
            }
        }
        return null
    }

    function removeToastOnly(toastId) {
        var toasts = notifManager.activeToasts.slice()
        for (var i = 0; i < toasts.length; i++) {
            if (toasts[i].id === toastId) {
                toasts.splice(i, 1)
                break
            }
        }
        notifManager.activeToasts = toasts
    }

    function removeHistoryById(toastId) {
        var hist = notifManager.history.slice()
        for (var i = 0; i < hist.length; i++) {
            if (hist[i].id === toastId) {
                hist.splice(i, 1)
                break
            }
        }
        notifManager.history = hist
    }

    function removeToast(toastId) {
        removeToastOnly(toastId)
    }

    function invokeNotificationAction(item) {
        if (!item || !item.notification) return

        try {
            var notif = item.notification
            var invoked = false

            if (notif.actions && notif.actions.length > 0) {
                var defaultAction = null
                for (var i = 0; i < notif.actions.length; i++) {
                    if (notif.actions[i].identifier === "default") {
                        defaultAction = notif.actions[i]
                        break
                    }
                }
                if (!defaultAction && notif.actions.length > 0) {
                    defaultAction = notif.actions[0]
                }
                if (defaultAction && typeof defaultAction.invoke === "function") {
                    defaultAction.invoke()
                    invoked = true
                }
            }

            if (!invoked && typeof notif.dismiss === "function") {
                notif.dismiss()
            }
        } catch (e) {
            console.warn("Error invoking notification action:", e)
        }
    }

    function focusSourceWindow(item) {
        if (!item) return

        var senderPid = (item.hints && (item.hints["sender-pid"] || item.hints["pid"])) || null
        var desktopEntry = (item.desktopEntry || (item.hints && item.hints["desktop-entry"]) || "").toLowerCase()
        var appName = (item.app || "").toLowerCase()
        var summary = (item.summary || "").toLowerCase()

        desktopEntry = desktopEntry.replace(/\.desktop$/, "")
        var desktopBase = ""
        if (desktopEntry.includes(".")) {
            var parts = desktopEntry.split(".")
            desktopBase = parts[parts.length - 1]
        }

        var cleanApp = appName.replace(/[\s\-_]/g, "")
        var cleanDesktop = desktopEntry.replace(/[\s\-_]/g, "")
        var cleanDesktopBase = desktopBase.replace(/[\s\-_]/g, "")

        var matchedAddress = ""

        if (typeof Hyprland !== "undefined" && Hyprland.toplevels && Hyprland.toplevels.values) {
            var toplevels = Hyprland.toplevels.values

            // 1. Match by sender PID if available
            if (senderPid) {
                for (var i = 0; i < toplevels.length; i++) {
                    var top = toplevels[i]
                    var ipc = top.lastIpcObject
                    if (ipc && ipc.pid === senderPid) {
                        matchedAddress = top.address || (ipc && ipc.address) || ""
                        break
                    }
                }
            }

            // 2. Match by window class / initialClass
            if (!matchedAddress) {
                for (var j = 0; j < toplevels.length; j++) {
                    var top2 = toplevels[j]
                    var ipc2 = top2.lastIpcObject
                    var cls = (ipc2 && ipc2.class ? ipc2.class : "").toLowerCase()
                    var initCls = (ipc2 && ipc2.initialClass ? ipc2.initialClass : "").toLowerCase()
                    var cleanCls = cls.replace(/[\s\-_]/g, "")
                    var cleanInitCls = initCls.replace(/[\s\-_]/g, "")

                    if (cleanDesktop && (cleanCls === cleanDesktop || cleanInitCls === cleanDesktop ||
                        cleanCls.includes(cleanDesktop) || cleanDesktop.includes(cleanCls))) {
                        matchedAddress = top2.address || (ipc2 && ipc2.address) || ""
                        break
                    }
                    if (cleanDesktopBase && (cleanCls === cleanDesktopBase || cleanInitCls === cleanDesktopBase ||
                        cleanCls.includes(cleanDesktopBase) || cleanDesktopBase.includes(cleanCls))) {
                        matchedAddress = top2.address || (ipc2 && ipc2.address) || ""
                        break
                    }
                    if (cleanApp && (cleanCls === cleanApp || cleanInitCls === cleanApp ||
                        cleanCls.includes(cleanApp) || cleanApp.includes(cleanCls))) {
                        matchedAddress = top2.address || (ipc2 && ipc2.address) || ""
                        break
                    }
                }
            }

            // 3. Match by window title
            if (!matchedAddress) {
                for (var k = 0; k < toplevels.length; k++) {
                    var top3 = toplevels[k]
                    var title = (top3.title || (top3.lastIpcObject && top3.lastIpcObject.title) || "").toLowerCase()
                    if (appName && appName.length > 2 && title.includes(appName)) {
                        matchedAddress = top3.address || (top3.lastIpcObject && top3.lastIpcObject.address) || ""
                        break
                    }
                    if (summary && summary.length > 2 && title.includes(summary)) {
                        matchedAddress = top3.address || (top3.lastIpcObject && top3.lastIpcObject.address) || ""
                        break
                    }
                }
            }
        }

        if (matchedAddress) {
            var addr = matchedAddress.startsWith("0x") ? matchedAddress : ("0x" + matchedAddress)
            Hyprland.dispatch("hl.dsp.focus({ window = 'address:" + addr + "' })")
        } else {
            var fallbackTarget = cleanDesktopBase || cleanDesktop || cleanApp
            if (fallbackTarget && fallbackTarget !== "notification" && fallbackTarget !== "alert") {
                Hyprland.dispatch("hl.dsp.focus({ window = 'class:(?i)" + fallbackTarget + "' })")
            }
        }
    }
}
