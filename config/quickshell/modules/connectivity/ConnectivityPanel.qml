pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

FocusScope {
    id: root

    required property font textFont
    required property string title
    required property bool radioOn
    required property bool radioToggleEnabled
    required property Component panelContent
    property bool open: false

    signal backRequested()
    signal radioToggled()

    readonly property int cornerRadius: 30
    implicitWidth: 432
    implicitHeight: 438
    enabled: open
    opacity: open ? 1 : 0

    Behavior on opacity {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
    }

    onOpenChanged: {
        if (open)
            Qt.callLater(() => { if (root.open) root.forceActiveFocus(); });
    }

    Keys.onEscapePressed: root.backRequested()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 9

            ConnectivityButton {
                text: "‹"
                fontFamily: root.textFont.family
                Accessible.name: "Back to dashboard"
                onClicked: root.backRequested()
            }

            Text {
                Layout.fillWidth: true
                text: root.title
                color: "#ffffff"
                font.family: root.textFont.family
                font.pixelSize: 17
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            ConnectivityButton {
                text: root.radioOn ? "Turn off" : "Turn on"
                fontFamily: root.textFont.family
                enabled: root.radioToggleEnabled
                onClicked: root.radioToggled()
            }
        }

        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            sourceComponent: root.panelContent
        }
    }
}
