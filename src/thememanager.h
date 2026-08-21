#pragma once

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QStringList>
#include <QTimer>
#include <QtConcurrent>

class Logger;

class ThemeManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString cacheDir READ cacheDir CONSTANT)
    Q_PROPERTY(QStringList configKeys READ configKeys CONSTANT)

public:
    explicit ThemeManager(QObject *parent = nullptr);
    ~ThemeManager();

    void setLogger(Logger *logger) { m_log = logger; }
    QString cacheDir() const;
    QStringList configKeys() const;

    Q_INVOKABLE QString exportTheme(const QString &filePath,
                                    const QString &jsonConfig,
                                    const QStringList &embedFonts,
                                    const QString &wallpaperPath = {});
    Q_INVOKABLE QString parseTheme(const QString &filePath);

    Q_INVOKABLE QStringList installThemeFonts(const QString &themePath);
    Q_INVOKABLE void cleanupTempFonts(const QStringList &fontPaths);
    Q_INVOKABLE QString resolveFontPath(const QString &familyName);

    Q_INVOKABLE bool hasThemeWallpaper(const QString &themePath);
    Q_INVOKABLE QString extractThemeWallpaper(const QString &themePath, const QString &themeId);
    Q_INVOKABLE void setDesktopWallpaper(const QString &imagePath);

    Q_INVOKABLE void fetchIndex();
    Q_INVOKABLE void downloadTheme(const QString &themeId, const QString &url);
    Q_INVOKABLE void clearCache();

    Q_INVOKABLE QString cachedPreviewPath(const QString &themeId);
    Q_INVOKABLE QString cachedThemePath(const QString &themeId);

    Q_INVOKABLE void persistActiveFonts(const QStringList &fontPaths);
    Q_INVOKABLE void restorePersistedFonts();

    Q_INVOKABLE QString generatePreview(const QString &jsonConfig,
                                        const QString &wallpaperPath,
                                        int appletId = -1,
                                        const QStringList &fontPaths = {},
                                        const QString &customDate = {},
                                        const QString &customDayName = {});

    Q_INVOKABLE void generatePreviewAsync(const QString &jsonConfig,
                                          const QString &wallpaperPath,
                                          int appletId = -1,
                                          const QStringList &fontPaths = {},
                                          const QString &customDate = {},
                                          const QString &customDayName = {});

signals:
    void indexFetchComplete(bool success, const QString &jsonData);
    void themeDownloaded(const QString &themeId, bool success);
    void errorOccurred(const QString &message);
    void previewGenerated(const QString &outPath);

private:
    Logger *m_log = nullptr;
    QString m_cacheDir;
    QNetworkAccessManager *m_net;
    bool m_previewBusy = false;
    QString m_pendingPreviewConfig;
    QString m_pendingPreviewWp;
    int m_pendingPreviewAppletId = -1;
    QStringList m_pendingPreviewFonts;
    QString m_pendingPreviewDate;
    QString m_pendingPreviewDay;
    QString fallbackPreview(const QString &outPath);
    QRect findWidgetGeometry();
    void doFetch(const QUrl &url, const std::function<void(QByteArray)> &onSuccess,
                 const std::function<void()> &onFailure, int timeoutMs = 10000);
};
