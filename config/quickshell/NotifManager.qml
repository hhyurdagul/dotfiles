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
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: notif => {
            var item = {
                id: notif.id || Date.now() + Math.random(),
                app: notif.appName || "Notification",
                summary: notif.summary || "Alert",
                body: notif.body || "",
                time: Qt.formatTime(new Date(), "hh:mm")
            }

            // Always add to history (accumulate even during DND)
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

    function removeToast(toastId) {
        var toasts = notifManager.activeToasts.slice()
        for (var i = 0; i < toasts.length; i++) {
            if (toasts[i].id === toastId) {
                toasts.splice(i, 1)
                break
            }
        }
        notifManager.activeToasts = toasts
    }

    function dismissFromHistory(index) {
        var hist = notifManager.history.slice()
        hist.splice(index, 1)
        notifManager.history = hist
    }

    function clearHistory() {
        notifManager.history = []
    }

    function toggleDnd() {
        notifManager.dndEnabled = !notifManager.dndEnabled
    }
}
