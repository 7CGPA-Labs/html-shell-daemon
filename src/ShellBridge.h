#ifndef SHELLBRIDGE_H
#define SHELLBRIDGE_H

#include <QObject>
#include <QString>
#include <QVariant>
#include <QVariantList>
#include <QFileSystemWatcher>

class ShellBridge : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString currentMode READ currentMode NOTIFY modeChanged)

    Q_PROPERTY(QVariantList tabs READ tabs NOTIFY tabsChanged)
    Q_PROPERTY(int currentTabIndex READ currentTabIndex WRITE setCurrentTabIndex NOTIFY currentTabIndexChanged)
    Q_PROPERTY(bool touchscreenDetected READ touchscreenDetected NOTIFY touchscreenDetectedChanged)

public:
    explicit ShellBridge(QObject *parent = nullptr);
    QString currentMode() const;
    bool touchscreenDetected() const;

    // Static helper allowing background managers to target this specific bridge instance
    static ShellBridge* instance();

    QVariantList tabs() const;
    int currentTabIndex() const;
    void setCurrentTabIndex(int index);

public slots:
    void executeSystemCommand(const QString &command);
    void logWebEvent(const QString &message);
    
    // Remote controls for active jobs
    void jobControl(const QString &jobId, const QString &action);
    
    // Standard D-Bus notification server receiver slot
    uint Notify(const QString &app_name, uint replaces_id, const QString &app_icon, const QString &summary, const QString &body, const QStringList &actions, const QVariantMap &hints, int expire_timeout);
    
    // ZRAM/Telemetry query slots carrying over legacy business logic
    QString getZramDiskSize();
    QString getZramAlgorithm();
    QString getSystemSwappiness();
    
    // Real-time telemetry calculations
    QString getCpuUsage();
    QString getRamUsage();
    QString getStorageStatus();
    QString getSystemCore();

    // Tab registry management
    void launchOrSwitchApp(const QString &appId, const QString &url, const QString &title);
    void closeTab(int index);
    
    // Internal slots used to intercept data streams from the JobManager
    void handleJobProgressUpdate(const QString &jobId, int progress);
    void handleJobCompletionUpdate(const QString &jobId, bool success, const QString &message);

signals:
    void modeChanged(const QString &newMode);
    void launcherToggleTriggered();
    void launchAppRequested(QString appId, QString url, QString title);
    void notificationReceived(QString title, QString body);

    // NEW SIGNALS Exposed directly to JavaScript over the QWebChannel
    void nativeJobProgressChanged(QString jobId, int progress);
    void nativeJobFinished(QString jobId, bool success, QString message);

    void tabsChanged();
    void currentTabIndexChanged();
    void touchscreenDetectedChanged();

private slots:
    void handleTouchScreenFlagChanged();

private:
    QString m_currentMode;
    static ShellBridge* m_instance;

    QVariantList m_tabs;
    int m_currentTabIndex;

    // CPU telemetry tracker states
    qint64 m_prevActiveTime;
    qint64 m_prevTotalTime;

    QFileSystemWatcher *m_watcher;
};

#endif // SHELLBRIDGE_H