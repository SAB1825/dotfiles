import QtQuick
import QtQuick.Effects
import Ryu.Shell
import Ryu.Wayland as Wl
import px.configuration.Wallpaper
import px.components.menu
import px.components.clock

Variants {
    model: Screens.list

    Scope {
        id: screenScope

        required property var modelData

        // Niri places this copy behind the overview's workspace previews.
        Wl.WlrLayershell {
            namespace: "phoenix-overview-wallpaper"
            screen: screenScope.modelData
            layer: Wl.WlrLayer.Background
            exclusiveZone: -1
            color: "#101010"
            mask: Wl.Region {}

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Image {
                id: overviewWallpaper
                anchors.fill: parent
                source: WallpaperConfig.currentWallpaper
                sourceSize.width: 1280
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                visible: false
            }

            MultiEffect {
                anchors.fill: parent
                source: overviewWallpaper
                blurEnabled: true
                blurMax: 64
                blur: 1.0
                autoPaddingEnabled: false
                brightness: -0.12
            }
        }

        Wl.WlrLayershell {
            namespace: "phoenix-background"
            screen: screenScope.modelData
            layer: Wl.WlrLayer.Background
            exclusiveZone: -1
            color: "transparent"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Item {
                id: wall
                anchors.fill: parent
                clip: true

                property real mouseNorm: 0.5
                readonly property real imgAspect: wallpaper.implicitHeight > 0 ? wallpaper.implicitWidth / wallpaper.implicitHeight : 0
                readonly property bool pannable: imgAspect > (width / height) * 1.1

                HoverHandler {
                    onPointChanged: if (hovered && wall.width > 0)
                        wall.mouseNorm = Math.max(0, Math.min(1, point.position.x / wall.width))
                }

                Image {
                    id: wallpaper
                    height: wall.height
                    width: wall.pannable ? implicitWidth * (wall.height / implicitHeight) : wall.width
                    source: WallpaperConfig.currentWallpaper
                    sourceSize.height: wall.height
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    asynchronous: true
                    x: wall.pannable ? -(width - wall.width) * wall.mouseNorm : 0

                    Behavior on x {
                        enabled: wall.pannable

                        NumberAnimation {
                            duration: 400
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                HomeMenu {
                    anchors.fill: parent
                }
            }

            ConfiguredClock {}
        }
    }
}
