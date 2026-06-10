#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtWebEngine/qtwebengineglobal.h>
#include "ShellBridge.h"
#include "JobManager.h"

int main(int argc, char *argv[]) {
    // 1. FIX: Set attributes BEFORE creating QGuiApplication
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QCoreApplication::setAttribute(Qt::AA_ShareOpenGLContexts); // Fixes OpenGL Context warning

    // 2. FIX: Initialize the WebEngine BEFORE creating QGuiApplication
    QtWebEngine::initialize(); // Fixes the initialization order warning

    QGuiApplication app(argc, argv);
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