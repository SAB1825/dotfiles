import QtQuick
import Quickshell
import QtQuick.Controls.impl

IconImage {
    id: root

    required property string iconName

    name: root.iconName
    source: root.iconName === "" ? "" : "file://" + iconDataHome
        + "/icons/Tela-circle-dark/symbolic/status/" + root.iconName + ".svg"

    readonly property string iconDataHome: Quickshell.env("XDG_DATA_HOME")
        || Quickshell.env("HOME") + "/.local/share"
    color: "white"
    width: 16
    height: 16
    sourceSize.width: width
    sourceSize.height: height
    fillMode: Image.PreserveAspectFit
    visible: status === Image.Ready
}
