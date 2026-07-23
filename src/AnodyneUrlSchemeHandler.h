#ifndef ANODYNEURLSCHEMEHANDLER_H
#define ANODYNEURLSCHEMEHANDLER_H

#include <QWebEngineUrlSchemeHandler>
#include <QWebEngineUrlRequestJob>

class AnodyneUrlSchemeHandler : public QWebEngineUrlSchemeHandler {
    Q_OBJECT
public:
    explicit AnodyneUrlSchemeHandler(QObject *parent = nullptr);
    void requestStarted(QWebEngineUrlRequestJob *request) override;
};

#endif // ANODYNEURLSCHEMEHANDLER_H
