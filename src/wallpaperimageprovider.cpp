#include "wallpaperimageprovider.h"
#include "wallpaperconfig.h"

#include <QDebug>
#include <QMutexLocker>

WallpaperImageProvider::WallpaperImageProvider()
    : QQuickImageProvider(QQuickImageProvider::Image)
{
    m_cache.setMaxCost(4);
    qDebug() << "[ModernRecClock] WallpaperImageProvider created, cache max cost = 4";
}

QImage WallpaperImageProvider::loadWallpaper() {
    QString path = WallpaperConfig::readWallpaperPath();
    if (path.isEmpty() || path.startsWith(QStringLiteral("slideshow:"))) {
        qDebug() << "[ModernRecClock] WIP::loadWallpaper →" << (path.isEmpty() ? "empty path" : "slideshow, skipping");
        return QImage();
    }

    QImage original(path);
    if (original.isNull()) {
        qDebug() << "[ModernRecClock] WIP::loadWallpaper → null image for" << path;
        return QImage();
    }

    const int maxW = 800;
    if (original.width() > maxW)
        original = original.scaledToWidth(maxW, Qt::SmoothTransformation);

    qDebug() << "[ModernRecClock] WIP::loadWallpaper →" << original.size() << "from" << path;
    return original;
}

QImage WallpaperImageProvider::requestImage(const QString& id, QSize* size, const QSize& requestedSize) {
    qDebug() << "[ModernRecClock] WIP::requestImage id=" << id << "requestedSize=" << requestedSize;
    QMutexLocker lock(&m_mutex);

    const QString cacheKey = QStringLiteral("wallpaper");

    QImage* cached = m_cache.object(cacheKey);
    if (cached) {
        qDebug() << "[ModernRecClock] WIP::requestImage → cache HIT, size=" << cached->size();
        if (size) *size = cached->size();
        int w = requestedSize.width() > 0 ? requestedSize.width() : cached->width();
        int h = requestedSize.height() > 0 ? requestedSize.height() : cached->height();
        return cached->scaled(w, h, Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
    }

    qDebug() << "[ModernRecClock] WIP::requestImage → cache MISS, loading...";
    QImage img = loadWallpaper();
    if (img.isNull()) {
        qDebug() << "[ModernRecClock] WIP::requestImage → wallpaper null, returning transparent fallback";
        QImage fallback(1, 1, QImage::Format_ARGB32);
        fallback.fill(Qt::transparent);
        if (size) *size = fallback.size();
        return fallback;
    }

    m_cache.insert(cacheKey, new QImage(img), img.sizeInBytes());
    qDebug() << "[ModernRecClock] WIP::requestImage → cached and returning" << img.size() << "cost=" << img.sizeInBytes();

    if (size) *size = img.size();
    int w = requestedSize.width() > 0 ? requestedSize.width() : img.width();
    int h = requestedSize.height() > 0 ? requestedSize.height() : img.height();
    return img.scaled(w, h, Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
}

void WallpaperImageProvider::invalidateCache() {
    QMutexLocker lock(&m_mutex);
    qDebug() << "[ModernRecClock] WIP::invalidateCache — clearing" << m_cache.count() << "entries";
    m_cache.clear();
}
