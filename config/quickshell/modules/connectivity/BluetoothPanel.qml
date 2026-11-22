pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import "../theme"

ConnectivityPanel {
    id: root

    title: "Bluetooth"
    radioOn: BluetoothControl.enabled
    radioToggleEnabled: BluetoothControl.available && !BluetoothControl.blocked && !BluetoothControl.powerChanging
    onRadioToggled: BluetoothControl.toggle()

    property var forgetDevice: null

    function deviceGroup(device) {
        return device?.connected ? "Connected" : device?.paired ? "Paired" : "Nearby";
    }

    onOpenChanged: {
        if (!open) {
            forgetDevice = null;
            BluetoothControl.cancelPairing();
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
                    visible: BluetoothControl.enabled && !BluetoothControl.blocked
                    model: visible ? BluetoothControl.devices : []
                    clip: true
                    spacing: 6
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: ColumnLayout {
                        id: entry
                        required property int index
                        required property var modelData
                        readonly property string group: root.deviceGroup(modelData)

                        width: list.width
                        spacing: 5

                        Text {
                            Layout.fillWidth: true
                            Layout.leftMargin: 4
                            visible: entry.index === 0
                                || entry.group !== root.deviceGroup(BluetoothControl.devices[entry.index - 1])
                            text: entry.group
                            color: Monochrome.muted
                            font.family: root.textFont.family
                            font.weight: root.textFont.weight
                            font.pixelSize: 12
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            ConnectivityRow {
                                Layout.fillWidth: true
                                fontFamily: root.textFont.family
                                title: entry.modelData.name || entry.modelData.address
                                detail: entry.group
                                iconName: entry.modelData.connected || entry.modelData.paired
                                    ? "bluetooth-paired-symbolic" : "bluetooth-disconnected-symbolic"
                                rowAction: BluetoothControl.pairDevice === entry.modelData ? "Pairing…"
                                    : BluetoothControl.connectionDevice === entry.modelData
                                        ? (BluetoothControl.connecting ? "Connecting…" : "Disconnecting…")
                                        : entry.modelData.connected ? "Disconnect" : entry.modelData.paired ? "Connect" : "Pair"
                                enabled: !BluetoothControl.pairDevice && !BluetoothControl.connectionDevice && !root.forgetDevice
                                onClicked: BluetoothControl.changeConnection(entry.modelData)
                            }

                            ConnectivityButton {
                                visible: entry.modelData.paired
                                enabled: !BluetoothControl.pairDevice && !BluetoothControl.connectionDevice && !root.forgetDevice
                                text: "Forget"
                                fontFamily: root.textFont.family
                                onClicked: root.forgetDevice = entry.modelData
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    visible: list.count === 0
                    text: BluetoothControl.enabled && !BluetoothControl.blocked
                        ? "Looking for nearby devices…" : BluetoothControl.status
                    color: Monochrome.muted
                    font.family: root.textFont.family
                    font.weight: root.textFont.weight
                    font.pixelSize: 14
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: BluetoothControl.pairDevice !== null || root.forgetDevice !== null
                spacing: 7

                Text {
                    Layout.fillWidth: true
                    text: root.forgetDevice ? "Forget " + (root.forgetDevice.name || root.forgetDevice.address) + "?"
                        : BluetoothControl.promptText || "Waiting for the device…"
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    color: Monochrome.foreground
                    font.family: root.textFont.family
                    font.weight: root.textFont.weight
                    font.pixelSize: 13
                }

                TextField {
                    id: code
                    Layout.fillWidth: true
                    visible: ["pin", "passkey"].includes(BluetoothControl.promptKind)
                    maximumLength: BluetoothControl.promptKind === "passkey" ? 6 : 16
                    placeholderText: BluetoothControl.promptKind === "passkey" ? "Passkey" : "PIN"
                    Accessible.name: placeholderText
                    color: Monochrome.foreground
                    placeholderTextColor: Monochrome.muted
                    font.family: root.textFont.family
                    font.weight: root.textFont.weight
                    font.pixelSize: 14
                    leftPadding: 12
                    rightPadding: 12
                    validator: RegularExpressionValidator {
                        regularExpression: BluetoothControl.promptKind === "passkey" ? /^\d{1,6}$/ : /^[\x20-\x7e]{1,16}$/
                    }

                    background: Rectangle {
                        radius: 10
                        color: Monochrome.background
                        border.color: code.activeFocus ? Monochrome.foreground : "transparent"
                    }

                    onVisibleChanged: {
                        clear();
                        if (visible)
                            forceActiveFocus();
                    }
                    onAccepted: BluetoothControl.answerPairing(text)
                }

                RowLayout {
                    Layout.alignment: Qt.AlignRight

                    ConnectivityButton {
                        text: "Cancel"
                        fontFamily: root.textFont.family
                        onClicked: {
                            if (root.forgetDevice)
                                root.forgetDevice = null;
                            else if (BluetoothControl.promptKind === "confirm")
                                BluetoothControl.answerPairing("no");
                            else
                                BluetoothControl.cancelPairing();
                        }
                    }

                    ConnectivityButton {
                        visible: root.forgetDevice !== null || BluetoothControl.promptKind === "confirm" || code.visible
                        enabled: !code.visible || code.acceptableInput
                        text: root.forgetDevice ? "Forget" : code.visible ? "Submit" : "Confirm"
                        fontFamily: root.textFont.family
                        onClicked: {
                            if (root.forgetDevice) {
                                BluetoothControl.forget(root.forgetDevice);
                                root.forgetDevice = null;
                            } else {
                                BluetoothControl.answerPairing(code.visible ? code.text : "yes");
                            }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: BluetoothControl.error
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                color: Monochrome.muted
                font.family: root.textFont.family
                font.weight: root.textFont.weight
                font.pixelSize: 12
            }
        }
    }
}
