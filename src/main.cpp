#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtWebEngine/qtwebengineglobal.h>
#include <QWebEngineUrlScheme>
#include <QWebEngineProfile>
#include <QDir>
#include "ShellBridge.h"
#include "JobManager.h"
#include "AnodyneUrlSchemeHandler.h"

int main(int argc, char *argv[]) {
    // Enable multi-threaded SharedArrayBuffer, disable CORS, and allow running as root user
    qputenv("QTWEBENGINE_CHROMIUM_FLAGS", "--enable-features=SharedArrayBuffer --disable-web-security --no-sandbox");

    // Register custom secure URL scheme BEFORE creating QGuiApplication
    QWebEngineUrlScheme scheme("anodyne");
    scheme.setFlags(QWebEngineUrlScheme::SecureScheme |
                    QWebEngineUrlScheme::LocalScheme |
                    QWebEngineUrlScheme::LocalAccessAllowed |
                    QWebEngineUrlScheme::CorsEnabled);
    QWebEngineUrlScheme::registerScheme(scheme);

    // 1. FIX: Set attributes BEFORE creating QGuiApplication
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QCoreApplication::setAttribute(Qt::AA_ShareOpenGLContexts); // Fixes OpenGL Context warning

    // 2. FIX: Initialize the WebEngine BEFORE creating QGuiApplication
    QtWebEngine::initialize(); // Fixes the initialization order warning

    QGuiApplication app(argc, argv);

    // Configure persistent profiles on the writeable home partition
    QWebEngineProfile *defaultProfile = QWebEngineProfile::defaultProfile();
    QString profilePath = QDir::homePath() + "/.config/anodyne/profile";
    QString cachePath = QDir::homePath() + "/.config/anodyne/cache";
    defaultProfile->setPersistentStoragePath(profilePath);
    defaultProfile->setCachePath(cachePath);

    // Install scheme handler
    AnodyneUrlSchemeHandler *handler = new AnodyneUrlSchemeHandler(&app);
    defaultProfile->installUrlSchemeHandler("anodyne", handler);
    QQmlApplicationEngine engine;

    // Instantiate core controllers
    ShellBridge *systemBridge = new ShellBridge(&app);
    JobManager *backgroundJobProcessor = new JobManager(&app);

    // Connect the background threads' Manager up to the Web Channel Gateway Bridge
    QObject::connect(backgroundJobProcessor, &JobManager::jobProgressBroadcast,
                     systemBridge, &ShellBridge::handleJobProgressUpdate);
    QObject::connect(backgroundJobProcessor, &JobManager::jobCompletedBroadcast,
                     systemBridge, &ShellBridge::handleJobCompletionUpdate);

    // 3. FIX: Explicitly pass the binary folder path down into the QML engine global context
    engine.rootContext()->setContextProperty("applicationDirPath", QCoreApplication::applicationDirPath());
    
    // Register the pointer directly inside the QML Engine environment context
    engine.rootContext()->setContextProperty("nativeSystemBridge", systemBridge);

    const QUrl url(QStringLiteral("qrc:/Shell.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}