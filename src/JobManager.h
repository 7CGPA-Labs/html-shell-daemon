#ifndef JOBMANAGER_H
#define JOBMANAGER_H

#include <QObject>
#include <QString>
#include <QRunnable>
#include <QThread>
#include <QMutex>
#include <QWaitCondition>
#include <QHash>
#include <atomic>

// Thread-safe control flags shared between JobManager and background FileWorker
struct JobControlState {
    std::atomic<bool> paused{false};
    std::atomic<bool> canceled{false};
    QMutex mutex;
    QWaitCondition condition;
};

// Individual Worker Task handling the heavy physical I/O disk writes
class FileWorker : public QObject, public QRunnable
{
    Q_OBJECT

public:
    FileWorker(const QString &jobId, const QString &type, const QString &source, const QString &dest, JobControlState *controlState);
    void run() override;

signals:
    void progressUpdated(const QString &jobId, int progress);
    void jobFinished(const QString &jobId, bool success, const QString &message);

private:
    bool checkPauseAndCancel();
    bool copyRecursive(const QString &src, const QString &dst, qint64 &bytesCopied, qint64 totalBytes);
    bool deleteRecursive(const QString &path);

    QString m_jobId;
    QString m_type;
    QString m_source;
    QString m_dest;
    JobControlState *m_controlState;
};

// Global Manager controlling active operational background queues
class JobManager : public QObject
{
    Q_OBJECT

public:
    explicit JobManager(QObject *parent = nullptr);
    static JobManager *instance();

    QString createDiskJob(const QString &type, const QString &source, const QString &dest);
    
    // Remote control slots triggered via IPC WebChannel
    void pauseJob(const QString &jobId);
    void resumeJob(const QString &jobId);
    void cancelJob(const QString &jobId);

    JobControlState* getJobState(const QString &jobId);
    void unregisterJob(const QString &jobId);

signals:
    void jobProgressBroadcast(const QString &jobId, int progress);
    void jobCompletedBroadcast(const QString &jobId, bool success, const QString &message);

private slots:
    void handleWorkerProgress(const QString &jobId, int progress);
    void handleWorkerFinished(const QString &jobId, bool success, const QString &message);

private:
    static JobManager *m_instance;
    QHash<QString, JobControlState*> m_activeJobs;
    QMutex m_mapMutex;
};

#endif // JOBMANAGER_H
