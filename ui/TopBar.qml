import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import "components"

Rectangle {
    id: root

    required property var theme

    signal drawerToggleRequested()
    signal sidebarToggleRequested()
    signal lockRequested()
    signal menuActionTriggered(string category, string item)

    property bool drawerOpen: false
    property string calendarSummary: qsTr("No upcoming events")
    property bool statusBadgeVisible: false
    property string statusBadgeText: ""
    property string networkStatus: qsTr("WiFi")
    property string powerStatus: qsTr("100%")

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

        Repeater {
            model: nativeSystemBridge.activeAppMenus
            delegate: Text {
                text: modelData.category
                color: theme.textSecondary
                font.pixelSize: 12
                font.weight: Font.Medium
                opacity: menuMa.containsMouse ? 0.8 : 1.0
                
                MouseArea {
                    id: menuMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        topBarMenuPopup.showMenu(parent, modelData.category, modelData.items)
                    }
                }
            }
        }

        RowLayout {
            spacing: 16
            visible: nativeSystemBridge.activeAppMenus.length === 0

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
        }

        Item { Layout.fillWidth: true }

        // Center / Right Status Tray & Clock
        RowLayout {
            spacing: 12



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

            // Lock Screen Button
            Text {
                text: "🔒"
                color: theme.textSecondary
                font.pixelSize: 13
                Layout.alignment: Qt.AlignVCenter
                opacity: lockMa.containsMouse ? 0.7 : 1.0
                MouseArea {
                    id: lockMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.lockRequested()
                }
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

    Menu {
        id: topBarMenuPopup
        title: "App Menu"

        background: Rectangle {
            color: "#12121a"
            border.color: "#2a2a3a"
            border.width: 1
            radius: 6
        }

        property string currentCategory: ""
        property var itemsModel: []

        function showMenu(parentItem, category, items) {
            currentCategory = category;
            itemsModel = items;
            repeater.model = 0;
            repeater.model = items;
            popup(parentItem, 0, parentItem.height);
        }

        Repeater {
            id: repeater
            delegate: MenuItem {
                text: modelData

                contentItem: Text {
                    text: parent.text
                    color: parent.hovered ? "#ffffff" : "#e2e8f0"
                    font.pixelSize: 11
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    color: parent.hovered ? "#3584e4" : "transparent"
                    radius: 4
                }

                onTriggered: {
                    root.menuActionTriggered(topBarMenuPopup.currentCategory, text);
                }
            }
        }
    }
}
