import QtQuick
import QtQuick.Effects
import qs.services
import "../theme"

Item {
    id: root

    property string wallpaperPath: ""
    property bool busy: false
    property string status: ""
    readonly property real clockSize: Math.max(34, Math.min(width * 0.15, height * 0.27, 240))

    signal submitted(string password)
    signal edited()

    Rectangle {
        anchors.fill: parent
        z: -3
        color: Monochrome.background
    }

    Item {
        id: backdrop
        anchors.fill: parent
        z: -2

        Image {
            id: wallpaper
            anchors.fill: parent
            source: root.wallpaperPath
                ? "file://" + root.wallpaperPath.split("/").map(encodeURIComponent).join("/") : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(Monochrome.background, 0.28)
        }
    }

    Text {
        id: clock
        anchors.centerIn: parent
        text: Time.hours + ":" + Time.minutes
        color: Monochrome.accent
        visible: !glass.visible
        renderType: Text.CurveRendering
        font.family: Typography.family
        font.weight: Typography.weight
        font.pixelSize: root.clockSize
        font.letterSpacing: -root.clockSize * 0.05
        leftPadding: Math.ceil(root.clockSize * 0.07)
        rightPadding: leftPadding
    }

    // Sample the visible wallpaper for the frost inside the clock glyphs.
    ShaderEffectSource {
        id: clockBackdrop
        sourceItem: backdrop
        sourceRect: Qt.rect(clock.x, clock.y, clock.width, clock.height)
        width: clock.width
        height: clock.height
        visible: false
        live: glass.visible
    }

    Text {
        id: maskText
        anchors.fill: clock
        text: clock.text
        font: clock.font
        leftPadding: clock.leftPadding
        rightPadding: clock.rightPadding
        color: "white"
        renderType: clock.renderType
        visible: glass.visible
    }

    ShaderEffectSource {
        id: clockMask
        sourceItem: maskText
        // Supersample the glyph mask to retain coverage along the curves.
        textureSize: Qt.size(Math.ceil(maskText.width * Screen.devicePixelRatio * 2),
            Math.ceil(maskText.height * Screen.devicePixelRatio * 2))
        smooth: true
        hideSource: true
        visible: false
    }

    Item {
        id: frostedFill
        anchors.fill: clock
        visible: glass.visible

        MultiEffect {
            anchors.fill: parent
            source: clockBackdrop
            autoPaddingEnabled: false
            blurEnabled: true
            blurMax: 48
            blur: 0.8
            brightness: 0.36
            saturation: -1
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(Monochrome.accent, 0.75)
        }
    }

    ShaderEffectSource {
        id: glassFill
        sourceItem: frostedFill
        hideSource: true
        visible: false
    }

    MultiEffect {
        id: glass
        anchors.fill: clock
        z: -1
        visible: wallpaper.status === Image.Ready && clock.width > 0 && clock.height > 0
        source: glassFill
        autoPaddingEnabled: false
        maskEnabled: true
        maskSource: clockMask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 0.5
    }

    Rectangle {
        id: island

        readonly property int sidePadding: 12
        readonly property int iconWidth: 14
        readonly property int contentGap: 8
        readonly property real contentWidth: statusLabel.visible
            ? statusMetrics.advanceWidth : Math.min(password.length, 18) * bulletMetrics.advanceWidth
        readonly property bool expanded: password.length > 0 || root.status !== ""
        property real shakeOffset: 0

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: shakeOffset
        y: Math.round(root.height * 0.036) + (expanded ? 16 : 0)
        width: Math.min(Math.max(0, root.width - 16), 2 * sidePadding + iconWidth
            + (expanded ? contentGap + Math.ceil(contentWidth) + 1 : 0))
        height: expanded ? 34 : 24
        radius: height / 2
        color: Monochrome.background
        border.color: Monochrome.outline
        clip: true

        Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: 155; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        SequentialAnimation {
            id: shake

            NumberAnimation { target: island; property: "shakeOffset"; to: -6; duration: 45 }
            NumberAnimation { target: island; property: "shakeOffset"; to: 5; duration: 65 }
            NumberAnimation { target: island; property: "shakeOffset"; to: -3; duration: 55 }
            NumberAnimation { target: island; property: "shakeOffset"; to: 0; duration: 65 }
        }

        Text {
            id: lockIcon

            anchors.left: parent.left
            anchors.leftMargin: island.sidePadding
            anchors.verticalCenter: parent.verticalCenter
            width: island.iconWidth
            horizontalAlignment: Text.AlignHCenter
            text: "\uf023"
            color: Monochrome.accent
            font.family: "CaskaydiaCove Nerd Font"
            font.pixelSize: 13
        }

        TextMetrics {
            id: bulletMetrics
            font: password.font
            text: password.passwordCharacter
        }

        TextMetrics {
            id: statusMetrics
            font: statusLabel.font
            text: root.status
        }

        TextInput {
            id: password

            anchors.left: lockIcon.right
            anchors.leftMargin: island.contentGap
            anchors.right: parent.right
            anchors.rightMargin: island.sidePadding
            anchors.verticalCenter: parent.verticalCenter
            focus: true
            readOnly: root.busy
            echoMode: TextInput.Password
            passwordCharacter: "•"
            passwordMaskDelay: 0
            inputMethodHints: Qt.ImhHiddenText | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
            color: Monochrome.foreground
            font.family: Typography.family
            font.weight: Typography.weight
            font.pixelSize: 17
            cursorVisible: false
            clip: contentWidth > width
            opacity: statusLabel.visible ? 0 : 1

            onTextEdited: root.edited()
            onAccepted: {
                if (readOnly || !length)
                    return;
                root.submitted(text);
                clear();
            }
            onActiveFocusChanged: {
                if (!activeFocus)
                    clear();
            }

            Keys.onEscapePressed: {
                if (!root.busy) {
                    clear();
                    root.edited();
                }
            }
        }

        Text {
            id: statusLabel

            anchors.left: lockIcon.right
            anchors.leftMargin: island.contentGap
            anchors.right: parent.right
            anchors.rightMargin: island.sidePadding
            anchors.verticalCenter: parent.verticalCenter
            text: root.status
            visible: text !== ""
            elide: Text.ElideRight
            color: root.busy ? Monochrome.muted : Monochrome.error
            font.family: Typography.family
            font.weight: Typography.weight
            font.pixelSize: 13
        }
    }

    onStatusChanged: {
        if (status === "Incorrect password")
            shake.restart();
    }
}
