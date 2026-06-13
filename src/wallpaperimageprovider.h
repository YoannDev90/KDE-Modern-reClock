#pragma once

#include <QQuickImageProvider>
#include <QImage>
#include <QCache>
#include <QMutex>

/// Image provider that loads the current wallpaper for use in QML Image elements.
/// Usage in QML:  source: "image://modernreclock/preview"
class WallpaperImageProvider : public QQuickImageProvider {
public:
    WallpaperImageProvider();

    QImage requestImage(const QString& id, QSize* size, const QSize& requestedSize) override;

    /// Call this to invalidate the cached wallpaper (e.g. when theme changes)
    void invalidateCache();

private:
    QImage loadWallpaper();
    QString readWallpaperPath() const;
    bool isDarkColorScheme() const;

    QCache<QString, QImage> m_cache;
    QMutex m_mutex;
};
