#include "ShellBridge.h"
#include "JobManager.h"
#include <QDebug>
#include <QFile>
#include <QTextStream>

// Static helper to read sysfs registers
static QString readSystemFile(const QString &path) {
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return "N/A";
    QTextStream in(&file);
    return in.readLine().trimmed();
}

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

QString ShellBridge::getZramDiskSize()
{
    QString zramSizeRaw = readSystemFile("/sys/block/zram0/disksize");
    if (zramSizeRaw == "N/A") return "N/A";
    
    bool ok;
    qint64 bytes = zramSizeRaw.toLongLong(&ok);
    if (!ok) return zramSizeRaw;
    
    qint64 sizeMb = bytes / (1024 * 1024);
    return QString::number(sizeMb) + " MB";
}

QString ShellBridge::getZramAlgorithm()
{
    QString algoRaw = readSystemFile("/sys/block/zram0/comp_algorithm");
    if (algoRaw == "N/A") return "N/A";
    
    int start = algoRaw.indexOf('[');
    int end = algoRaw.indexOf(']');
    if (start != -1 && end != -1 && end > start) {
        return algoRaw.mid(start + 1, end - start - 1);
    }
    return algoRaw;
}

QString ShellBridge::getSystemSwappiness()
{
    return readSystemFile("/proc/sys/vm/swappiness");
}