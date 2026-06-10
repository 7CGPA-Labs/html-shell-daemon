#include "ShellBridge.h"
#include "JobManager.h"
#include <QDebug>

ShellBridge* ShellBridge::m_instance = nullptr;

ShellBridge::ShellBridge(QObject *parent) 
    : QObject(parent), m_currentMode("Precision-Desktop") 
{
    m_instance = this;
    qDebug() << "ShellBridge: Initialized communication core.";
}

QString ShellBridge::currentMode() const 
{
    return m_currentMode;
}

ShellBridge* ShellBridge::instance()
{
    return m_instance;
}

void ShellBridge::executeSystemCommand(const QString &command) 
{
    QString cleanCommand = command.trimmed().toLower();
    qDebug() << "⚠️ IPC Bridge Request Received -> Action:" << cleanCommand;
    
    if (cleanCommand == "files") {
        qDebug() << "ShellBridge: Launching a native background I/O copy transaction...";
        JobManager::instance()->createDiskJob("copy", "/home/user/downloads", "/media/usb/backup");
    } else if (cleanCommand == "settings") {
        qDebug() << "ShellBridge: Validated 'settings' request.";
    } else if (cleanCommand == "launcher") {
        qDebug() << "ShellBridge: Forwarding Launcher display toggle down to the QML window layer.";
        emit launcherToggleTriggered();
    }
}

void ShellBridge::logWebEvent(const QString &message) 
{
    qDebug() << "[PWA Web Context Log]:" << message;
}

// Intercept thread pool progressions and shoot them straight across the browser channel
void ShellBridge::handleJobProgressUpdate(const QString &jobId, int progress)
{
    emit nativeJobProgressChanged(jobId, progress);
}

void ShellBridge::handleJobCompletionUpdate(const QString &jobId, bool success, const QString &message)
{
    emit nativeJobFinished(jobId, success, message);
}