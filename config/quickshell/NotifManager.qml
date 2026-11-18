pragma Singleton
import QtQuick
import Quickshell
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
            // After a config reload the server re-announces retained
            // notifications (lastGeneration); the old connections died with
            // the previous QML engine, so connect them again.
            if (!alreadyTracked || notif.lastGeneration) notifManager.watch(notif)
            notifManager.publish(notif, !notif.lastGeneration)
        }
    }

    function watch(notif) {
        var notificationId = notif.id
        notif.closed.connect(() => {
            notifManager.removeToastOnly(notificationId)
            notifManager.history = notifManager.history.map(item => {
                if (item.id !== notificationId) return item
                return Object.assign({}, item, { notification: null })
            })
        })
        // A replacement (`notify-send -r`, progress updates) reuses this object
        // and only changes its properties; onNotification does not fire again.
        // Batch the property signals of one replacement into a single refresh.
        var refresh = () => notifManager.publish(notif, true)
        var scheduleRefresh = () => Qt.callLater(refresh)
        notif.appNameChanged.connect(scheduleRefresh)
        notif.summaryChanged.connect(scheduleRefresh)
        notif.bodyChanged.connect(scheduleRefresh)
        notif.urgencyChanged.connect(scheduleRefresh)
        notif.desktopEntryChanged.connect(scheduleRefresh)
    }

    // Puts the notification's current content at the top of history (one
    // entry per id) and, unless suppressed or in DND, (re)shows its toast.
    function publish(notif, showToast) {
        var item = {
            id: notif.id,
            app: notif.appName || "Notification",
            summary: notif.summary || "Alert",
            body: notif.body || "",
            time: Qt.formatTime(new Date(), "hh:mm"),
            desktopEntry: notif.desktopEntry || "",
            critical: notif.urgency === NotificationUrgency.Critical,
            notification: notif
        }

        var hist = notifManager.history.filter(existing => existing.id !== item.id)
        hist.unshift(item)
        if (hist.length > 50) {
            var oldest = hist.pop()
            if (oldest.notification) oldest.notification.dismiss()
        }
        notifManager.history = hist

        if (showToast && !notifManager.dndEnabled) {
            var toasts = notifManager.activeToasts.filter(existing => existing.id !== item.id)
            toasts.unshift(item)
            if (toasts.length > 5) toasts.pop()
            notifManager.activeToasts = toasts
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
        return clients.filter(client => keys.includes(normalizedApp(client.appId)))
            .sort((a, b) => a.focusRank - b.focusRank)[0] || null
    }

    property var focusQueue: []
    property var focusDelay: Timer {
        interval: 150
        onTriggered: notifManager.startNextFocus()
    }

    function startNextFocus() {
        if (focusQueue.length === 0) return
        var item = focusQueue[0]
        focusQueue = focusQueue.slice(1)
        try {
            var client = matchingWindow(item, Compositor.windows)
            if (client) {
                Compositor.focusWindow(client)
            } else if (!item.actionInvoked) {
                var entry = desktopEntryFor(item)
                if (entry) entry.execute()
            }
        } catch (e) {
            console.warn("Unable to focus notification source:", e)
        }
        if (focusQueue.length > 0) Qt.callLater(startNextFocus)
    }
}
