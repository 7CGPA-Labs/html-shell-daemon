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
    
    // Internal slots used to intercept data streams from the JobManager
    void handleJobProgressUpdate(const QString &jobId, int progress);
    void handleJobCompletionUpdate(const QString &jobId, bool success, const QString &message);

signals:
    void modeChanged(const QString &newMode);
    void launcherToggleTriggered();

    // NEW SIGNALS Exposed directly to JavaScript over the QWebChannel
    void nativeJobProgressChanged(QString jobId, int progress);
    void nativeJobFinished(QString jobId, bool success, QString message);

private:
    QString m_currentMode;
    static ShellBridge* m_instance;
};

#endif // SHELLBRIDGE_H