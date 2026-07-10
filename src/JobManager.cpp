#include "JobManager.h"
#include <QDebug>
#include <QThreadPool>
#include <QUuid>
#include <QFile>
#include <QDir>
#include <QFileInfo>

// Static helper to calculate total bytes in a file or directory tree
static qint64 calculateTotalBytes(const QString &path) {
    QFileInfo info(path);
    if (info.isFile()) {
        return info.size();
    } else if (info.isDir()) {
        qint64 total = 0;
        QDir dir(path);
        for (const QString &entry : dir.entryList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot)) {
            total += calculateTotalBytes(dir.absoluteFilePath(entry));
        }
        return total;
    }
    return 0;
}

// --- File Worker Implementation ---

FileWorker::FileWorker(const QString &jobId, const QString &type, const QString &source, const QString &dest, JobControlState *controlState)
    : m_jobId(jobId)
    , m_type(type)
    , m_source(source)
    , m_dest(dest)
    , m_controlState(controlState)
{
    setAutoDelete(true);
}

bool FileWorker::checkPauseAndCancel() {
    if (m_controlState->canceled) {
        return true;
    }
    if (m_controlState->paused) {
        m_controlState->mutex.lock();
        while (m_controlState->paused && !m_controlState->canceled) {
            m_controlState->condition.wait(&m_controlState->mutex);
        }
        m_controlState->mutex.unlock();
    }
    return m_controlState->canceled;
}

bool FileWorker::copyRecursive(const QString &src, const QString &dst, qint64 &bytesCopied, qint64 totalBytes) {
    if (checkPauseAndCancel()) return false;

    QFileInfo srcInfo(src);
    if (srcInfo.isFile()) {
        QFile srcFile(src);
        if (!srcFile.open(QIODevice::ReadOnly)) return false;
        
        QFile dstFile(dst);
        if (!dstFile.open(QIODevice::WriteOnly)) return false;

        char buffer[65536];
        while (!srcFile.atEnd()) {
            if (checkPauseAndCancel()) {
                dstFile.close();
                QFile::remove(dst); // clean up partial file
                return false;
            }
            qint64 read = srcFile.read(buffer, sizeof(buffer));
            if (read <= 0) break;
            dstFile.write(buffer, read);
            bytesCopied += read;
            
            int progress = totalBytes > 0 ? (bytesCopied * 100 / totalBytes) : 100;
            emit progressUpdated(m_jobId, progress);
        }
        return true;
    } else if (srcInfo.isDir()) {
        QDir().mkpath(dst);
        QDir srcDir(src);
        for (const QString &entry : srcDir.entryList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot)) {
            QString srcPath = srcDir.absoluteFilePath(entry);
            QString dstPath = QDir(dst).absoluteFilePath(entry);
            if (!copyRecursive(srcPath, dstPath, bytesCopied, totalBytes)) {
                return false;
            }
        }
        return true;
    }
    return false;
}

bool FileWorker::deleteRecursive(const QString &path) {
    QFileInfo info(path);
    if (info.isFile()) {
        return QFile::remove(path);
    } else if (info.isDir()) {
        QDir dir(path);
        for (const QString &entry : dir.entryList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot)) {
            if (!deleteRecursive(dir.absoluteFilePath(entry))) {
                return false;
            }
        }
        return QDir().rmdir(path);
    }
    return false;
}

void FileWorker::run()
{
    qDebug() << "Thread Spawned: Processing Job" << m_jobId << "for action:" << m_type;

    bool success = false;
    QString message = "";

    qint64 totalBytes = calculateTotalBytes(m_source);
    qint64 bytesCopied = 0;

    if (m_type == "copy") {
        success = copyRecursive(m_source, m_dest, bytesCopied, totalBytes);
        message = success ? "Files copied successfully." : "Copy operation failed or canceled.";
    } else if (m_type == "move") {
        success = copyRecursive(m_source, m_dest, bytesCopied, totalBytes);
        if (success) {
            success = deleteRecursive(m_source);
            message = success ? "Files moved successfully." : "Failed to clean source files during move.";
        } else {
            message = "Move operation failed or canceled.";
        }
    } else if (m_type == "delete") {
        success = deleteRecursive(m_source);
        message = success ? "Files deleted successfully." : "Delete operation failed.";
    } else {
        message = "Unknown job type: " + m_type;
    }

    if (m_controlState->canceled) {
        success = false;
        message = "Operation canceled by user.";
    }

    emit jobFinished(m_jobId, success, message);
    
    // Automatically release the active job state from mapping lists
    JobManager::instance()->unregisterJob(m_jobId);
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
    const QString jobId = QUuid::createUuid().toString(QUuid::WithoutBraces).left(8);
    qDebug() << "JobManager: Queueing Task ID [" << jobId << "] type:" << type;

    m_mapMutex.lock();
    auto *controlState = new JobControlState();
    m_activeJobs.insert(jobId, controlState);
    m_mapMutex.unlock();

    auto *worker = new FileWorker(jobId, type, source, dest, controlState);

    connect(worker, &FileWorker::progressUpdated, this, &JobManager::handleWorkerProgress, Qt::QueuedConnection);
    connect(worker, &FileWorker::jobFinished, this, &JobManager::handleWorkerFinished, Qt::QueuedConnection);

    QThreadPool::globalInstance()->start(worker);

    return jobId;
}

void JobManager::pauseJob(const QString &jobId)
{
    m_mapMutex.lock();
    if (m_activeJobs.contains(jobId)) {
        qDebug() << "JobManager: Pausing job ID" << jobId;
        m_activeJobs.value(jobId)->paused = true;
    }
    m_mapMutex.unlock();
}

void JobManager::resumeJob(const QString &jobId)
{
    m_mapMutex.lock();
    if (m_activeJobs.contains(jobId)) {
        qDebug() << "JobManager: Resuming job ID" << jobId;
        auto *state = m_activeJobs.value(jobId);
        state->paused = false;
        state->condition.wakeAll();
    }
    m_mapMutex.unlock();
}

void JobManager::cancelJob(const QString &jobId)
{
    m_mapMutex.lock();
    if (m_activeJobs.contains(jobId)) {
        qDebug() << "JobManager: Canceling job ID" << jobId;
        auto *state = m_activeJobs.value(jobId);
        state->canceled = true;
        state->condition.wakeAll();
    }
    m_mapMutex.unlock();
}

JobControlState* JobManager::getJobState(const QString &jobId)
{
    QMutexLocker locker(&m_mapMutex);
    return m_activeJobs.value(jobId, nullptr);
}

void JobManager::unregisterJob(const QString &jobId)
{
    m_mapMutex.lock();
    if (m_activeJobs.contains(jobId)) {
        auto *state = m_activeJobs.take(jobId);
        delete state;
    }
    m_mapMutex.unlock();
}

void JobManager::handleWorkerProgress(const QString &jobId, int progress)
{
    emit jobProgressBroadcast(jobId, progress);
}

void JobManager::handleWorkerFinished(const QString &jobId, bool success, const QString &message)
{
    emit jobCompletedBroadcast(jobId, success, message);
}
