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
            if (hist.length > 50) hist.pop()
            notifManager.history = hist

            // Show floating popup on screen only if DND is disabled
            if (!notifManager.dndEnabled) {
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

}
