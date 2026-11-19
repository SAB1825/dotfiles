pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs.services
import "../theme"

WlSessionLock {
    id: lock

    property string status: ""
    property string pendingPassword: ""
    property bool passwordSent: false

    readonly property Timer authenticationTimeout: Timer {
        interval: 15000
        onTriggered: {
            lock.pendingPassword = "";
            lock.status = "Authentication timed out. Try again";
            pam.abort();
        }
    }

    function engage(): void {
        if (locked)
            return;
        status = "";
        locked = true;
    }

    function authenticate(password: string): void {
        if (!secure || pam.active || !password.length)
            return;

        pendingPassword = password;
        passwordSent = false;
        status = "Unlocking…";
        authenticationTimeout.restart();
        if (!pam.start()) {
            authenticationTimeout.stop();
            pendingPassword = "";
            status = "Authentication unavailable";
        }
    }

    readonly property PamContext authenticator: PamContext {
        id: pam

        config: "swaylock"
        configDirectory: "/etc/pam.d"

        onPamMessage: {
            if (!responseRequired)
                return;
            if (!lock.authenticationTimeout.running)
                return;
            if (responseVisible || lock.passwordSent) {
                lock.authenticationTimeout.stop();
                lock.pendingPassword = "";
                lock.status = "Authentication unavailable";
                pam.abort();
                return;
            }

            lock.passwordSent = true;
            pam.respond(lock.pendingPassword);
            lock.pendingPassword = "";
        }

        onCompleted: result => {
            if (!lock.authenticationTimeout.running)
                return;
            lock.authenticationTimeout.stop();
            lock.pendingPassword = "";
            if (result === PamResult.Success && lock.secure) {
                lock.status = "";
                lock.locked = false;
            } else {
                lock.status = result === PamResult.Failed || result === PamResult.MaxTries
                    ? "Incorrect password" : "Authentication unavailable";
            }
        }

        onError: {
            if (!lock.authenticationTimeout.running)
                return;
            lock.authenticationTimeout.stop();
            lock.pendingPassword = "";
            lock.status = "Authentication unavailable";
        }
    }

    surface: WlSessionLockSurface {
        color: Monochrome.background

        LockView {
            anchors.fill: parent
            wallpaperPath: Wallpaper.currentPath
            busy: pam.active
            status: lock.status

            onSubmitted: password => lock.authenticate(password)
            onEdited: {
                if (!pam.active)
                    lock.status = "";
            }
        }
    }
}
