import QtQuick 2.15
import QtQuick.Layouts 1.15
import "components"

Rectangle {
    id: root

    required property var theme

    signal drawerToggleRequested()
    signal sidebarToggleRequested()

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
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 16

        // macOS Apple-like Logo (App Drawer Launcher)
        Text {
            text: "⬡"
            color: theme.textPrimary
            font.pixelSize: 15
            font.weight: Font.Bold
            opacity: logoMa.containsMouse ? 0.8 : 1.0

            MouseArea {
                id: logoMa
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.drawerToggleRequested()
            }
        }

        // Active Application Menu System
        Text {
            text: "Anodyne"
            color: theme.textPrimary
            font.pixelSize: 12
            font.weight: Font.Bold
        }

        Text {
            text: "File"
            color: theme.textSecondary
            font.pixelSize: 12
            opacity: fmMa.containsMouse ? 0.8 : 1.0
            MouseArea { id: fmMa; anchors.fill: parent; hoverEnabled: true }
        }

        Text {
            text: "Edit"
            color: theme.textSecondary
            font.pixelSize: 12
            opacity: edMa.containsMouse ? 0.8 : 1.0
            MouseArea { id: edMa; anchors.fill: parent; hoverEnabled: true }
        }

        Text {
            text: "View"
            color: theme.textSecondary
            font.pixelSize: 12
            opacity: vwMa.containsMouse ? 0.8 : 1.0
            MouseArea { id: vwMa; anchors.fill: parent; hoverEnabled: true }
        }

        Text {
            text: "Go"
            color: theme.textSecondary
            font.pixelSize: 12
            opacity: goMa.containsMouse ? 0.8 : 1.0
            MouseArea { id: goMa; anchors.fill: parent; hoverEnabled: true }
        }

        Text {
            text: "Window"
            color: theme.textSecondary
            font.pixelSize: 12
            opacity: wdMa.containsMouse ? 0.8 : 1.0
            MouseArea { id: wdMa; anchors.fill: parent; hoverEnabled: true }
        }

        Text {
            text: "Help"
            color: theme.textSecondary
            font.pixelSize: 12
            opacity: hpMa.containsMouse ? 0.8 : 1.0
            MouseArea { id: hpMa; anchors.fill: parent; hoverEnabled: true }
        }

        Item { Layout.fillWidth: true }

        // Center / Right Status Tray & Clock
        RowLayout {
            spacing: 12

            RowLayout {
                visible: inputModeHint.length > 0
                spacing: 4

                Image {
                    Layout.preferredWidth: theme.iconSize
                    Layout.preferredHeight: theme.iconSize
                    source: theme.iconTouch
                    fillMode: Image.PreserveAspectFit
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

            // macOS Notification/Control Center icon
            TopBarIcon {
                theme: root.theme
                iconSource: theme.iconNotification
                accessibleName: qsTr("Control Center")
                onClicked: root.sidebarToggleRequested()
            }

            // macOS far-right clock
            Text {
                id: clockLabel
                text: Qt.formatDateTime(new Date(), "ddd MMM d  H:mm")
                color: theme.textPrimary
                font.pixelSize: 12
                font.weight: Font.Medium
            }

            Timer {
                interval: 1000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: clockLabel.text = Qt.formatDateTime(new Date(), "ddd MMM d  H:mm")
            }
        }
    }
}
