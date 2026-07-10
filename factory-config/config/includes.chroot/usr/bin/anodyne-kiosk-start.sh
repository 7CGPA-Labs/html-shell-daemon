#!/bin/sh

# Initialize zRAM compressed swap at boot before GUI application starts
/usr/bin/setup-zram.sh

# 1. Disable screensavers and power management loops
xset s off
xset s noblank
xset -dpms

# 2. FIX: Force environment paths for the QML declarative module loader
export QML2_IMPORT_PATH=/usr/lib/x86_64-linux-gnu/qt5/qml
export QT_PLUGIN_PATH=/usr/lib/x86_64-linux-gnu/qt5/plugins
export QT_LOGGING_RULES="qt.qml.binding.removal.info=false"

# 3. Launch the custom multi-threaded C++/Qt window environment in an infinite loop
while true; do
    dbus-run-session -- /usr/bin/AnodyneOS --no-sandbox --disable-gpu-sandbox
done
