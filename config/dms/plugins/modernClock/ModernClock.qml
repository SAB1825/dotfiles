import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Common
import qs.Modules.Plugins

DesktopPluginComponent {
    id: root

    // Natural size of the original plasmoid: a 72px Anurati day line
    // (~9 glyphs at 17px tracking) stacked over two 19px Poppins lines.
    minWidth: 220
    minHeight: 80
    property real defaultWidth: 640
    property real defaultHeight: 170

    readonly property bool showDay: pluginData.showDay ?? true
    readonly property bool showDate: pluginData.showDate ?? true
    readonly property bool showTime: pluginData.showTime ?? true

    readonly property bool use24Hour: pluginData.use24Hour ?? false
    readonly property bool showSeconds: pluginData.showSeconds ?? false
    readonly property bool uppercase: pluginData.uppercase ?? true

    readonly property string separator: pluginData.separator ?? "-"
    readonly property string dateFormat: pluginData.dateFormat ?? "dd MMM yyyy"
    readonly property string alignment: pluginData.alignment ?? "center"

    // ColorSetting round-trips a QML color through JSON, which serializes it as
    // an {r,g,b,a,...} object rather than a hex string (see desktopClockCustomColor
    // in settings.json). Accept either form so a picked color still applies.
    function toColor(value, fallback) {
        if (value === undefined || value === null)
            return fallback;
        if (typeof value === "string")
            return value.length > 0 ? value : fallback;
        if (typeof value === "object" && value.r !== undefined)
            return Qt.rgba(value.r, value.g, value.b, value.a ?? 1);
        return fallback;
    }

    readonly property bool useThemeColors: pluginData.useThemeColors ?? false
    readonly property color dayColor: useThemeColors ? Theme.surfaceText : toColor(pluginData.dayColor, "#FFFFFF")
    readonly property color dateColor: useThemeColors ? Theme.surfaceText : toColor(pluginData.dateColor, "#FFFFFF")
    readonly property color timeColor: useThemeColors ? Theme.surfaceText : toColor(pluginData.timeColor, "#FFFFFF")

    readonly property int shadowStrength: pluginData.shadowStrength ?? 60
    readonly property real backgroundOpacity: (pluginData.backgroundOpacity ?? 0) / 100

    // Scale mode: font sizes follow the widget width using the original
    // 72 / 19 / 19 proportions instead of the fixed slider values.
    readonly property bool scaleWithWidget: pluginData.scaleWithWidget ?? false
    readonly property real scaleReferenceWidth: 640
    readonly property real scaleFactor: scaleWithWidget ? Math.max(0.1, widgetWidth / scaleReferenceWidth) : 1

    readonly property real dayFontSize: scaleWithWidget ? 72 * scaleFactor : (pluginData.dayFontSize ?? 72)
    readonly property real bodyFontSize: scaleWithWidget ? 19 * scaleFactor : (pluginData.bodyFontSize ?? 19)
    readonly property real dayTracking: scaleWithWidget ? 17 * scaleFactor : (pluginData.dayLetterSpacing ?? 17)
    readonly property real dateTracking: scaleWithWidget ? 3 * scaleFactor : (pluginData.dateLetterSpacing ?? 3)
    readonly property real timeTracking: scaleWithWidget ? 3 * scaleFactor : (pluginData.timeLetterSpacing ?? 3)

    // Anurati is uppercase-only and personal-use licensed, so it is not
    // shipped with this plugin. Fall back to the DMS UI font if absent.
    FontLoader {
        id: anuratiFont
        source: Qt.resolvedUrl("fonts/Anurati.otf")
        onStatusChanged: {
            if (status === FontLoader.Error && root.dayFontFamily === "")
                console.warn("ModernClock: fonts/Anurati.otf could not be loaded - " + "falling back to the DMS UI font. Drop the file in, or pick a Day Font " + "in the plugin settings. See the plugin README.");
        }
    }

    FontLoader {
        id: poppinsFont
        source: Qt.resolvedUrl("fonts/Poppins.ttf")
        onStatusChanged: {
            if (status === FontLoader.Error)
                console.warn("ModernClock: fonts/Poppins.ttf could not be loaded - falling back to the DMS UI font.");
        }
    }

    // An explicit family chosen in the settings panel wins; otherwise fall back
    // to the bundled face, and to the DMS UI font if that file is missing.
    readonly property string dayFontFamily: pluginData.dayFontFamily ?? ""
    readonly property string bodyFontFamily: pluginData.bodyFontFamily ?? ""

    readonly property string dayFamily: {
        if (dayFontFamily !== "")
            return dayFontFamily;
        return anuratiFont.status === FontLoader.Ready ? anuratiFont.font.family : Theme.fontFamily;
    }
    readonly property string bodyFamily: {
        if (bodyFontFamily !== "")
            return bodyFontFamily;
        return poppinsFont.status === FontLoader.Ready ? poppinsFont.font.family : Theme.fontFamily;
    }

    SystemClock {
        id: systemClock
        precision: root.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    readonly property string timeFormat: {
        if (use24Hour)
            return showSeconds ? "hh:mm:ss" : "hh:mm";
        return showSeconds ? "hh:mm:ss AP" : "hh:mm AP";
    }

    function cased(text) {
        return root.uppercase ? text.toUpperCase() : text;
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: Theme.surfaceContainer
        opacity: root.backgroundOpacity
        visible: opacity > 0
    }

    Item {
        id: shadowSource
        anchors.fill: parent

        layer.enabled: root.shadowStrength > 0
        layer.effect: MultiEffect {
            shadowEnabled: true
            blurMax: 24
            shadowBlur: 1
            shadowColor: "#000000"
            shadowOpacity: root.shadowStrength / 100
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 2
            autoPaddingEnabled: false
        }

        Column {
            id: container

            spacing: 5 * root.scaleFactor

            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: root.alignment === "center" ? parent.horizontalCenter : undefined
            anchors.left: root.alignment === "left" ? parent.left : undefined
            anchors.right: root.alignment === "right" ? parent.right : undefined
            // Keep edge-aligned text off the widget bounds, or the shadow layer
            // (which is exactly the widget rect) clips the outermost glyphs.
            anchors.leftMargin: Theme.spacingS
            anchors.rightMargin: Theme.spacingS

            Text {
                id: dayText
                visible: root.showDay

                anchors.horizontalCenter: root.alignment === "center" ? parent.horizontalCenter : undefined
                anchors.left: root.alignment === "left" ? parent.left : undefined
                anchors.right: root.alignment === "right" ? parent.right : undefined

                text: root.cased(Qt.formatDate(systemClock.date, "dddd"))
                color: root.dayColor
                font.family: root.dayFamily
                font.pixelSize: root.dayFontSize
                font.letterSpacing: root.dayTracking
            }

            Text {
                id: dateText
                visible: root.showDate

                anchors.horizontalCenter: root.alignment === "center" ? parent.horizontalCenter : undefined
                anchors.left: root.alignment === "left" ? parent.left : undefined
                anchors.right: root.alignment === "right" ? parent.right : undefined

                text: root.cased(Qt.formatDate(systemClock.date, root.dateFormat))
                color: root.dateColor
                font.family: root.bodyFamily
                font.pixelSize: root.bodyFontSize
                font.letterSpacing: root.dateTracking
            }

            Text {
                id: timeText
                visible: root.showTime

                anchors.horizontalCenter: root.alignment === "center" ? parent.horizontalCenter : undefined
                anchors.left: root.alignment === "left" ? parent.left : undefined
                anchors.right: root.alignment === "right" ? parent.right : undefined

                text: root.cased(root.separator + " " + Qt.formatTime(systemClock.date, root.timeFormat) + " " + root.separator)
                color: root.timeColor
                font.family: root.bodyFamily
                font.pixelSize: root.bodyFontSize
                font.letterSpacing: root.timeTracking
            }
        }
    }
}
