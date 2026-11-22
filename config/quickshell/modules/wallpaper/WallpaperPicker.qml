pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs.services
import "../theme"

FocusScope {
    id: root

    required property font textFont
    property bool open: false
    signal dismissRequested()

    readonly property int cornerRadius: 30
    readonly property color foreground: Monochrome.foreground
    readonly property color secondary: Monochrome.muted
    readonly property string query: search.text.trim().toLowerCase()
    readonly property var results: query
        ? Wallpaper.entries.filter(entry => entry.searchText.includes(query))
        : Wallpaper.entries
    readonly property var selected: results[strip.currentIndex] ?? null

    implicitWidth: 1000
    implicitHeight: 270
    enabled: open
    focus: open
    opacity: open ? 1 : 0

    Behavior on opacity {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
    }

    function selectCurrent() {
        const currentIndex = results.findIndex(entry => entry.path === Wallpaper.currentPath);
        strip.currentIndex = results.length ? Math.max(0, currentIndex) : -1;
        if (strip.currentIndex >= 0)
            strip.positionViewAtIndex(strip.currentIndex, ListView.Center);
    }

    function navigate(delta) {
        if (results.length)
            strip.currentIndex = Math.max(0, Math.min(results.length - 1, strip.currentIndex + delta));
    }

    function applySelection() {
        if (selected && !Wallpaper.busy)
            Wallpaper.apply(selected.path);
    }

    onResultsChanged: Qt.callLater(root.selectCurrent)

    onOpenChanged: {
        if (open) {
            search.clear();
            Wallpaper.refresh();
            Qt.callLater(() => {
                if (root.open) {
                    root.selectCurrent();
                    search.forceActiveFocus();
                }
            });
        }
    }

    Connections {
        target: Wallpaper
        function onApplied(path) {
            if (root.open && root.selected?.path === path)
                root.dismissRequested();
        }
    }

    Item {
        id: header
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: 12
            leftMargin: 18
            rightMargin: 18
        }
        height: 44

        Text {
            id: searchIcon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "\uf002"
            color: root.secondary
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 15
        }

        Text {
            id: folderLabel
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(180, parent.width / 4)
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideLeft
            text: root.selected ? root.selected.folder : ""
            textFormat: Text.PlainText
            color: root.secondary
            font.family: root.textFont.family
            font.weight: root.textFont.weight
            font.pixelSize: 12
        }

        TextInput {
            id: search
            anchors {
                left: searchIcon.right
                right: folderLabel.left
                leftMargin: 10
                rightMargin: 12
                verticalCenter: parent.verticalCenter
            }
            color: root.foreground
            selectionColor: root.foreground
            selectedTextColor: Monochrome.background
            font.family: root.textFont.family
            font.weight: root.textFont.weight
            font.pixelSize: 15
            clip: true
            focus: true
            Accessible.name: "Search wallpapers"

            Keys.onEscapePressed: root.dismissRequested()
            Keys.onReturnPressed: root.applySelection()
            Keys.onEnterPressed: root.applySelection()
            Keys.onPressed: event => {
                if (event.modifiers !== Qt.NoModifier)
                    return;
                if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
                    root.navigate(event.key === Qt.Key_Left ? -1 : 1);
                    event.accepted = true;
                }
            }

            Text {
                anchors.fill: parent
                text: "Search wallpapers…"
                visible: search.text === ""
                color: root.secondary
                font: search.font
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: Monochrome.outline
        }
    }

    ListView {
        id: strip
        anchors {
            top: header.bottom
            bottom: footer.top
            left: parent.left
            right: parent.right
            margins: 12
        }
        orientation: ListView.Horizontal
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        snapMode: ListView.SnapToItem
        highlightRangeMode: ListView.StrictlyEnforceRange
        highlightMoveDuration: 220
        highlightMoveVelocity: -1
        preferredHighlightBegin: (width - slotWidth) / 2
        preferredHighlightEnd: preferredHighlightBegin + slotWidth
        cacheBuffer: 200
        model: root.results

        readonly property real slotWidth: Math.min(220, Math.max(100, width / 4.6))

        delegate: Item {
            id: slot
            required property int index
            required property var modelData
            readonly property int distance: Math.abs(index - strip.currentIndex)
            readonly property bool selected: distance === 0
            readonly property bool applied: modelData.path === Wallpaper.currentPath

            width: strip.slotWidth
            height: strip.height

            ClippingRectangle {
                anchors.centerIn: parent
                width: Math.max(0, Math.min(slot.width - 12, slot.height * 1.65))
                height: width / 1.65
                radius: 15
                color: Monochrome.background
                border.width: slot.selected ? 1 : 0
                border.color: Monochrome.accent
                scale: slot.selected ? 1 : slot.distance === 1 ? 0.76 : 0.66
                opacity: slot.selected ? 1 : slot.distance === 1 ? 0.7 : 0.38

                Behavior on scale {
                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                }

                Behavior on opacity {
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }

                Image {
                    anchors.fill: parent
                    source: slot.modelData.url
                    sourceSize.width: 440
                    sourceSize.height: 270
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                Rectangle {
                    visible: slot.applied
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 10
                    width: 8
                    height: 8
                    radius: 4
                    color: Monochrome.foreground
                }
            }

            TapHandler {
                onTapped: {
                    if (slot.selected)
                        root.applySelection();
                    else
                        strip.currentIndex = slot.index;
                }
            }
        }

        WheelHandler {
            target: null
            orientation: Qt.Vertical
            onWheel: event => {
                if (event.angleDelta.y !== 0)
                    root.navigate(event.angleDelta.y < 0 ? 1 : -1);
            }
        }
    }

    Text {
        anchors.centerIn: strip
        visible: root.results.length === 0
        text: Wallpaper.scanning ? "Loading wallpapers…" : Wallpaper.scanError
            || (root.query ? "No matching wallpapers" : "No images in ~/Pictures/Wallpapers")
        color: root.secondary
        font.family: root.textFont.family
        font.weight: root.textFont.weight
        font.pixelSize: 14
    }

    Row {
        id: footer
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            bottomMargin: 16
            leftMargin: 22
            rightMargin: 22
        }
        height: 20
        spacing: 12

        Text {
            width: Math.max(0, footer.width - counter.width - footer.spacing)
            anchors.verticalCenter: parent.verticalCenter
            text: Wallpaper.busy ? "Applying wallpaper…" : Wallpaper.applyError || root.selected?.name || ""
            textFormat: Text.PlainText
            elide: Text.ElideRight
            color: root.secondary
            font.family: root.textFont.family
            font.weight: root.textFont.weight
            font.pixelSize: 12
        }

        Text {
            id: counter
            anchors.verticalCenter: parent.verticalCenter
            visible: root.selected !== null
            text: (strip.currentIndex + 1) + "/" + root.results.length
            color: root.secondary
            font.family: root.textFont.family
            font.weight: root.textFont.weight
            font.pixelSize: 12
        }
    }
}
