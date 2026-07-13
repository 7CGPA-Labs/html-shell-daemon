import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
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

            SwipeView {
                id: swipeView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                // Page 1: Core Apps Grid
                Item {
                    GridView {
                        id: grid1
                        anchors.fill: parent
                        anchors.margins: 4
                        cellWidth: parent.width / 2
                        cellHeight: 70
                        clip: true
                        model: ListModel {
                            ListElement {
                                appId: "home"
                                title: "Home"
                                subtitle: "Dashboard"
                                url: "about:blank"
                            }
                            ListElement {
                                appId: "files"
                                title: "Files"
                                subtitle: "File Viewer"
                                url: "https://example.com/mock-local-file-viewer"
                            }
                            ListElement {
                                appId: "settings"
                                title: "Settings"
                                subtitle: "Preferences"
                                url: "https://example.com/mock-settings"
                            }
                            ListElement {
                                appId: "calendar"
                                title: "Calendar"
                                subtitle: "Events"
                                url: "https://example.com/mock-calendar"
                            }
                        }
                        delegate: AppDrawerItem {
                            width: grid1.cellWidth - 8
                            theme: root.theme
                            label: title
                            subtitle: subtitle
                            property string localAppId: model.appId
                            property string localUrl: model.url
                            property string localTitle: model.title
                            onClicked: root.appLaunched(localAppId, localUrl, localTitle)
                        }
                    }
                }

                // Page 2: System Utilities / Extensions Grid
                Item {
                    GridView {
                        id: grid2
                        anchors.fill: parent
                        anchors.margins: 4
                        cellWidth: parent.width / 2
                        cellHeight: 70
                        clip: true
                        model: ListModel {
                            ListElement {
                                appId: "gemini"
                                title: "Gemini"
                                subtitle: "AI Search"
                                url: "https://gemini.google.com/app"
                            }
                            ListElement {
                                appId: "diagnostics"
                                title: "Diagnostics"
                                subtitle: "Sys Monitor"
                                url: ""
                            }
                        }
                        delegate: AppDrawerItem {
                            width: grid2.cellWidth - 8
                            theme: root.theme
                            label: title
                            subtitle: subtitle
                            property string localAppId: model.appId
                            property string localUrl: model.url
                            property string localTitle: model.title
                            onClicked: {
                                if (localAppId === "diagnostics") {
                                    root.closed();
                                }
                                root.appLaunched(localAppId, localUrl, localTitle);
                            }
                        }
                    }
                }
            }

            PageIndicator {
                id: indicator
                count: swipeView.count
                currentIndex: swipeView.currentIndex
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
