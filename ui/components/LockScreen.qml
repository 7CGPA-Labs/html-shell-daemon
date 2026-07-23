import QtQuick 2.15
import QtQuick.Layouts 1.15

Item {
    id: lockRoot
    anchors.fill: parent
    z: 1000 // Cover everything

    property string targetPin: "1234"
    property string enteredPin: ""
    property bool isLocked: false

    signal unlocked()

    opacity: isLocked ? 1.0 : 0.0
    visible: opacity > 0.0

    Behavior on opacity {
        NumberAnimation { duration: 350; easing.type: Easing.InOutQuad }
    }

    onIsLockedChanged: {
        if (isLocked) {
            enteredPin = "";
            lockRoot.forceActiveFocus();
        }
    }

    // Capture physical keyboard numbers and backspaces
    focus: isLocked
    Keys.onPressed: {
        if (!isLocked) return;
        
        if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
            appendDigit(String(event.key - Qt.Key_0));
            event.accepted = true;
        } else if (event.key === Qt.Key_Backspace) {
            removeDigit();
            event.accepted = true;
        }
    }

    // Background Momentum Wallpaper image loaded locally
    Image {
        id: bgImage
        anchors.fill: parent
        source: "anodyne://homepage/momentum_bg.jpg"
        fillMode: Image.PreserveAspectCrop

        // Dark glassmorphic backdrop overlay
        Rectangle {
            anchors.fill: parent
            color: "#b0000000" // Premium dark dimming
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.centerIn: parent
        spacing: 24
        width: 320

        // 1. Clock Display (Big, premium Outfit/Inter styled typography)
        Text {
            id: lockTime
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(new Date(), "H:mm")
            color: "#ffffff"
            font.pixelSize: 72
            font.weight: Font.Light
            font.family: "Outfit"
        }

        Text {
            id: lockDate
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
            color: "#888888"
            font.pixelSize: 15
            font.weight: Font.Medium
            font.family: "Outfit"
        }

        Item {
            Layout.preferredHeight: 20
        }

        // 2. PIN Instructions
        Text {
            id: instructionsText
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("Enter PIN to Unlock")
            color: "#ffffff"
            font.pixelSize: 13
            font.weight: Font.Medium
        }

        // 3. Dot Indicators
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 16
            
            Repeater {
                model: 4
                delegate: Rectangle {
                    width: 14
                    height: 14
                    radius: 7
                    color: index < enteredPin.length ? "#ffffff" : "transparent"
                    border.color: "#ffffff"
                    border.width: 1.5
                    
                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }
                }
            }
        }

        Item {
            Layout.preferredHeight: 12
        }

        // 4. Circular Button Grid (Mouse & Touch-friendly)
        GridLayout {
            Layout.alignment: Qt.AlignHCenter
            columns: 3
            columnSpacing: 20
            rowSpacing: 16

            Repeater {
                model: [
                    "1", "2", "3",
                    "4", "5", "6",
                    "7", "8", "9",
                    "C", "0", "⌫"
                ]

                delegate: Rectangle {
                    id: keyButton
                    width: 60
                    height: 60
                    radius: 30
                    color: keyMa.pressed ? Qt.rgba(1.0, 1.0, 1.0, 0.2) : (keyMa.containsMouse ? Qt.rgba(1.0, 1.0, 1.0, 0.1) : Qt.rgba(1.0, 1.0, 1.0, 0.05))
                    border.color: Qt.rgba(1.0, 1.0, 1.0, 0.15)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: "#ffffff"
                        font.pixelSize: modelData === "⌫" ? 16 : 20
                        font.weight: Font.Light
                    }

                    MouseArea {
                        id: keyMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (modelData === "⌫") {
                                removeDigit();
                            } else if (modelData === "C") {
                                enteredPin = "";
                            } else {
                                appendDigit(modelData);
                            }
                        }
                    }
                }
            }
        }
    }

    // Shake animation on wrong PIN input
    SequentialAnimation {
        id: shakeAnim
        loops: 1

        NumberAnimation { target: mainLayout; property: "anchors.horizontalCenterOffset"; to: -15; duration: 50; easing.type: Easing.OutQuad }
        NumberAnimation { target: mainLayout; property: "anchors.horizontalCenterOffset"; to: 15; duration: 50; easing.type: Easing.OutQuad }
        NumberAnimation { target: mainLayout; property: "anchors.horizontalCenterOffset"; to: -10; duration: 50; easing.type: Easing.OutQuad }
        NumberAnimation { target: mainLayout; property: "anchors.horizontalCenterOffset"; to: 10; duration: 50; easing.type: Easing.OutQuad }
        NumberAnimation { target: mainLayout; property: "anchors.horizontalCenterOffset"; to: -5; duration: 50; easing.type: Easing.OutQuad }
        NumberAnimation { target: mainLayout; property: "anchors.horizontalCenterOffset"; to: 5; duration: 50; easing.type: Easing.OutQuad }
        NumberAnimation { target: mainLayout; property: "anchors.horizontalCenterOffset"; to: 0; duration: 50; easing.type: Easing.OutQuad }
    }

    Timer {
        id: timeUpdater
        interval: 1000
        running: isLocked
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            lockTime.text = Qt.formatDateTime(new Date(), "H:mm");
            lockDate.text = Qt.formatDateTime(new Date(), "dddd, MMMM d");
        }
    }

    Timer {
        id: pinValidationTimer
        interval: 150
        repeat: false
        onTriggered: {
            if (enteredPin === targetPin) {
                lockRoot.isLocked = false;
                lockRoot.unlocked();
            } else {
                shakeAnim.start();
                enteredPin = "";
            }
        }
    }

    function appendDigit(digit) {
        if (enteredPin.length >= 4) return;
        enteredPin += digit;
        
        if (enteredPin.length === 4) {
            pinValidationTimer.start();
        }
    }

    function removeDigit() {
        if (enteredPin.length > 0) {
            enteredPin = enteredPin.slice(0, -1);
        }
    }
}
