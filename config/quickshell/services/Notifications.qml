pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    readonly property var popup: queue[0] ?? null
    property var entries: []
    property var queue: []
    property bool available: false
    property bool focusEnabled: false
    property bool popupsPaused: false

    function start() {
        focusState.reload();
        Qt.callLater(root.checkAvailability);
    }

    function checkAvailability() {
        if (!ownerCheck.running)
            ownerCheck.running = true;
    }

    function toggleFocus() {
        focusState.restorePending = false;
        focusEnabled = !focusEnabled;
        saveFocus.restart();
        if (focusEnabled)
            hidePopups();
    }

    function receive(notification) {
        available = true;
        const id = notification.id;
        const previous = entries.find(entry => entry.id === id)
            ?? queue.find(entry => entry.id === id);
        if (!previous || previous.notification !== notification)
            notification.closed.connect(() => root.remove(id, notification));

        notification.tracked = true;
        const receivedTimes = JSON.parse(session.timestamps);
        const receivedAt = notification.lastGeneration ? (receivedTimes[id] ?? Date.now()) : Date.now();
        const entry = { id, notification, receivedAt };
        const remaining = entries.filter(item => item.id !== id);
        if (!notification.transient) {
            receivedTimes[id] = receivedAt;
            session.timestamps = JSON.stringify(receivedTimes);
            entries = [entry, ...remaining].sort((a, b) => b.receivedAt - a.receivedAt);
        } else if (previous) {
            entries = remaining;
        }

        if (notification.lastGeneration || focusEnabled) {
            if (notification.transient)
                Qt.callLater(() => notification?.expire());
            return;
        }

        const index = queue.findIndex(item => item.id === id);
        if (index >= 0) {
            queue = queue.map(item => item.id === id ? entry : item);
        } else if (queue.length < 6) {
            queue = [...queue, entry];
        } else if (notification.transient) {
            Qt.callLater(() => notification?.expire());
        }
    }

    function remove(id, notification) {
        entries = entries.filter(entry => entry.id !== id || entry.notification !== notification);
        queue = queue.filter(entry => entry.id !== id || entry.notification !== notification);
        if (!entries.some(entry => entry.id === id)) {
            const receivedTimes = JSON.parse(session.timestamps);
            if (id in receivedTimes) {
                delete receivedTimes[id];
                session.timestamps = JSON.stringify(receivedTimes);
            }
        }
    }

    function dismiss(entry) {
        entry?.notification.dismiss();
    }

    function clearAll() {
        const notifications = new Set([...entries, ...queue].map(entry => entry.notification));
        for (const notification of notifications)
            notification.dismiss();
    }

    function hidePopups() {
        const previous = queue;
        queue = [];
        for (const entry of previous) {
            if (entry.notification.transient)
                entry.notification.expire();
        }
    }

    function advancePopup() {
        const previous = popup;
        if (!previous)
            return;
        queue = queue.slice(1);
        if (previous.notification.transient)
            previous.notification.expire();
    }

    function updatePopupTimer() {
        popupTimer.stop();
        if (popup && !popupsPaused && !focusEnabled)
            popupTimer.start();
    }

    onPopupChanged: updatePopupTimer()
    onPopupsPausedChanged: updatePopupTimer()

    NotificationServer {
        keepOnReload: true
        persistenceSupported: true
        onNotification: notification => root.receive(notification)
    }

    PersistentProperties {
        id: session
        property string timestamps: "{}"
    }

    FileView {
        id: focusState
        property bool restorePending: true
        path: Quickshell.stateDir + "/notification-focus.json"
        printErrors: false
        atomicWrites: true

        onLoaded: {
            if (!restorePending)
                return;
            restorePending = false;
            root.focusEnabled = text().trim() === "true";
            if (root.focusEnabled)
                root.hidePopups();
        }
        onSaveFailed: error => console.warn("Couldn't save notification Focus setting:", error)
    }

    Timer {
        id: saveFocus
        interval: 80
        onTriggered: focusState.setText(JSON.stringify(root.focusEnabled))
    }

    Timer {
        id: popupTimer
        interval: Math.max(2500, Math.min(10000, root.popup?.notification.expireTimeout > 0
            ? root.popup.notification.expireTimeout : 5000))
        onTriggered: root.advancePopup()
    }

    Process {
        id: ownerCheck
        command: ["busctl", "--user", "call", "org.freedesktop.DBus", "/org/freedesktop/DBus",
            "org.freedesktop.DBus", "GetConnectionUnixProcessID", "s", "org.freedesktop.Notifications"]
        stdout: StdioCollector { id: ownerReply }
        onExited: (code, status) => {
            root.available = code === 0 && status === 0
                && ownerReply.text.trim() === "u " + Quickshell.processId;
        }
    }
}
