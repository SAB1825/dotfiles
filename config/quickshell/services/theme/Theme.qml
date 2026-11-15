pragma Singleton

import QtQuick
import Ryu.Io
import px.configuration.Wallpaper
import px.services.paths
import px.services.state

QtObject {
    id: root

    property string mode: StateService.get("mode", "dark")
    property string scheme: StateService.get("scheme", "scheme-content")
    property string lastText: ""
    property bool queued: false
    readonly property bool isDark: mode === "dark"

    property var md3: ({"background": "#14131b", "on_background": "#e7e0ec", "error": "#ffb4ab", "on_error": "#690005", "primary": "#c3c0ff", "on_primary": "#2c2860", "surface": "#14131b", "surface_dim": "#14131b", "surface_bright": "#3b3843", "surface_variant": "#494553", "surface_tint": "#c3c0ff", "surface_container_lowest": "#0f0e16", "surface_container_low": "#1c1b24", "surface_container": "#211f29", "surface_container_high": "#2b2933", "surface_container_highest": "#36343e", "on_surface": "#e7e0ec", "on_surface_variant": "#cac4d0", "outline": "#948e9c", "outline_variant": "#494553", "primary_container": "#433e78", "on_primary_container": "#e5deff", "inverse_primary": "#cac4d0", "secondary": "#c8c2dc", "on_secondary": "#312e41", "secondary_container": "#484459", "on_secondary_container": "#e4dff9", "tertiary": "#edb8cc", "on_tertiary": "#482536", "tertiary_container": "#613b4d", "on_tertiary_container": "#ffd8e7", "error_container": "#93000a", "on_error_container": "#ffdad6", "inverse_surface": "#e7e0ec", "inverse_on_surface": "#322f39", "scrim": "#cac4d0", "shadow": "#000000"})
    property var palette: ({})
    property var base16: ({})

    readonly property color background: md3.background ?? "transparent"
    readonly property color onBackgroundColor: md3.on_background ?? "transparent"
    readonly property color error: md3.error ?? "transparent"
    readonly property color onErrorColor: md3.on_error ?? "transparent"
    readonly property color primary: md3.primary ?? "transparent"
    readonly property color onPrimaryColor: md3.on_primary ?? "transparent"
    readonly property color surface: md3.surface ?? "transparent"
    readonly property color surfaceDim: md3.surface_dim ?? "transparent"
    readonly property color surfaceBright: md3.surface_bright ?? "transparent"
    readonly property color surfaceVariant: md3.surface_variant ?? "transparent"
    readonly property color surfaceTint: md3.surface_tint ?? "transparent"
    readonly property color surfaceContainerLowest: md3.surface_container_lowest ?? "transparent"
    readonly property color surfaceContainerLow: md3.surface_container_low ?? "transparent"
    readonly property color surfaceContainer: md3.surface_container ?? "transparent"
    readonly property color surfaceContainerHigh: md3.surface_container_high ?? "transparent"
    readonly property color surfaceContainerHighest: md3.surface_container_highest ?? "transparent"
    readonly property color onSurfaceColor: md3.on_surface ?? "transparent"
    readonly property color onSurfaceVariantColor: md3.on_surface_variant ?? "transparent"
    readonly property color outline: md3.outline ?? "transparent"
    readonly property color outlineVariant: md3.outline_variant ?? "transparent"
    readonly property color primaryContainer: md3.primary_container ?? "transparent"
    readonly property color onPrimaryContainerColor: md3.on_primary_container ?? "transparent"
    readonly property color inversePrimary: md3.inverse_primary ?? "transparent"
    readonly property color secondary: md3.secondary ?? "transparent"
    readonly property color onSecondaryColor: md3.on_secondary ?? "transparent"
    readonly property color secondaryContainer: md3.secondary_container ?? "transparent"
    readonly property color onSecondaryContainerColor: md3.on_secondary_container ?? "transparent"
    readonly property color tertiary: md3.tertiary ?? "transparent"
    readonly property color onTertiaryColor: md3.on_tertiary ?? "transparent"
    readonly property color tertiaryContainer: md3.tertiary_container ?? "transparent"
    readonly property color onTertiaryContainerColor: md3.on_tertiary_container ?? "transparent"
    readonly property color errorContainer: md3.error_container ?? "transparent"
    readonly property color onErrorContainerColor: md3.on_error_container ?? "transparent"
    readonly property color inverseSurface: md3.inverse_surface ?? "transparent"
    readonly property color inverseOnSurfaceColor: md3.inverse_on_surface ?? "transparent"
    readonly property color scrim: md3.scrim ?? "transparent"
    readonly property color shadow: md3.shadow ?? "transparent"

    readonly property var schemes: ["scheme-content", "scheme-expressive", "scheme-fidelity", "scheme-fruit-salad", "scheme-monochrome", "scheme-neutral", "scheme-rainbow", "scheme-tonal-spot"]

    function setScheme(s) {
        if (s === scheme)
            return;
        scheme = s;
        StateService.set("scheme", s);
        generate();
    }

    function setMode(newMode) {
        if (newMode !== "light" && newMode !== "dark")
            return;
        if (newMode === mode)
            return;
        mode = newMode;
        StateService.set("mode", newMode);
        generate();
    }

    function toggleMode() {
        return setMode(isDark ? "light" : "dark");
    }

    function generate() {
        if (matugen.running) {
            root.queued = true;
            return;
        }
        const src = decodeURIComponent(WallpaperConfig.currentWallpaper.toString().replace("file://", ""));
        matugen.command = ["python3", Qt.resolvedUrl("../../scripts/theme.py").toString().replace("file://", ""), src, root.mode, root.scheme];
        matugen.running = true;
    }

    property Process matugen: Process {
        onRunningChanged: {
            if (!running && root.queued) {
                root.queued = false;
                root.generate();
            }
        }
    }

    Component.onCompleted: generate()

    property Timer reloadTimer: Timer {
        interval: 50
        onTriggered: root.colorsFile.reload()
    }

    property FileView colorsFile: FileView {
        path: PathService.home + "/.local/state/ryu/colors.json"
        watchChanges: true

        onFileChanged: root.reloadTimer.restart()
        onLoadFailed: err => console.log("error loading file: ", err)

        onLoaded: {
            const raw = text();
            if (raw.trim() === "" || raw === root.lastText)
                return;
            let data;
            try {
                data = JSON.parse(raw);
            } catch (e) {
                console.log("parsing error: ", e);
                return;
            }
            root.lastText = raw;
            root.md3 = data.md3 ?? {};
            root.palette = data.palette ?? {};
            root.base16 = data.base16 ?? {};
        }
    }
}
