#ifndef JOBMANAGER_H
#define JOBMANAGER_H

#include <QObject>
#include <QString>
#include <QRunnable>
#include <QThread>

// Individual Worker Task handling the heavy physical I/O disk writes
class FileWorker : public QObject, public QRunnable
{
    Q_OBJECT

public:
    FileWorker(const QString &jobId, const QString &type, const QString &source, const QString &dest);
    void run() override;

signals:
    void progressUpdated(const QString &jobId, int progress);
    void jobFinished(const QString &jobId, bool success, const QString &message);

private:
    QString m_jobId;
    QString m_type;
    QString m_source;
    QString m_dest;
};

// Global Manager controlling active operational background queues
class JobManager : public QObject
{
    Q_OBJECT

public:
    explicit JobManager(QObject *parent = nullptr);
    static JobManager *instance();

    QString createDiskJob(const QString &type, const QString &source, const QString &dest);

signals:
    void jobProgressBroadcast(const QString &jobId, int progress);
    void jobCompletedBroadcast(const QString &jobId, bool success, const QString &message);

private slots:
    void handleWorkerProgress(const QString &jobId, int progress);
    void handleWorkerFinished(const QString &jobId, bool success, const QString &message);

private:
    static JobManager *m_instance;
};

#endif // JOBMANAGER_H
