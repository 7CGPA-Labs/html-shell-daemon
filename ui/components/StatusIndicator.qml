import QtQuick 2.15
import QtQuick.Layouts 1.15

RowLayout {
    id: root

    required property var theme
    property string iconSource: ""
    property string label: ""

    spacing: 4

    Image {
        Layout.preferredWidth: theme.iconSize
        Layout.preferredHeight: theme.iconSize
        source: iconSource
        fillMode: Image.PreserveAspectFit
        smooth: true
        antialiasing: true
    }

    Text {
        visible: label.length > 0
        text: label
        color: theme.textSecondary
        font.pixelSize: 11
    }
}
