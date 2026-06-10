import QtQuick 2.15
import QtQuick.Window 2.15
import QtWebChannel 1.0 
import QtWebEngine 1.5   

Window {
    id: root
    visible: true
    width: 1280
    height: 720
    title: "Project WebOS Appliance Core"
    flags: Qt.FramelessWindowHint

    // Base background dark styling
    Rectangle { anchors.fill: parent; color: "#0a0a0a" }

    // 1. C++ Signal Linker Proxy
    Connections {
        target: nativeSystemBridge
        
        // Modernized Qt 5.15 syntax avoids the deprecation warning
        function onLauncherToggleTriggered() {
            appLauncherDrawer.visible = !appLauncherDrawer.visible;
        }
    }

    WebChannel {
        id: shellIPCChannel
        Component.onCompleted: {
            shellIPCChannel.registerObject("sysContext", nativeSystemBridge);
        }
    }

    // 2. Hard Layer: System Top Bar Navigation
    Rectangle {
        id: topBar
        anchors.top: parent.top; width: parent.width; height: 45
        color: "#141414"; border.color: "#222222"; border.width: 1; z: 10

        Row {
            anchors.fill: parent; anchors.leftMargin: 15; anchors.rightMargin: 15; spacing: 20

            Rectangle {
                width: 30; height: 30; color: "#222222"; radius: 4
                anchors.verticalCenter: parent.verticalCenter
                Text { text: "☰"; color: "white"; anchors.centerIn: parent; font.pixelSize: 16 }
                MouseArea {
                    anchors.fill: parent
                    onClicked: nativeSystemBridge.executeSystemCommand("launcher")
                }
            }

            Text {
                text: "WebOS Appliance v1.0 | Connected Shell Backend"
                color: "#888888"; font.pixelSize: 14; font.bold: true; anchors.verticalCenter: parent.verticalCenter
            }
        }

        Text {
            anchors.right: parent.right; anchors.rightMargin: 15; anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(new Date(), "hh:mm AP"); color: "#ffffff"; font.pixelSize: 14
        }
    }

    // 3. Soft Layer Viewport: Primary Browser Application Canvas
    WebEngineView {
        id: mainBrowser
        anchors.top: topBar.bottom; anchors.bottom: parent.bottom; width: parent.width
        webChannel: shellIPCChannel
        url: "file://" + applicationDirPath + "/web-apps/homepage/index.html"

        onLoadingChanged: {
            if (loadRequest.status === WebEngineView.LoadSucceededStatus) {
                console.log("System Shell Context mounted web asset successfully.")
            }
        }
    }

    // 4. Hard Layer Overlays: Sliding Application Drawer (Launcher Overlay)
    Rectangle {
        id: appLauncherDrawer
        visible: false 
        anchors.top: topBar.bottom; anchors.bottom: parent.bottom
        width: 320; color: "#1a1a1a"; z: 50
        border.color: "#2b2b2b"; border.width: 1

        Column {
            anchors.fill: parent; anchors.margins: 20; spacing: 25

            Text {
                text: "APPLICATION DRAWER"; color: "#888888"
                font.pixelSize: 12; font.bold: true; font.letterSpacing: 1 // FIX applied here
            }

            Grid {
                columns: 2; spacing: 15; width: parent.width

                // Local Files PWA Shortcut
                Rectangle {
                    width: 130; height: 90; color: "#262626"; radius: 6; border.color: "#383838"
                    Column {
                        anchors.centerIn: parent; spacing: 8
                        Text { text: "📁"; font.pixelSize: 24; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: "File Viewer"; color: "white"; font.pixelSize: 12 }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            appLauncherDrawer.visible = false;
                            nativeSystemBridge.executeSystemCommand("files");
                        }
                    }
                }

                // Settings PWA Shortcut
                Rectangle {
                    width: 130; height: 90; color: "#262626"; radius: 6; border.color: "#383838"
                    Column {
                        anchors.centerIn: parent; spacing: 8
                        Text { text: "⚙️"; font.pixelSize: 24; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: "OS Settings"; color: "white"; font.pixelSize: 12 }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            appLauncherDrawer.visible = false;
                            nativeSystemBridge.executeSystemCommand("settings");
                        }
                    }
                }
            }
        }
    }

    // 5. Keyboard Search Trigger Mechanics (Spotlight Overlay)
    Shortcut {
        sequence: "Ctrl+Space"
        onActivated: {
            spotlightOverlay.visible = !spotlightOverlay.visible
            if (spotlightOverlay.visible) commandInput.forceActiveFocus()
            else commandInput.text = ""
        }
    }

    Rectangle {
        id: spotlightOverlay; visible: false; anchors.fill: parent; color: "#cc000000"; z: 100
        MouseArea { anchors.fill: parent; onClicked: { spotlightOverlay.visible = false; commandInput.text = ""; } }

        Rectangle {
            width: 600; height: 60; color: "#1f1f1f"; radius: 8; border.color: "#333333"; border.width: 1
            anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.top; anchors.topMargin: parent.height * 0.2

            TextInput {
                id: commandInput; anchors.fill: parent; anchors.margins: 15
                color: "#ffffff"; font.pixelSize: 20; verticalAlignment: TextInput.AlignVCenter; selectByMouse: true
                
                Text {
                    text: "Search or type a system command..."; color: "#666666"; font.pixelSize: 20
                    visible: !commandInput.text && !commandInput.activeFocus; anchors.verticalCenter: parent.verticalCenter
                }

                Keys.onReturnPressed: {
                    var query = commandInput.text.trim();
                    if (query.length === 0) return;
                    spotlightOverlay.visible = false; commandInput.text = "";
                    routeCommand(query);
                }
            }
        }
    }

    function routeCommand(input) {
        var lowerInput = input.toLowerCase();
        if (lowerInput === "files" || lowerInput === "settings") {
            nativeSystemBridge.executeSystemCommand(lowerInput);
            return;
        }
        var geminiUrl = "https://gemini.google.com/app?q=" + encodeURIComponent(input);
        mainBrowser.url = geminiUrl;
    }
}