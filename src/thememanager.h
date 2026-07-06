#pragma once

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QStringList>

class Logger;

class ThemeManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString cacheDir READ cacheDir CONSTANT)

public:
    explicit ThemeManager(QObject *parent = nullptr);
    ~ThemeManager();

    void setLogger(Logger *logger) { m_log = logger; }
    QString cacheDir() const;

    // === EXPORT ===
    Q_INVOKABLE QString exportTheme(const QString &filePath,
                                     const QString &jsonConfig,
                                     const QStringList &embedFonts,
                                     const QString &wallpaperPath = {});

    // === IMPORT ===
    Q_INVOKABLE QString parseTheme(const QString &filePath);

    // === FONTS ===
    Q_INVOKABLE QStringList installThemeFonts(const QString &themePath);
    Q_INVOKABLE void cleanupTempFonts(const QStringList &fontPaths);
    Q_INVOKABLE QString resolveFontPath(const QString &familyName);

    // === GALLERY NETWORK ===
    Q_INVOKABLE void fetchIndex();
    Q_INVOKABLE bool downloadTheme(const QString &themeId, const QString &url);
    Q_INVOKABLE void clearCache();

    // === GALLERY CACHE ===
    Q_INVOKABLE QString cachedPreviewPath(const QString &themeId);
    Q_INVOKABLE QString cachedThemePath(const QString &themeId);

    // === FONT PERSISTENCE ===
    Q_INVOKABLE void persistActiveFonts(const QStringList &fontPaths);
    Q_INVOKABLE void restorePersistedFonts();

    // === PREVIEW ===
    Q_INVOKABLE QString generatePreview(const QString &jsonConfig,
                                         const QString &wallpaperPath,
                                         int appletId = -1,
                                         const QStringList &fontPaths = {},
                                         const QString &customDate = {},
                                         const QString &customDayName = {});

signals:
    void indexFetchComplete(bool success);
    void themeDownloaded(const QString &themeId, bool success);
    void errorOccurred(const QString &message);

private:
    Logger *m_log = nullptr;
    QString m_cacheDir;
    QNetworkAccessManager *m_net;
    QString fallbackPreview(const QString &outPath);
    QRect findWidgetGeometry();
};
