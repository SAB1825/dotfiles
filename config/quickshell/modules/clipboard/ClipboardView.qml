pragma ComponentBehavior: Bound

import QtQuick

FocusScope {
    id: root

    required property font textFont
    property bool open: false
    property int selectedIndex: 0
    readonly property real cornerRadius: 30
    readonly property color foreground: "#c8cde0"
    readonly property color secondary: "#898e9b"
    readonly property int rowHeight: 47
    readonly property var results: {
        const query = search.text.trim().toLowerCase();
        return ClipboardHistory.entries.filter(entry =>
            (entry.title + " " + entry.detail).toLowerCase().includes(query));
    }
    readonly property string status: ClipboardHistory.error || (!ClipboardHistory.loaded
        ? "Loading clipboard history…" : results.length === 0
        ? (search.text.trim() ? "No matching entries" : "Clipboard history is empty") : "")

    signal dismissRequested()

    implicitWidth: 508
    implicitHeight: 86 + Math.min(6, Math.max(1, results.length + (ClipboardHistory.error ? 1 : 0))) * rowHeight
    focus: open
    enabled: open
    opacity: open ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: 160
            easing.type: Easing.OutCubic
        }
    }

    onOpenChanged: {
        if (open) {
            search.clear();
            selectedIndex = 0;
            list.positionViewAtBeginning();
            search.forceActiveFocus();
            ClipboardHistory.refresh();
        }
    }

    onResultsChanged: {
        selectedIndex = 0;
        list.positionViewAtBeginning();
    }

    function navigate(delta) {
        if (results.length === 0)
            return;
        selectedIndex = (selectedIndex + delta + results.length) % results.length;
        list.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    Connections {
        target: ClipboardHistory
        function onCopied() {
            if (root.open)
                root.dismissRequested();
        }
    }

    Timer {
        interval: 1500
        repeat: true
        running: root.open
        onTriggered: ClipboardHistory.refresh()
    }

    Column {
        anchors {
            top: parent.top
            topMargin: 8
            left: parent.left
            leftMargin: 14
            right: parent.right
            rightMargin: 14
        }

        Item {
            width: parent.width
            height: 52

            Item {
                id: clipboardIcon
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 20
                height: 16

                Rectangle {
                    x: 2
                    y: 3
                    width: 10
                    height: 12
                    radius: 2
                    color: "transparent"
                    border.color: root.secondary
                }

                Rectangle {
                    x: 4
                    y: 1
                    width: 6
                    height: 4
                    radius: 1
                    color: root.secondary
                }
            }

            Text {
                anchors.fill: search
                verticalAlignment: Text.AlignVCenter
                text: "Search what you copied…"
                color: root.secondary
                font: search.font
                visible: !search.text
            }

            TextInput {
                id: search
                anchors {
                    left: clipboardIcon.right
                    leftMargin: 6
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                }
                color: root.foreground
                font.family: root.textFont.family
                font.pixelSize: 14
                verticalAlignment: Text.AlignVCenter
                clip: true
                focus: true

                Keys.onUpPressed: root.navigate(-1)
                Keys.onDownPressed: root.navigate(1)
                Keys.onEscapePressed: root.dismissRequested()
                onAccepted: ClipboardHistory.copy(root.results[root.selectedIndex])
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: "#222326"
        }

        Item { width: 1; height: 10 }

        Text {
            width: parent.width
            height: root.rowHeight
            visible: text !== ""
            text: root.status
            color: root.secondary
            font.family: root.textFont.family
            font.pixelSize: 13
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        ListView {
            id: list
            width: parent.width
            height: Math.min(root.results.length, ClipboardHistory.error ? 5 : 6) * root.rowHeight
            model: root.results
            clip: true
            cacheBuffer: 0

            delegate: Rectangle {
                id: row
                required property int index
                required property var modelData
                readonly property bool selected: root.selectedIndex === index

                width: list.width
                height: root.rowHeight
                radius: 10
                color: selected ? "#26282d" : "transparent"

                Rectangle {
                    anchors.left: parent.left
                    anchors.leftMargin: 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: 3
                    height: 24
                    radius: 1.5
                    color: "#99d9d6"
                    visible: row.selected
                }

                Row {
                    id: rowContent
                    anchors {
                        fill: parent
                        leftMargin: 11
                        rightMargin: 11
                    }
                    spacing: 10

                    Loader {
                        id: preview
                        active: root.open && row.modelData.format !== ""
                        visible: active
                        width: 60
                        height: 34
                        anchors.verticalCenter: parent.verticalCenter

                        sourceComponent: ClipboardThumbnail { entry: row.modelData }
                    }

                    Column {
                        width: Math.max(0, rowContent.width - (preview.visible ? preview.width + rowContent.spacing : 0))
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: row.modelData.title
                            textFormat: Text.PlainText
                            color: root.foreground
                            font.family: root.textFont.family
                            font.pixelSize: 14
                            font.weight: Font.Medium
                        }

                        Text {
                            width: parent.width
                            visible: text !== ""
                            elide: Text.ElideRight
                            text: row.modelData.detail
                            textFormat: Text.PlainText
                            color: root.secondary
                            font.family: root.textFont.family
                            font.pixelSize: 12
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.selectedIndex = row.index
                    onClicked: ClipboardHistory.copy(row.modelData)
                }
            }
        }
    }
}
