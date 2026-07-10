#include "ShellBridge.h"
#include "JobManager.h"
#include <QDebug>
#include <QFile>
#include <QTextStream>
#include <QUrl>
#include <QDateTime>
#include <QMap>
#include <QProcess>
#include <QtDBus/QDBusConnection>
#include <QtDBus/QDBusError>

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

    // Register this application as the Freedesktop Notification daemon
    QDBusConnection bus = QDBusConnection::sessionBus();
    if (bus.registerService("org.freedesktop.Notifications")) {
        bus.registerObject("/org/freedesktop/Notifications", this, QDBusConnection::ExportAllSlots);
        qDebug() << "[+] Registered org.freedesktop.Notifications D-Bus service successfully.";
    } else {
        qDebug() << "[-] Failed to register org.freedesktop.Notifications service:" << bus.lastError().message();
    }
}

void ShellBridge::jobControl(const QString &jobId, const QString &action)
{
    QString act = action.trimmed().toLower();
    if (act == "pause") {
        JobManager::instance()->pauseJob(jobId);
    } else if (act == "resume") {
        JobManager::instance()->resumeJob(jobId);
    } else if (act == "cancel") {
        JobManager::instance()->cancelJob(jobId);
    }
}

uint ShellBridge::Notify(const QString &app_name, uint replaces_id, const QString &app_icon, const QString &summary, const QString &body, const QStringList &actions, const QVariantMap &hints, int expire_timeout)
{
    Q_UNUSED(app_name)
    Q_UNUSED(replaces_id)
    Q_UNUSED(app_icon)
    Q_UNUSED(actions)
    Q_UNUSED(hints)
    Q_UNUSED(expire_timeout)

    qDebug() << "🔔 D-Bus Notification Received Summary:" << summary << "Body:" << body;
    emit notificationReceived(summary, body);
    return 1;
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

    if (cleanCommand.startsWith("volume:")) {
        QString volStr = cleanCommand.mid(7);
        bool ok;
        int vol = volStr.toInt(&ok);
        if (ok) {
            qDebug() << "ShellBridge: Changing hardware audio volume to" << vol << "%";
            QProcess::startDetached("amixer", {"set", "Master", QString::number(vol) + "%"});
        }
        return;
    }
    
    static const QMap<QString, QPair<QString, QString>> localApps = {
        {"files", {"files", "Files"}},
        {"file", {"files", "Files"}},
        {"settings", {"settings", "Settings"}},
        {"setting", {"settings", "Settings"}},
        {"home", {"home", "Home Dashboard"}},
        {"dashboard", {"home", "Home Dashboard"}}
    };

    if (localApps.contains(cleanCommand)) {
        auto appInfo = localApps.value(cleanCommand);
        emit launchAppRequested(appInfo.first, "", appInfo.second);
    } else {
        // Check if the command is a URL (starts with http/https or contains dot and no spaces)
        bool isUrl = false;
        QString resolvedUrl = command.trimmed();
        if (resolvedUrl.startsWith("http://") || resolvedUrl.startsWith("https://")) {
            isUrl = true;
        } else if (resolvedUrl.contains(".") && !resolvedUrl.contains(" ")) {
            isUrl = true;
            resolvedUrl = "https://" + resolvedUrl;
        }

        if (isUrl) {
            qDebug() << "ShellBridge: Routing URL directly as a browser tab:" << resolvedUrl;
            emit launchAppRequested("web_" + QString::number(QDateTime::currentMSecsSinceEpoch()), resolvedUrl, command.trimmed());
        } else {
            // Sanitize and route to Google Gemini
            QString encodedQuery = QString::fromUtf8(QUrl::toPercentEncoding(command));
            QString geminiUrl = "https://gemini.google.com/app?q=" + encodedQuery;
            emit launchAppRequested("gemini_" + QString::number(QDateTime::currentMSecsSinceEpoch()), geminiUrl, "Gemini: " + command);
        }
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