import QtQuick
import QtQuick.Controls.impl

IconImage {
    id: root

    required property string iconName

    name: root.iconName
    color: "white"
    width: 16
    height: 16
    sourceSize.width: width
    sourceSize.height: height
    fillMode: Image.PreserveAspectFit
    visible: status === Image.Ready
}
