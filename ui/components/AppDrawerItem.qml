import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root

    required property var theme
    property string label: ""
    property string subtitle: ""

    signal clicked()

    height: 52
    radius: theme.cornerRadius
    color: itemMa.pressed ? theme.cardBackground : "transparent"
    border.color: itemMa.containsMouse ? theme.barBorder : "transparent"
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        Rectangle {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            radius: theme.cornerRadius
            color: theme.cardBackground

            Text {
                anchors.centerIn: parent
                text: label.length > 0 ? label.charAt(0).toUpperCase() : "?"
                color: theme.textPrimary
                font.pixelSize: 14
                font.weight: Font.Medium
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: label
                color: theme.textPrimary
                font.pixelSize: 14
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: subtitle.length > 0
                text: subtitle
                color: theme.textMuted
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }
    }

    MouseArea {
        id: itemMa
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
