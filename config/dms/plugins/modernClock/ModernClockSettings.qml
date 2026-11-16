import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "modernClock"

    // A searchable font-family picker.
    //
    // This has to be an inline component rather than its own FontSetting.qml:
    // Quickshell loads plugin QML through a synthesized module namespace, so a
    // sibling file is not resolvable as a type ("FontSetting is not a type").
    //
    // The stock SelectionSetting builds its DankDropdown without
    // enableFuzzySearch, which makes a ~700 entry font list unusable, so this
    // drives DankDropdown directly. It follows the same settingKey /
    // loadValue() / findSettings() contract as the built-in setting components,
    // so PluginSettings reparents and reloads it like any other row.
    //
    // An empty stored value means "use the font bundled with the plugin".
    component FontSetting: Column {
        id: fontRow

        required property string settingKey
        required property string label
        property string description: ""
        property string defaultValue: ""
        property string value: defaultValue
        property string bundledLabel: "Bundled default"

        width: parent.width
        spacing: Theme.spacingS

        property bool isInitialized: false
        property var families: [bundledLabel]
        property bool enumerated: false

        // Qt.fontFamilies() walks the whole font database, so do it once and
        // off the initial binding pass.
        function enumerateFonts() {
            if (enumerated)
                return;
            const fonts = Qt.fontFamilies().filter(f => !f.startsWith("."));
            fonts.sort();
            fonts.unshift(bundledLabel);
            families = fonts;
            enumerated = true;
        }

        function loadValue() {
            const settings = findSettings();
            if (settings && settings.pluginService) {
                value = settings.loadValue(settingKey, defaultValue);
                isInitialized = true;
            }
        }

        function findSettings() {
            let item = parent;
            while (item) {
                if (item.saveValue !== undefined && item.loadValue !== undefined)
                    return item;
                item = item.parent;
            }
            return null;
        }

        onValueChanged: {
            if (!isInitialized)
                return;
            const settings = findSettings();
            if (settings)
                settings.saveValue(settingKey, value);
        }

        Component.onCompleted: {
            Qt.callLater(enumerateFonts);
            Qt.callLater(loadValue);
        }

        DankDropdown {
            width: parent.width
            text: fontRow.label
            description: fontRow.description
            enableFuzzySearch: true
            maxPopupHeight: 400
            options: fontRow.families
            currentValue: fontRow.value === "" ? fontRow.bundledLabel : fontRow.value
            onValueChanged: newValue => {
                fontRow.value = newValue === fontRow.bundledLabel ? "" : newValue;
            }
        }
    }

    // Register the bundled faces so they appear in the pickers below even when
    // the widget itself has not been placed on a desktop yet. FontLoader is not
    // an Item, so PluginSettings leaves these out of the visible column.
    FontLoader {
        source: Qt.resolvedUrl("fonts/Anurati.otf")
    }

    FontLoader {
        source: Qt.resolvedUrl("fonts/Poppins.ttf")
    }

    FontSetting {
        settingKey: "dayFontFamily"
        label: "Day Font"
        description: "Bundled default is Anurati, from this plugin's fonts folder"
        defaultValue: ""
    }

    FontSetting {
        settingKey: "bodyFontFamily"
        label: "Date & Time Font"
        description: "Bundled default is Poppins, from this plugin's fonts folder"
        defaultValue: ""
    }

    ToggleSetting {
        settingKey: "showDay"
        label: "Show Day"
        description: "The large day name line"
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "showDate"
        label: "Show Date"
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "showTime"
        label: "Show Time"
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "use24Hour"
        label: "24-Hour Format"
        description: "Off matches the original plasmoid (12-hour with AM/PM)"
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "showSeconds"
        label: "Show Seconds"
        description: "Updates the clock every second instead of every minute"
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "uppercase"
        label: "Uppercase Text"
        description: "Required for Anurati, which has no lowercase glyphs"
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "scaleWithWidget"
        label: "Scale With Widget Size"
        description: "Derive font sizes from the widget width using the original 72/19/19 proportions, ignoring the size sliders"
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "useThemeColors"
        label: "Use DMS Theme Colors"
        description: "Use the shell's text color and ignore the color pickers below"
        defaultValue: false
    }

    ColorSetting {
        settingKey: "dayColor"
        label: "Day Color"
        defaultValue: "#FFFFFF"
    }

    ColorSetting {
        settingKey: "dateColor"
        label: "Date Color"
        defaultValue: "#FFFFFF"
    }

    ColorSetting {
        settingKey: "timeColor"
        label: "Time Color"
        defaultValue: "#FFFFFF"
    }

    StringSetting {
        settingKey: "separator"
        label: "Separator Character"
        description: "Drawn on both sides of the time"
        placeholder: "-"
        defaultValue: "-"
    }

    StringSetting {
        settingKey: "dateFormat"
        label: "Date Format"
        description: "Qt date format string, e.g. dd MMM yyyy"
        placeholder: "dd MMM yyyy"
        defaultValue: "dd MMM yyyy"
    }

    SelectionSetting {
        settingKey: "alignment"
        label: "Alignment"
        options: [
            {
                label: "Left",
                value: "left"
            },
            {
                label: "Center",
                value: "center"
            },
            {
                label: "Right",
                value: "right"
            }
        ]
        defaultValue: "center"
    }

    SliderSetting {
        settingKey: "dayFontSize"
        label: "Day Font Size"
        defaultValue: 72
        minimum: 8
        maximum: 200
        unit: "px"
    }

    SliderSetting {
        settingKey: "bodyFontSize"
        label: "Date & Time Font Size"
        defaultValue: 19
        minimum: 6
        maximum: 80
        unit: "px"
    }

    SliderSetting {
        settingKey: "dayLetterSpacing"
        label: "Day Letter Spacing"
        defaultValue: 17
        minimum: 0
        maximum: 60
        unit: "px"
    }

    SliderSetting {
        settingKey: "dateLetterSpacing"
        label: "Date Letter Spacing"
        defaultValue: 3
        minimum: 0
        maximum: 30
        unit: "px"
    }

    SliderSetting {
        settingKey: "timeLetterSpacing"
        label: "Time Letter Spacing"
        defaultValue: 3
        minimum: 0
        maximum: 30
        unit: "px"
    }

    SliderSetting {
        settingKey: "shadowStrength"
        label: "Drop Shadow Strength"
        description: "Keeps the text readable over a bright wallpaper"
        defaultValue: 60
        minimum: 0
        maximum: 100
        unit: "%"
    }

    SliderSetting {
        settingKey: "backgroundOpacity"
        label: "Background Opacity"
        description: "0 keeps the widget fully transparent, like the original"
        defaultValue: 0
        minimum: 0
        maximum: 100
        unit: "%"
    }
}
