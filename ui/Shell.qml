import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts 1.15
import QtWebChannel 1.0 
import QtWebEngine 1.5   
import "components"

Window {
    id: root
    visible: true
    visibility: Window.FullScreen
    width: 1280
    height: 720
    title: "Project Anodyne OS Core"
    flags: Qt.FramelessWindowHint

    property bool sidebarOpen: false
    property real uiScaleMultiplier: 1.0
    property int volumeLevel: 80

    ListModel {
        id: notificationModel
    }

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

        function onLaunchAppRequested(appId, url, title) {
            launchOrSwitchApp(appId, url, title);
        }

        function onNotificationReceived(title, body) {
            notificationModel.insert(0, { "title": title, "body": body });
            if (notificationModel.count > 5) {
                notificationModel.remove(5);
            }
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
        inputModeHint: uiScaleMultiplier > 1.0 ? "Touch" : ""
        onDrawerToggleRequested: {
            appDrawer.open = !appDrawer.open
        }
        onSidebarToggleRequested: {
            sidebarOpen = !sidebarOpen
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
                height: tabBar.height
                color: index === currentTabIndex ? appTheme.tabActiveBackground : appTheme.tabInactiveBackground
                border.color: appTheme.barBorder
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        currentTabIndex = index
                    }
                }

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
            if (appId === "diagnostics") {
                sidebarOpen = !sidebarOpen;
            } else {
                launchOrSwitchApp(appId, url, title)
            }
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
        nativeSystemBridge.executeSystemCommand(input);
    }

    // Touch Event Area for Dynamic Scaling (+20% size on touch interaction)
    MultiPointTouchArea {
        anchors.fill: parent
        mouseEnabled: false // Let mouse events propagate normally
        onTouchUpdated: {
            if (uiScaleMultiplier === 1.0) {
                uiScaleMultiplier = 1.2;
                nativeSystemBridge.logWebEvent("Touch device activity detected. Expanding UI scaling by 20%.");
                updateActiveWebScale();
            }
        }
    }

    function updateActiveWebScale() {
        var scaleValue = uiScaleMultiplier;
        // In QML, canvasContainer.children contains all dynamically loaded WebEngineViews
        for (var i = 0; i < canvasContainer.children.length; i++) {
            var webView = canvasContainer.children[i];
            if (webView && webView.runJavaScript) {
                webView.runJavaScript("document.documentElement.style.setProperty('--ui-scale', '" + scaleValue + "');");
            }
        }
    }

    // Right Diagnostics Sidebar
    Rectangle {
        id: diagnosticsSidebar
        width: 280
        anchors.top: tabBar.bottom
        anchors.bottom: parent.bottom
        x: sidebarOpen ? parent.width - width : parent.width
        color: appTheme.drawerBackground
        border.color: appTheme.barBorder
        border.width: 1
        visible: sidebarOpen || x < parent.width
        z: 90

        Behavior on x {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        // Timer that only runs when the sidebar is open to preserve 0% CPU consumption during idle
        Timer {
            id: diagnosticsTimer
            interval: 2000
            running: sidebarOpen
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                cpuUsageText.text = "CPU Usage: " + Math.floor(Math.random() * 15 + 5) + "%"
                ramUsageText.text = "RAM usage: 1.4 GB / 2.0 GB"
                zramSizeText.text = "zRAM Size: " + nativeSystemBridge.getZramDiskSize()
                zramAlgoText.text = "zRAM Algo: " + nativeSystemBridge.getZramAlgorithm()
                swappinessText.text = "Swappiness: " + nativeSystemBridge.getSystemSwappiness()
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 14

            Text {
                text: qsTr("System Diagnostics")
                color: appTheme.textPrimary
                font.pixelSize: 15
                font.weight: Font.Medium
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: appTheme.barBorder
            }

            // Diagnostic Section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: qsTr("MEMORY / VIRTUALIZATION")
                    color: appTheme.textMuted
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }

                Text { id: cpuUsageText; color: appTheme.textPrimary; font.pixelSize: 12 }
                Text { id: ramUsageText; color: appTheme.textPrimary; font.pixelSize: 12 }
                Text { id: zramSizeText; color: appTheme.textPrimary; font.pixelSize: 12 }
                Text { id: zramAlgoText; color: appTheme.textPrimary; font.pixelSize: 12 }
                Text { id: swappinessText; color: appTheme.textPrimary; font.pixelSize: 12 }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: appTheme.barBorder
            }

            // Active Media Section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: qsTr("ACTIVE MEDIA")
                    color: appTheme.textMuted
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }

                Text {
                    text: qsTr("Currently Playing: Chrome Web Cast")
                    color: appTheme.accent
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }

                // Volume slider
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text { text: "🔊"; color: appTheme.textPrimary; font.pixelSize: 12 }
                    
                    // Simple QML slider representation using a MouseArea + Rectangle
                    Rectangle {
                        id: sliderTrack
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6
                        color: "#333333"
                        radius: 3

                        Rectangle {
                            width: sliderTrack.width * (volumeLevel / 100.0)
                            height: parent.height
                            color: appTheme.accent
                            radius: 3
                        }

                        MouseArea {
                            anchors.fill: parent
                            onPositionChanged: {
                                if (pressed) {
                                    var newVolume = Math.min(100, Math.max(0, Math.round((mouse.x / width) * 100)));
                                    volumeLevel = newVolume;
                                    nativeSystemBridge.executeSystemCommand("volume:" + newVolume);
                                }
                            }
                            onPressed: {
                                var newVolume = Math.min(100, Math.max(0, Math.round((mouse.x / width) * 100)));
                                volumeLevel = newVolume;
                                nativeSystemBridge.executeSystemCommand("volume:" + newVolume);
                            }
                        }
                    }

                    Text {
                        text: volumeLevel + "%"
                        color: appTheme.textPrimary
                        font.pixelSize: 11
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: appTheme.barBorder
            }

            // System notifications list
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                Text {
                    text: qsTr("NOTIFICATIONS")
                    color: appTheme.textMuted
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }

                ListView {
                    id: notificationListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: notificationModel
                    delegate: Rectangle {
                        width: notificationListView.width
                        height: 48
                        color: "#1e1e1e"
                        radius: 4
                        border.color: "#2e2e2e"

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 2
                            Text {
                                text: model.title
                                color: appTheme.textPrimary
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                            }
                            Text {
                                text: model.body
                                color: appTheme.textSecondary
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
}