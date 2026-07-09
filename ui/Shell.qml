import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts 1.15
import QtWebChannel 1.0 
import QtWebEngine 1.5   
import "components"

Window {
    id: root
    visible: true
    width: 1280
    height: 720
    title: "Project Anodyne OS Core"
    flags: Qt.FramelessWindowHint

    // Base background styling
    Rectangle { anchors.fill: parent; color: appTheme.canvasBackground }

    // Root Theme instantiation
    Theme { id: appTheme }

    // 1. C++ Signal Linker Proxy
    Connections {
        target: nativeSystemBridge
        
        function onLauncherToggleTriggered() {
            appDrawer.open = !appDrawer.open;
        }

        // Intercept thread pool progressions and completion notices to update TopBar badge
        function onNativeJobProgressChanged(jobId, progress) {
            topBar.statusBadgeText = qsTr("Backup: ") + progress + "%"
            topBar.statusBadgeVisible = true
        }

        function onNativeJobFinished(jobId, success, message) {
            topBar.statusBadgeText = success ? qsTr("Backup Complete") : qsTr("Backup Failed")
            topBar.statusBadgeVisible = true
            badgeTimer.restart()
        }
    }

    Timer {
        id: badgeTimer
        interval: 4000
        repeat: false
        onTriggered: topBar.statusBadgeVisible = false
    }

    WebChannel {
        id: shellIPCChannel
        Component.onCompleted: {
            shellIPCChannel.registerObject("sysContext", nativeSystemBridge);
        }
    }

    // 2. Hard Layer: System Top Bar Navigation
    TopBar {
        id: topBar
        theme: appTheme
        anchors.top: parent.top
        width: parent.width
        drawerOpen: appDrawer.open
        onDrawerToggleRequested: {
            appDrawer.open = !appDrawer.open
        }
    }

    // 3. Tabbed Multitasking Bar
    Rectangle {
        id: tabBar
        anchors.top: topBar.bottom
        width: parent.width
        height: appTheme.tabHeight
        color: appTheme.barBackground
        
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: appTheme.barBorder
        }

        ListView {
            id: tabListView
            anchors.fill: parent
            orientation: ListView.Horizontal
            model: tabModel
            boundsBehavior: Flickable.StopAtBounds
            
            delegate: Rectangle {
                width: appTheme.tabWidth
                height: parent.height
                color: index === currentTabIndex ? appTheme.tabActiveBackground : appTheme.tabInactiveBackground
                border.color: appTheme.barBorder
                border.width: 1

                // Active tab top indicator strip
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 2
                    color: appTheme.tabActiveBorder
                    visible: index === currentTabIndex
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    spacing: 6

                    Text {
                        Layout.fillWidth: true
                        text: model.title
                        color: index === currentTabIndex ? appTheme.textPrimary : appTheme.textSecondary
                        font.pixelSize: 12
                        font.weight: index === currentTabIndex ? Font.Medium : Font.Normal
                        elide: Text.ElideRight
                    }

                    // Close Tab button
                    Rectangle {
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        radius: 8
                        color: closeMa.containsMouse ? "#2d2d2d" : "transparent"
                        visible: model.appId !== "home" // Home tab cannot be closed

                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            color: closeMa.containsMouse ? appTheme.textPrimary : appTheme.textMuted
                            font.pixelSize: 13
                            anchors.verticalCenterOffset: -1
                        }

                        MouseArea {
                            id: closeMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                closeTab(index)
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    propagateComposedEvents: true
                    onClicked: {
                        currentTabIndex = index
                    }
                }
            }
        }
    }

    // 4. Soft Layer Viewport: Dynamic Multitasking Browser Canvas
    Item {
        id: canvasContainer
        anchors.top: tabBar.bottom
        anchors.bottom: parent.bottom
        width: parent.width

        Repeater {
            model: tabModel
            delegate: WebEngineView {
                anchors.fill: parent
                visible: index === currentTabIndex
                webChannel: shellIPCChannel
                url: model.url

                onLoadingChanged: {
                    if (loadRequest.status === WebEngineView.LoadSucceededStatus) {
                        console.log("System Shell Context mounted web asset successfully: " + model.url)
                    }
                }
            }
        }
    }

    // 5. Hard Layer Overlays: Sliding Application Drawer
    AppDrawer {
        id: appDrawer
        theme: appTheme
        anchors.top: tabBar.bottom
        anchors.bottom: parent.bottom
        width: parent.width
        open: false
        onClosed: open = false
        onAppLaunched: {
            launchOrSwitchApp(appId, url, title)
        }
    }

    // 6. Keyboard Search Trigger Mechanics (Polished Spotlight Overlay)
    Shortcut {
        sequence: "Ctrl+Space"
        onActivated: {
            spotlightOpen = !spotlightOpen
            if (spotlightOpen) {
                commandInput.forceActiveFocus()
            } else {
                commandInput.text = ""
            }
        }
    }

    property bool spotlightOpen: false

    Rectangle {
        id: spotlightOverlay
        visible: opacity > 0
        opacity: spotlightOpen ? 1 : 0
        anchors.fill: parent
        color: "#cc000000"
        z: 100

        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                spotlightOpen = false
                commandInput.text = ""
            }
        }

        Rectangle {
            width: 600
            height: 60
            color: "#1a1a1a"
            radius: 8
            border.color: "#333333"
            border.width: 1
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: spotlightOpen ? parent.height * 0.2 : parent.height * 0.15

            Behavior on anchors.topMargin {
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }

            TextInput {
                id: commandInput
                anchors.fill: parent
                anchors.margins: 15
                color: "#ffffff"
                font.pixelSize: 20
                verticalAlignment: TextInput.AlignVCenter
                selectByMouse: true
                
                Text {
                    text: "Search or type a system command..."
                    color: "#666666"
                    font.pixelSize: 20
                    visible: !commandInput.text && !commandInput.activeFocus
                    anchors.verticalCenter: parent.verticalCenter
                }

                Keys.onReturnPressed: {
                    var query = commandInput.text.trim();
                    if (query.length === 0) return;
                    spotlightOpen = false;
                    commandInput.text = "";
                    routeCommand(query);
                }
            }
        }
    }

    // Tab switcher & App Registry controllers
    property int currentTabIndex: 0

    ListModel {
        id: tabModel
    }

    Component.onCompleted: {
        // Register the primary Home Dashboard
        tabModel.append({
            "appId": "home",
            "title": "Home Dashboard",
            "url": "file://" + applicationDirPath + "/web-apps/homepage/index.html"
        })
    }

    function launchOrSwitchApp(appId, url, title) {
        var resolvedUrl = url;
        if (appId === "files") {
            resolvedUrl = "file://" + applicationDirPath + "/web-apps/files/index.html";
        } else if (appId === "settings") {
            resolvedUrl = "file://" + applicationDirPath + "/web-apps/settings/index.html";
        } else if (appId === "home") {
            resolvedUrl = "file://" + applicationDirPath + "/web-apps/homepage/index.html";
        }

        // If the PWA is already open, just focus the tab
        for (var i = 0; i < tabModel.count; i++) {
            if (tabModel.get(i).appId === appId) {
                currentTabIndex = i;
                appDrawer.open = false;
                return;
            }
        }

        // Open as a new tab
        tabModel.append({
            "appId": appId,
            "title": title,
            "url": resolvedUrl
        });
        currentTabIndex = tabModel.count - 1;
        appDrawer.open = false;
    }

    function closeTab(index) {
        if (index === 0) return; // Prevent closing the home tab
        
        var selectedTabWasClosed = (index === currentTabIndex);
        tabModel.remove(index);
        
        if (selectedTabWasClosed) {
            currentTabIndex = Math.max(0, index - 1);
        } else if (currentTabIndex > index) {
            currentTabIndex--;
        }
    }

    function routeCommand(input) {
        var lowerInput = input.toLowerCase().trim();
        if (lowerInput === "files" || lowerInput === "file") {
            launchOrSwitchApp("files", "", "Files");
            return;
        }
        if (lowerInput === "settings" || lowerInput === "setting") {
            launchOrSwitchApp("settings", "", "Settings");
            return;
        }
        if (lowerInput === "home" || lowerInput === "dashboard") {
            launchOrSwitchApp("home", "", "Home");
            return;
        }

        // Redirect to external Gemini interface in a new tab
        var geminiUrl = "https://gemini.google.com/app?q=" + encodeURIComponent(input);
        var searchAppId = "gemini_" + Date.now();
        launchOrSwitchApp(searchAppId, geminiUrl, "Gemini: " + input);
    }
}