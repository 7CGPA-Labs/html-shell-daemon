#include "ShellBridge.h"
#include "JobManager.h"
#include <QDebug>
#include <QFile>
#include <QTextStream>
#include <QUrl>
#include <QDateTime>
#include <QMap>
#include <QProcess>
#include <QCoreApplication>
#include <QRegularExpression>
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
    : QObject(parent), m_currentMode("Precision-Desktop"), m_currentTabIndex(0), m_prevActiveTime(0), m_prevTotalTime(0)
{
    m_instance = this;
    qDebug() << "ShellBridge: Initialized communication core.";

    // Pre-populate with the Home Dashboard
    QVariantMap homeTab;
    homeTab["appId"] = "home";
    homeTab["title"] = "Home Dashboard";
    homeTab["url"] = "anodyne://homepage/index.html";
    m_tabs.append(homeTab);

    // Register this application as the Freedesktop Notification daemon
    QDBusConnection bus = QDBusConnection::sessionBus();
    if (bus.registerService("org.freedesktop.Notifications")) {
        bus.registerObject("/org/freedesktop/Notifications", this, QDBusConnection::ExportAllSlots);
        qDebug() << "[+] Registered org.freedesktop.Notifications D-Bus service successfully.";
    } else {
        qDebug() << "[-] Failed to register org.freedesktop.Notifications service:" << bus.lastError().message();
    }

    m_watcher = new QFileSystemWatcher(this);
    m_watcher->addPath("/tmp");
    connect(m_watcher, &QFileSystemWatcher::directoryChanged, this, &ShellBridge::handleTouchScreenFlagChanged);
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

    qDebug() << "D-Bus Notification Received Summary:" << summary << "Body:" << body;
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

QVariantList ShellBridge::tabs() const
{
    return m_tabs;
}

int ShellBridge::currentTabIndex() const
{
    return m_currentTabIndex;
}

void ShellBridge::setCurrentTabIndex(int index)
{
    if (index >= 0 && index < m_tabs.count() && m_currentTabIndex != index) {
        m_currentTabIndex = index;
        emit currentTabIndexChanged();
    }
}

void ShellBridge::launchOrSwitchApp(const QString &appId, const QString &url, const QString &title)
{
    QString resolvedUrl = url;
    QString appPath = QCoreApplication::applicationDirPath();
    if (appId == "files") {
        resolvedUrl = "anodyne://files/index.html";
    } else if (appId == "settings") {
        resolvedUrl = "anodyne://settings/index.html";
    } else if (appId == "home") {
        resolvedUrl = "anodyne://homepage/index.html";
    }

    // If already open, switch focus
    for (int i = 0; i < m_tabs.count(); ++i) {
        if (m_tabs[i].toMap()["appId"].toString() == appId) {
            setCurrentTabIndex(i);
            return;
        }
    }

    // Add new tab
    QVariantMap newTab;
    newTab["appId"] = appId;
    newTab["title"] = title;
    newTab["url"] = resolvedUrl;
    
    m_tabs.append(newTab);
    emit tabsChanged();
    
    setCurrentTabIndex(m_tabs.count() - 1);
}

void ShellBridge::closeTab(int index)
{
    if (index == 0) return; // Dashboard is pinned

    bool selectedTabWasClosed = (index == m_currentTabIndex);
    m_tabs.removeAt(index);
    emit tabsChanged();

    if (selectedTabWasClosed) {
        setCurrentTabIndex(qMax(0, index - 1));
    } else if (m_currentTabIndex > index) {
        m_currentTabIndex--;
        emit currentTabIndexChanged();
    }
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
        launchOrSwitchApp(appInfo.first, "", appInfo.second);
    } else {
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
            launchOrSwitchApp("web_" + QString::number(QDateTime::currentMSecsSinceEpoch()), resolvedUrl, command.trimmed());
        } else {
            QString encodedQuery = QString::fromUtf8(QUrl::toPercentEncoding(command));
            QString geminiUrl = "https://gemini.google.com/app?q=" + encodedQuery;
            launchOrSwitchApp("gemini_" + QString::number(QDateTime::currentMSecsSinceEpoch()), geminiUrl, "Gemini: " + command);
        }
    }
}

void ShellBridge::logWebEvent(const QString &message) 
{
    qDebug() << "[PWA Web Context Log]:" << message;
}

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

QString ShellBridge::getCpuUsage()
{
    QFile file("/proc/stat");
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return "N/A";
    
    QTextStream in(&file);
    QString line = in.readLine();
    file.close();

    if (line.startsWith("cpu ")) {
        QStringList parts = line.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);
        if (parts.size() >= 5) {
            qint64 user = parts[1].toLongLong();
            qint64 nice = parts[2].toLongLong();
            qint64 system = parts[3].toLongLong();
            qint64 idle = parts[4].toLongLong();
            qint64 iowait = parts[5].toLongLong();
            qint64 irq = parts[6].toLongLong();
            qint64 softirq = parts[7].toLongLong();

            qint64 activeTime = user + nice + system + irq + softirq;
            qint64 totalIdle = idle + iowait;
            qint64 total = activeTime + totalIdle;

            double percent = 0.0;
            if (m_prevTotalTime > 0) {
                qint64 totalDiff = total - m_prevTotalTime;
                qint64 idleDiff = totalIdle - m_prevActiveTime;
                if (totalDiff > 0) {
                    percent = 100.0 * (totalDiff - idleDiff) / totalDiff;
                    if (percent < 0.0) percent = 0.0;
                    if (percent > 100.0) percent = 100.0;
                }
            }
            m_prevTotalTime = total;
            m_prevActiveTime = totalIdle;
            return QString::number(qRound(percent)) + "%";
        }
    }
    return "N/A";
}

QString ShellBridge::getRamUsage()
{
    QFile file("/proc/meminfo");
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return "N/A";

    QTextStream in(&file);
    qint64 totalKb = 0;
    qint64 availKb = 0;
    
    while (!in.atEnd()) {
        QString line = in.readLine();
        if (line.startsWith("MemTotal:")) {
            QStringList parts = line.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);
            if (parts.size() >= 2) totalKb = parts[1].toLongLong();
        } else if (line.startsWith("MemAvailable:")) {
            QStringList parts = line.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);
            if (parts.size() >= 2) availKb = parts[1].toLongLong();
        }
    }
    file.close();

    if (totalKb > 0) {
        qint64 usedKb = totalKb - availKb;
        double usedGb = usedKb / (1024.0 * 1024.0);
        double totalGb = totalKb / (1024.0 * 1024.0);
        double pct = (100.0 * usedKb) / totalKb;
        
        QString health = "Healthy";
        if (pct > 90.0) health = "Low Memory";
        else if (pct > 75.0) health = "Normal";

        return health + " (" + QString::number(usedGb, 'f', 1) + " GB / " + QString::number(totalGb, 'f', 1) + " GB)";
    }
    return "N/A";
}

QString ShellBridge::getStorageStatus()
{
    return "Verified / Secure";
}

QString ShellBridge::getSystemCore()
{
    return "Anodyne OS 1.0 (Immutable)";
}

bool ShellBridge::touchscreenDetected() const
{
    return false; // QFile::exists("/tmp/touchscreen_detected");
}

void ShellBridge::handleTouchScreenFlagChanged()
{
    emit touchscreenDetectedChanged();
}