pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import "../theme"

FocusScope {
    id: root

    required property font textFont
    readonly property real cornerRadius: 30
    readonly property font displayFont: Qt.font({
        family: "SF Compact Display",
        pixelSize: textFont.pixelSize,
        weight: Font.Medium
    })
    readonly property font bodyFont: Qt.font({
        family: "SF Compact Text",
        pixelSize: textFont.pixelSize - 2,
        weight: Font.Normal
    })
    readonly property font detailFont: Qt.font({
        family: "SF Compact Text",
        pixelSize: 12,
        weight: Font.Normal
    })
    signal dismissRequested()

    property bool open: false
    focus: open
    enabled: open

    property string searchQuery: ""
    property int selectedIndex: 0
    readonly property bool isSearching: searchQuery.trim() !== ""

    property var filteredApps: {
        var q = searchQuery.trim().toLowerCase(); // User's search text
        var vals = DesktopEntries.applications.values;

        if (q !== "") {
            // Filter apps that match the search
            return vals.filter(function (e) {
                if (e.name.toLowerCase().indexOf(q) !== -1) // App name
                    return true;
                if (e.genericName && e.genericName.toLowerCase().indexOf(q) !== -1) // Generic name
                    return true;
                for (var i = 0; i < e.keywords.length; i++) {
                    if (e.keywords[i].toLowerCase().indexOf(q) !== -1)
                        return true;
                }
                return false;
            }).sort(function (a, b) {
                return a.name.localeCompare(b.name);
            });
        }

        const recentIds = ApplauncherState.recentIds;
        const recentApps = recentIds.map(id => {
            return vals.find(entry => entry.id === id);
        }).filter(entry => entry !== undefined);
        const otherApps = vals.filter(entry => !recentIds.includes(entry.id))
            .sort((a, b) => a.name.localeCompare(b.name));
        return recentApps.concat(otherApps);
    }

    onFilteredAppsChanged: {
        resetSelection();
    }

    function resetSelection() {
        selectedIndex = 0;
        keyboardScroll.stop();
        listView.cancelFlick();
        listView.positionViewAtBeginning();
    }

    function launchEntry(entry) {
        if (!entry || (entry.runInTerminal && !entry.command.length))
            return;
        ApplauncherState.recordLaunch(entry.id);
        if (entry.runInTerminal) {
            Quickshell.execDetached({
                command: ["kitty", "--", ...entry.command],
                workingDirectory: entry.workingDirectory
            });
        } else {
            entry.execute();
        }
        root.dismissRequested();
    }

    function navigate(delta) {
        if (filteredApps.length === 0)
            return;
        selectedIndex = (selectedIndex + delta + filteredApps.length) % filteredApps.length;

        const top = listView.originY + selectedIndex * itemH;
        const bottom = top + itemH;
        const offset = keyboardScroll.running ? keyboardScroll.to : listView.contentY;
        const maxOffset = listView.originY + Math.max(0, listView.count * itemH - listView.height);
        const target = Math.min(maxOffset, Math.max(listView.originY,
            Math.min(top, Math.max(offset, bottom - listView.height))));
        if (target === offset)
            return;

        listView.cancelFlick();
        keyboardScroll.stop();
        if (Math.abs(target - listView.contentY) > listView.height) {
            listView.positionViewAtIndex(selectedIndex, ListView.Contain);
        } else {
            keyboardScroll.to = target;
            keyboardScroll.start();
        }
    }

    onOpenChanged: {
        if (open) {
            searchInput.clear();
            searchQuery = "";
            resetSelection();
            searchInput.forceActiveFocus();
        }
    }

    readonly property color foreground: Monochrome.foreground
    readonly property color secondary: Monochrome.muted
    readonly property int itemH: 47
    implicitWidth: 508
    readonly property int resultsHeight: isSearching && filteredApps.length === 0
        ? itemH : Math.min(filteredApps.length, 6) * itemH
    implicitHeight: 86 + resultsHeight

    Column {
        anchors {
            top: parent.top
            topMargin: 8
            left: parent.left
            leftMargin: 14
            right: parent.right
            rightMargin: 14
        }
        spacing: 0
        opacity: root.open ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }

        transform: Translate {
            y: root.open ? 0 : -6

            Behavior on y {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }
        }

        Item {
            width: parent.width
            height: 48

            Row {
                anchors {
                    fill: parent
                    rightMargin: 8
                }
                spacing: 10

                Item {
                    id: searchIcon
                    width: 18
                    height: 18
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        x: 1
                        y: 1
                        width: 12
                        height: 12
                        radius: width / 2
                        color: "transparent"
                        border.color: Monochrome.accent
                        border.width: 1
                    }

                    Rectangle {
                        x: 11
                        y: 11
                        width: 8
                        height: 2
                        radius: 1
                        color: Monochrome.accent
                        rotation: 45
                        transformOrigin: Item.Left
                    }
                }

                Item {
                    width: Math.max(0, parent.width - searchIcon.width - parent.spacing)
                    height: parent.height

                    Text {
                        anchors.fill: parent
                        text: "Search…"
                        color: root.secondary
                        font: root.bodyFont
                        verticalAlignment: Text.AlignVCenter
                        visible: searchInput.text === ""
                    }

                    TextInput {
                        id: searchInput
                        focus: true
                        anchors.fill: parent
                        color: root.foreground
                        selectionColor: Monochrome.accent
                        selectedTextColor: Monochrome.accentText
                        font: root.bodyFont
                        verticalAlignment: TextInput.AlignVCenter
                        clip: true

                        onTextChanged: root.searchQuery = text

                        Keys.onPressed: function (event) {
                            if (event.key === Qt.Key_Up) {
                                root.navigate(-1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down) {
                                root.navigate(1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                if (root.filteredApps.length > 0)
                                    root.launchEntry(root.filteredApps[root.selectedIndex]);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Escape) {
                                root.dismissRequested();
                                event.accepted = true;
                            }
                        }
                    }
                }
            }
        }

        Item { width: 1; height: 4 }

        Rectangle {
            width: parent.width
            height: 1
            color: Monochrome.outline
        }

        Item { width: 1; height: 10 }

        ListView {
            id: listView
            width: parent.width
            height: root.resultsHeight
            model: root.filteredApps
            clip: true
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds
            onMovementStarted: keyboardScroll.stop()

            NumberAnimation {
                id: keyboardScroll
                target: listView
                property: "contentY"
                duration: 160
                easing.type: Easing.OutCubic
            }

            add: Transition {
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 140
                    easing.type: Easing.OutCubic
                }
            }

            Text {
                anchors.centerIn: parent
                visible: opacity > 0
                text: "No apps found"
                color: root.foreground
                opacity: root.isSearching && root.filteredApps.length === 0 ? 1 : 0
                font: root.bodyFont

                Behavior on opacity {
                    NumberAnimation { duration: 120 }
                }
            }

            delegate: Item {
                id: appRow
                required property int index
                required property var modelData
                width: listView.width
                height: root.itemH

                readonly property bool sel: root.selectedIndex === appRow.index
                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: appRow.sel ? Monochrome.selection : "transparent"

                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3
                        height: 24
                        radius: 1.5
                        color: Monochrome.accent
                        visible: appRow.sel
                    }

                    Row {
                        id: resultContent
                        anchors {
                            fill: parent
                            leftMargin: 11
                            rightMargin: 8
                        }
                        spacing: 10

                        Rectangle {
                            id: appIconSlot
                            width: 34
                            height: 34
                            radius: 10
                            color: appRow.sel ? Monochrome.raised : Monochrome.background
                            anchors.verticalCenter: parent.verticalCenter

                            Image {
                                id: appIcon
                                anchors.centerIn: parent
                                width: 22
                                height: 22
                                source: appRow.modelData.icon
                                    ? Quickshell.iconPath(appRow.modelData.icon, true) : ""
                                fillMode: Image.PreserveAspectFit
                                mipmap: true
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: appIcon.status !== Image.Ready
                                text: appRow.modelData.name.charAt(0).toUpperCase()
                                font: root.displayFont
                                color: appRow.sel ? Monochrome.selectionText : root.foreground
                            }
                        }

                        // Name + subtitle
                        Column {
                            width: Math.max(0, resultContent.width - appIconSlot.width - resultContent.spacing)
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 0

                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: appRow.modelData.name
                                font: root.displayFont
                                color: appRow.sel ? Monochrome.selectionText : root.foreground
                            }

                            Text {
                                width: parent.width
                                visible: appRow.modelData.genericName !== ""
                                elide: Text.ElideRight
                                text: appRow.modelData.genericName
                                font: root.detailFont
                                color: appRow.sel ? Monochrome.selectionText : root.secondary
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                            if (!keyboardScroll.running)
                                root.selectedIndex = appRow.index;
                        }
                        onClicked: root.launchEntry(appRow.modelData)
                    }
                }
            }
        }

    }
}
