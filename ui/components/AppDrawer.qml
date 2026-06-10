import QtQuick 2.15
import QtQuick.Layouts 1.15
import "."

Item {
    id: root

    required property var theme
    property bool open: false

    signal closed()
    signal appLaunched(string appId, string url, string title)

    readonly property int panelWidth: theme.drawerWidth

    visible: open || panel.x > -panelWidth
    enabled: open

    // Scrim over the web canvas
    Rectangle {
        anchors.fill: parent
        color: theme.drawerScrim
        opacity: open ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.closed()
        }
    }

    Rectangle {
        id: panel
        width: panelWidth
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        x: open ? 0 : -width
        color: theme.drawerBackground
        border.color: theme.barBorder
        border.width: 1

        Behavior on x {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Text {
                text: qsTr("Apps")
                color: theme.textPrimary
                font.pixelSize: 15
                font.weight: Font.Medium
            }

            Text {
                Layout.fillWidth: true
                text: qsTr("Launch an app over the web canvas")
                color: theme.textMuted
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: theme.barBorder
            }

            ListView {
                id: appList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 4
                boundsBehavior: Flickable.StopAtBounds

                model: ListModel {
                    ListElement {
                        appId: "home"
                        title: "Home"
                        subtitle: "Momentum dashboard"
                        url: "about:blank"
                    }
                    ListElement {
                        appId: "files"
                        title: "Files"
                        subtitle: "Local file viewer PWA"
                        url: "https://example.com/mock-local-file-viewer"
                    }
                    ListElement {
                        appId: "settings"
                        title: "Settings"
                        subtitle: "System preferences PWA"
                        url: "https://example.com/mock-settings"
                    }
                    ListElement {
                        appId: "calendar"
                        title: "Calendar"
                        subtitle: "Timeline and events PWA"
                        url: "https://example.com/mock-calendar"
                    }
                }

                delegate: AppDrawerItem {
                    width: appList.width
                    theme: root.theme
                    label: title
                    subtitle: subtitle
                    onClicked: root.appLaunched(appId, url, title)
                }
            }
        }
    }
}
