import QtQuick 2.15

QtObject {
    readonly property color canvasBackground: "#0a0a0a"
    readonly property color barBackground: "#161616"
    readonly property color barBorder: "#2a2a2a"
    readonly property color cardBackground: "#1f1f1f"
    readonly property color textPrimary: "#ffffff"
    readonly property color textSecondary: "#888888"
    readonly property color textMuted: "#666666"
    readonly property color accent: "#4a9eff"
    readonly property color badgeBackground: "#2d3a1f"
    readonly property color badgeText: "#b8e986"
    readonly property color drawerBackground: "#141414"
    readonly property color drawerScrim: "#99000000"

    readonly property int barHeight: 32
    readonly property int drawerWidth: 280
    readonly property int barPadding: 10
    readonly property int itemSpacing: 12
    readonly property int cornerRadius: 6
    readonly property int iconSize: 16
    readonly property int tabHeight: 36
    readonly property int tabWidth: 160

    readonly property color tabActiveBackground: "#1a1a1a"
    readonly property color tabInactiveBackground: "#101010"
    readonly property color tabActiveBorder: "#007acc"

    readonly property string iconDrawer: "qrc:/icons/drawer.svg"
    readonly property string iconCalendar: "qrc:/icons/calendar.svg"
    readonly property string iconWifi: "qrc:/icons/wifi.svg"
    readonly property string iconBattery: "qrc:/icons/battery.svg"
    readonly property string iconTouch: "qrc:/icons/touch.svg"
    readonly property string iconNotification: "qrc:/icons/notification.svg"
}
