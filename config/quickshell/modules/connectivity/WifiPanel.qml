pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import qs.services
import "../theme"

ConnectivityPanel {
    id: root

    title: "Wi-Fi"
    radioOn: Wifi.enabled
    radioToggleEnabled: Wifi.available && !Wifi.blocked && !Wifi.pending
    onRadioToggled: Wifi.toggle()

    property var passwordNetwork: null
    property string notice: ""

    signal dismissRequested()

    function select(network) {
        notice = "";
        if (network.connected || Wifi.canJoinWithoutPassword(network))
            Wifi.changeConnection(network);
        else if (Wifi.usesPassword(network))
            passwordNetwork = network;
        else
            notice = "Open Advanced to configure this network.";
    }

    onOpenChanged: {
        if (!open) {
            passwordNetwork = null;
            notice = "";
        }
    }

    Connections {
        target: Wifi

        function onRetryNetworkChanged() {
            if (root.open && Wifi.retryNetwork)
                root.passwordNetwork = Wifi.retryNetwork;
        }

        function onEnabledChanged() {
            if (!Wifi.enabled)
                root.passwordNetwork = null;
        }
    }

    panelContent: Component {
        ColumnLayout {
            spacing: 8

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: list
                    anchors.fill: parent
                    clip: true
                    spacing: 6
                    boundsBehavior: Flickable.StopAtBounds
                    visible: Wifi.enabled && !Wifi.blocked
                    model: visible ? Wifi.networks : []

                    delegate: ConnectivityRow {
                        id: networkRow
                        required property var modelData
                        readonly property bool secured: modelData.security !== WifiSecurityType.Open
                            && modelData.security !== WifiSecurityType.Owe

                        width: list.width
                        fontFamily: root.textFont.family
                        title: modelData.name
                        iconName: {
                            const strength = modelData.signalStrength;
                            const level = strength > 0.75 ? "excellent" : strength > 0.50 ? "good"
                                : strength > 0.25 ? "ok" : strength > 0 ? "low" : "none";
                            return (secured ? "network-wireless-secure-signal-" : "network-wireless-signal-") + level;
                        }
                        detail: (modelData.connected ? "Connected" : modelData.known ? "Saved"
                            : secured ? "Secured" : "Open") + " · " + Math.round(modelData.signalStrength * 100) + "%"
                        rowAction: modelData.stateChanging || Wifi.pending === modelData
                            ? (modelData.state === ConnectionState.Disconnecting
                                || (Wifi.pending === modelData && !Wifi.joining) ? "Disconnecting…" : "Joining…")
                            : modelData.connected ? "Disconnect" : "Join"
                        enabled: !Wifi.pending && !root.passwordNetwork && !modelData.stateChanging
                        onClicked: root.select(modelData)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    visible: list.count === 0
                    text: !Wifi.available || Wifi.blocked || !Wifi.enabled ? Wifi.status : "Looking for networks…"
                    color: Monochrome.muted
                    font.family: root.textFont.family
                    font.weight: root.textFont.weight
                    font.pixelSize: 14
                }
            }

            Loader {
                Layout.fillWidth: true
                active: root.passwordNetwork !== null
                sourceComponent: ColumnLayout {
                    id: credentialPrompt
                    spacing: 7

                    function join() {
                        const secret = password.text;
                        if (!secret)
                            return;
                        const network = root.passwordNetwork;
                        password.clear();
                        root.passwordNetwork = null;
                        Wifi.changeConnection(network, secret);
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Password for " + (root.passwordNetwork?.name ?? "")
                        textFormat: Text.PlainText
                        color: Monochrome.foreground
                        font.family: root.textFont.family
                        font.weight: root.textFont.weight
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }

                    TextField {
                        id: password
                        Layout.fillWidth: true
                        echoMode: TextInput.Password
                        placeholderText: "Wi-Fi password"
                        Accessible.name: placeholderText
                        color: Monochrome.foreground
                        placeholderTextColor: Monochrome.muted
                        font.family: root.textFont.family
                        font.weight: root.textFont.weight
                        font.pixelSize: 14
                        leftPadding: 12
                        rightPadding: 12
                        inputMethodHints: Qt.ImhHiddenText | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText

                        background: Rectangle {
                            radius: 10
                            color: Monochrome.background
                            border.color: password.activeFocus ? Monochrome.foreground : "transparent"
                        }

                        Component.onCompleted: forceActiveFocus()
                        onAccepted: credentialPrompt.join()
                        Keys.onEscapePressed: root.passwordNetwork = null
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        ConnectivityButton {
                            text: "Cancel"
                            fontFamily: root.textFont.family
                            onClicked: root.passwordNetwork = null
                        }
                        ConnectivityButton {
                            text: "Join"
                            fontFamily: root.textFont.family
                            enabled: password.text.length > 0
                            onClicked: credentialPrompt.join()
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: Wifi.error || root.notice
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    color: Monochrome.muted
                    font.family: root.textFont.family
                    font.weight: root.textFont.weight
                    font.pixelSize: 12
                }

                ConnectivityButton {
                    text: "Advanced"
                    fontFamily: root.textFont.family
                    onClicked: {
                        root.dismissRequested();
                        Quickshell.execDetached(["nm-connection-editor"]);
                    }
                }
            }
        }
    }
}
