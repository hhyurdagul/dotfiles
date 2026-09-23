pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

QtObject {
    id: notifManager

    property bool dndEnabled: false
    property var history: []
    property var activeToasts: []

    // Native Quickshell Notification Server
    property var server: NotificationServer {
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: false
        actionsSupported: true
        imageSupported: true

        onNotification: notif => {
            // Keep actions valid after this signal returns and while in history.
            var alreadyTracked = notif.tracked
            notif.tracked = true
            var notificationId = notif.id
            if (!alreadyTracked || notif.lastGeneration) notif.closed.connect(() => {
                notifManager.removeToastOnly(notificationId)
                notifManager.history = notifManager.history.map(item => {
                    if (item.id !== notificationId) return item
                    return Object.assign({}, item, { notification: null })
                })
            })
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

            // Replacement IDs update existing entries instead of duplicating them.
            var hist = notifManager.history.filter(existing => existing.id !== item.id)
            hist.unshift(item)
            if (hist.length > 50) {
                var oldest = hist.pop()
                if (oldest.notification) oldest.notification.dismiss()
            }
            notifManager.history = hist

            // Show floating popup on screen only if DND is disabled
            if (!notifManager.dndEnabled && !notif.lastGeneration) {
                var toasts = notifManager.activeToasts.filter(existing => existing.id !== item.id)
                toasts.unshift(item)
                if (toasts.length > 5) toasts.pop()
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
            }
        }
    }

    function dismissFromHistory(index) {
        var hist = notifManager.history.slice()
        if (index >= 0 && index < hist.length) {
            var item = hist[index]
            hist.splice(index, 1)
            notifManager.history = hist

            if (item && item.id) {
                removeToastOnly(item.id)
            }

            if (item && item.notification && typeof item.notification.dismiss === "function") {
                try {
                    item.notification.dismiss()
                } catch (e) {}
            }
        }
    }

    function clearHistory() {
        var hist = notifManager.history.slice()
        for (var i = 0; i < hist.length; i++) {
            var notification = hist[i].notification
            if (notification && typeof notification.dismiss === "function") {
                try {
                    notification.dismiss()
                } catch (e) {}
            }
        }
        notifManager.history = []
        notifManager.activeToasts = []
    }

    function toggleDnd() {
        notifManager.dndEnabled = !notifManager.dndEnabled
        if (notifManager.dndEnabled) notifManager.activeToasts = []
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
        if (!item) return
        // Invoking the action may destroy the native notification immediately.
        // Keep plain source metadata for the compositor focus request.
        var focusRequest = Object.assign({}, item, { notification: null, actionInvoked: false })
        try {
            var notif = item.notification
            if (notif) {
                // Only the default action means “open”. Other actions may delete
                // or archive content and must never be chosen implicitly.
                for (var i = 0; i < notif.actions.length; i++) {
                    if (notif.actions[i].identifier === "default") {
                        var resident = notif.resident
                        notif.actions[i].invoke()
                        focusRequest.actionInvoked = true
                        if (resident) notif.dismiss()
                        break
                    }
                }
                if (!focusRequest.actionInvoked) notif.dismiss()
            }
        } catch (e) {
            console.warn("Notification action unavailable:", e)
        }
        focusQueue = focusQueue.concat([focusRequest])
        // Let the notification popup release its focus grab before switching.
        focusDelay.restart()
    }

    function normalizedApp(value) {
        return String(value || "").toLowerCase().replace(/\.desktop$/, "").replace(/[^a-z0-9]/g, "")
    }

    function desktopEntryFor(item) {
        var id = (item.desktopEntry || "").replace(/\.desktop$/, "")
        // Codex notifications in this setup come from the Paseo agent window.
        // Its notification label and Wayland app id are different.
        if (normalizedApp(item.app) === "codex" || normalizedApp(id) === "codex") {
            var agentEntry = DesktopEntries.byId("paseo-desktop")
            if (agentEntry) return agentEntry
        }
        var entry = id ? DesktopEntries.byId(id) : null
        if (entry) return entry
        var key = normalizedApp(item.app)
        var matches = DesktopEntries.applications.values.filter(candidate =>
            [candidate.id, candidate.name, candidate.startupClass].some(name => key && normalizedApp(name) === key))
        return matches.length === 1 ? matches[0] : null
    }

    function matchingWindow(item, clients) {
        var entry = desktopEntryFor(item)
        var names = [item.desktopEntry, item.app]
        if (entry) names = names.concat([entry.id, entry.name, entry.startupClass])
        var keys = names.map(normalizedApp).filter(key => key.length > 0)
        return clients.filter(client => client.mapped !== false
            && [client.class, client.initialClass].some(name => keys.includes(normalizedApp(name))))
            .sort((a, b) => (a.focusHistoryID ?? 9999) - (b.focusHistoryID ?? 9999))[0] || null
    }

    property var focusQueue: []
    property var focusItem: null
    property var focusDelay: Timer {
        interval: 150
        onTriggered: notifManager.startNextFocus()
    }

    function startNextFocus() {
        if (focusProc.running || focusQueue.length === 0) return
        focusItem = focusQueue[0]
        focusQueue = focusQueue.slice(1)
        focusProc.running = true
    }

    property var focusProc: Process {
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector { id: focusOutput }
        onExited: (exitCode, exitStatus) => {
            var item = notifManager.focusItem
            try {
                if (exitCode === 0) {
                    var client = notifManager.matchingWindow(item, JSON.parse(focusOutput.text))
                    if (client && /^0x[0-9a-f]+$/i.test(client.address)) {
                        Quickshell.execDetached(["hyprctl", "eval",
                            'hl.dispatch(hl.dsp.focus({ window = "address:' + client.address + '" }))'])
                    } else if (!item.actionInvoked) {
                        var entry = notifManager.desktopEntryFor(item)
                        if (entry) entry.execute()
                    }
                }
            } catch (e) {
                console.warn("Unable to focus notification source:", e)
            }
            notifManager.focusItem = null
            Qt.callLater(notifManager.startNextFocus)
        }
    }
}
