import QtQuick 2.15

Item {
    id: root

    required property var theme
    property string iconSource: ""
    property bool active: false
    property string accessibleName: ""

    signal clicked()

    implicitWidth: theme.iconSize + 8
    implicitHeight: theme.iconSize + 8

    Rectangle {
        anchors.fill: parent
        radius: theme.cornerRadius
        color: active ? theme.cardBackground : "transparent"
        border.color: active ? theme.barBorder : "transparent"
        border.width: 1
    }

    Image {
        anchors.centerIn: parent
        width: theme.iconSize
        height: theme.iconSize
        source: iconSource
        fillMode: Image.PreserveAspectFit
        smooth: true
        antialiasing: true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
