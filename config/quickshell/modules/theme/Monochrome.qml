pragma Singleton

import QtQuick
import qs.services

QtObject {
    function matugen(role: string, fallback: color): color {
        const value = Wallpaper.paletteColors[role]?.dark?.color;
        return typeof value === "string" && /^#[0-9a-f]{6}$/i.test(value) ? value : fallback;
    }

    readonly property color background: "#000000"
    readonly property color foreground: matugen("on_surface", "#eeeeee")
    readonly property color muted: matugen("on_surface_variant", "#b3b3b3")
    readonly property color accent: matugen("primary", "#ededed")
    readonly property color accentText: matugen("on_primary", "#000000")
    readonly property color selection: background
    readonly property color selectionText: accent
    readonly property color raised: background
    readonly property color outline: matugen("outline_variant", "#414141")
    readonly property color error: matugen("error", "#ffb4ab")
}
