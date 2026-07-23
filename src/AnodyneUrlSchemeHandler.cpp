#include "AnodyneUrlSchemeHandler.h"
#include <QFile>
#include <QFileInfo>
#include <QMimeDatabase>
#include <QMimeType>
#include <QCoreApplication>
#include <QUrl>
#include <QDebug>

AnodyneUrlSchemeHandler::AnodyneUrlSchemeHandler(QObject *parent)
    : QWebEngineUrlSchemeHandler(parent)
{
}

void AnodyneUrlSchemeHandler::requestStarted(QWebEngineUrlRequestJob *request)
{
    const QUrl url = request->requestUrl();
    QString host = url.host();
    QString path = url.path();

    // If path is empty or ends with "/", default to index.html
    if (path.isEmpty() || path.endsWith("/")) {
        path += "index.html";
    }

    // Resolve file path to the web-apps directory beside the application binary
    QString baseDir = QCoreApplication::applicationDirPath() + "/web-apps";
    QString filePath = baseDir + "/" + host + path;

    QFileInfo fileInfo(filePath);
    if (!fileInfo.exists() || !fileInfo.isFile()) {
        qWarning() << "AnodyneUrlSchemeHandler: Asset not found:" << filePath;
        request->fail(QWebEngineUrlRequestJob::UrlNotFound);
        return;
    }

    QFile *file = new QFile(filePath);
    if (!file->open(QIODevice::ReadOnly)) {
        qWarning() << "AnodyneUrlSchemeHandler: Failed to open asset:" << filePath;
        request->fail(QWebEngineUrlRequestJob::RequestAborted);
        delete file;
        return;
    }

    // Determine MIME type
    QMimeDatabase mimeDb;
    QString mimeName = mimeDb.mimeTypeForFile(filePath).name();

    // Explicit override for WASM files to ensure correct Chromium compilation
    if (filePath.endsWith(".wasm", Qt::CaseInsensitive)) {
        mimeName = "application/wasm";
    }

    // Send the reply
    request->reply(mimeName.toUtf8(), file);

    // Clean up QFile when the request job is destroyed
    connect(request, &QObject::destroyed, file, &QObject::deleteLater);
}
