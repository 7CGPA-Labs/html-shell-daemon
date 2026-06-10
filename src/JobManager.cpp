#include "JobManager.h"

#include <QDebug>
#include <QThreadPool>
#include <QUuid>

// --- File Worker Implementation ---

FileWorker::FileWorker(const QString &jobId, const QString &type, const QString &source, const QString &dest)
    : m_jobId(jobId)
    , m_type(type)
    , m_source(source)
    , m_dest(dest)
{
    // Auto-delete runnable from memory allocation once run() finishes execution
    setAutoDelete(true);
}

void FileWorker::run()
{
    qDebug() << "Thread Spawned: Processing Job" << m_jobId << "for action:" << m_type;

    // Simulate a heavy file copy task over 5 progressive intervals
    for (int i = 1; i <= 5; ++i) {
        QThread::msleep(600); // Blocks worker thread, NOT the UI shell thread
        const int progress = i * 20;
        emit progressUpdated(m_jobId, progress);
    }

    emit jobFinished(m_jobId, true, QStringLiteral("Operation completed successfully via native filesystem."));
}

// --- Job Manager Core Pool Implementation ---

JobManager *JobManager::m_instance = nullptr;

JobManager::JobManager(QObject *parent)
    : QObject(parent)
{
    m_instance = this;
    qDebug() << "JobManager: Thread-pool control layer active.";
}

JobManager *JobManager::instance()
{
    return m_instance;
}

QString JobManager::createDiskJob(const QString &type, const QString &source, const QString &dest)
{
    // Generate a unique sequential identifier for the transaction tracking loop
    const QString jobId = QUuid::createUuid().toString(QUuid::WithoutBraces).left(8);
    qDebug() << "JobManager: Queueing Task ID [" << jobId << "] type:" << type;

    auto *worker = new FileWorker(jobId, type, source, dest);

    // Bind execution signaling pathways up to manager context bridges
    connect(worker, &FileWorker::progressUpdated, this, &JobManager::handleWorkerProgress, Qt::QueuedConnection);
    connect(worker, &FileWorker::jobFinished, this, &JobManager::handleWorkerFinished, Qt::QueuedConnection);

    // Push the worker task onto the global shared CPU execution thread-pool
    QThreadPool::globalInstance()->start(worker);

    return jobId;
}

void JobManager::handleWorkerProgress(const QString &jobId, int progress)
{
    qDebug() << "Job [" << jobId << "] Processing Data Layer:" << progress << "%";
    emit jobProgressBroadcast(jobId, progress);
}

void JobManager::handleWorkerFinished(const QString &jobId, bool success, const QString &message)
{
    qDebug() << "Job [" << jobId << "] Discharged. Status:" << success << "|" << message;
    emit jobCompletedBroadcast(jobId, success, message);
}
