QT += core gui quick webengine webchannel

CONFIG += c++17

SOURCES += src/main.cpp \
           src/ShellBridge.cpp \
           src/JobManager.cpp

HEADERS += src/ShellBridge.h \
           src/JobManager.h

RESOURCES += ui/qml.qrc

# Copy web-apps beside the binary for shadow builds only.
# Shell guard avoids qmake PWD/OUT_PWD string mismatches on in-source builds.
copy_assets.commands = test $$shell_quote($$PWD) = $$shell_quote($$OUT_PWD) \
    || (mkdir -p $$shell_quote($$OUT_PWD/web-apps) \
    && cp -rf $$shell_quote($$PWD/web-apps)/. $$shell_quote($$OUT_PWD/web-apps)/)
copy_assets.depends = FORCE
QMAKE_EXTRA_TARGETS += copy_assets
PRE_TARGETDEPS += copy_assets

target.path = /usr/bin
INSTALLS += target

webapps.files = web-apps
webapps.path = /usr/bin
INSTALLS += webapps
