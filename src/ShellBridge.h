#ifndef SHELLBRIDGE_H
#define SHELLBRIDGE_H

#include <QObject>
#include <QString>

class ShellBridge : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString currentMode READ currentMode NOTIFY modeChanged)

public:
    explicit ShellBridge(QObject *parent = nullptr);
    QString currentMode() const;

    // Static helper allowing background managers to target this specific bridge instance
    static ShellBridge* instance();

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

private:
    QString m_currentMode;
    static ShellBridge* m_instance;
};

#endif // SHELLBRIDGE_H