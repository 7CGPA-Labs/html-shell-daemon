import QtQuick 2.15
import QtQuick.Layouts 1.15
import "components"

Rectangle {
    id: root

    required property var theme

    signal drawerToggleRequested()

    property bool drawerOpen: false
    property string calendarSummary: qsTr("No upcoming events")
    property bool statusBadgeVisible: false
    property string statusBadgeText: ""
    property string networkStatus: qsTr("WiFi")
    property string powerStatus: qsTr("100%")
    property string inputModeHint: ""

    height: theme.barHeight
    color: theme.barBackground

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: theme.barBorder
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: theme.barPadding
        anchors.rightMargin: theme.barPadding
        spacing: theme.itemSpacing

        TopBarIcon {
            theme: root.theme
            iconSource: theme.iconDrawer
            active: drawerOpen
            accessibleName: qsTr("App Launcher")
            onClicked: root.drawerToggleRequested()
        }

        RowLayout {
            spacing: 6

            Image {
                Layout.preferredWidth: theme.iconSize
                Layout.preferredHeight: theme.iconSize
                source: theme.iconCalendar
                fillMode: Image.PreserveAspectFit
                smooth: true
                antialiasing: true
            }

            Text {
                Layout.maximumWidth: 200
                elide: Text.ElideRight
                text: calendarSummary
                color: theme.textSecondary
                font.pixelSize: 12
            }
        }

        Item { Layout.fillWidth: true }

        Text {
            id: clockLabel
            text: Qt.formatTime(new Date(), "HH:mm")
            color: theme.textPrimary
            font.pixelSize: 13
            font.weight: Font.Medium
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: clockLabel.text = Qt.formatTime(new Date(), "HH:mm")
        }

        Rectangle {
            visible: statusBadgeVisible && statusBadgeText.length > 0
            Layout.preferredHeight: 22
            Layout.preferredWidth: Math.min(statusBadgeRow.implicitWidth + 12, 280)
            radius: theme.cornerRadius
            color: theme.badgeBackground

            RowLayout {
                id: statusBadgeRow
                anchors.centerIn: parent
                spacing: 6

                Image {
                    Layout.preferredWidth: theme.iconSize
                    Layout.preferredHeight: theme.iconSize
                    source: theme.iconNotification
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    antialiasing: true
                }

                Text {
                    Layout.maximumWidth: 220
                    elide: Text.ElideRight
                    text: statusBadgeText
                    color: theme.badgeText
                    font.pixelSize: 11
                }
            }
        }

        RowLayout {
            spacing: 10

            RowLayout {
                visible: inputModeHint.length > 0
                spacing: 4

                Image {
                    Layout.preferredWidth: theme.iconSize
                    Layout.preferredHeight: theme.iconSize
                    source: theme.iconTouch
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    antialiasing: true
                }

                Text {
                    text: inputModeHint
                    color: theme.accent
                    font.pixelSize: 11
                }
            }

            StatusIndicator {
                theme: root.theme
                iconSource: theme.iconWifi
                label: networkStatus
            }

            StatusIndicator {
                theme: root.theme
                iconSource: theme.iconBattery
                label: powerStatus
            }
        }
    }
}
