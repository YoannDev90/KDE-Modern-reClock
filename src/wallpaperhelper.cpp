#include "wallpaperhelper.h"
#include "wallpaperconfig.h"

#include <QBuffer>
#include <QByteArray>
#include <QColor>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QImage>
#include <QStandardPaths>

WallpaperHelper::WallpaperHelper(QObject* parent)
    : QObject(parent)
{
    m_watcher = new QFileSystemWatcher(this);
    connect(m_watcher, &QFileSystemWatcher::fileChanged, this, [this](const QString&) {
        qDebug() << "[ModernRecClock] WallpaperHelper: wallpaper file changed, invalidating cache";
        m_cachedPath.clear();
        m_cachedBrightness.clear();
        emit wallpaperChanged();
        // Re-setup watcher (some editors/filesystems remove the watch on change)
        setupWatcher(wallpaperPath());
    });
    qDebug() << "[ModernRecClock] WallpaperHelper created with QFileSystemWatcher";
}

void WallpaperHelper::setupWatcher(const QString& path) {
    if (!m_watcher || path.isEmpty()) return;
    const auto files = m_watcher->files();
    if (!files.isEmpty()) m_watcher->removePaths(files);
    m_watcher->addPath(path);
    qDebug() << "[ModernRecClock] WallpaperHelper: watching" << path;
}

QString WallpaperHelper::wallpaperPath() const {
    if (!m_cachedPath.isEmpty()) {
        qDebug() << "[Wallpaper] wallpaperPath (cached):" << m_cachedPath;
        return m_cachedPath;
    }

    m_cachedPath = WallpaperConfig::readWallpaperPath();
    qDebug() << "[Wallpaper] wallpaperPath (resolved):" << m_cachedPath;

    if (!m_cachedPath.isEmpty())
        const_cast<WallpaperHelper*>(this)->setupWatcher(m_cachedPath);
    return m_cachedPath;
}

QString WallpaperHelper::wallpaperBrightness(const QString& path) const {
    if (path.isEmpty()) {
        qDebug() << "[ModernRecClock] WallpaperHelper::wallpaperBrightness → dark (empty path)";
        return QStringLiteral("dark");
    }
    if (path == m_cachedPath && !m_cachedBrightness.isEmpty()) {
        qDebug() << "[ModernRecClock] WallpaperHelper::wallpaperBrightness → cached:" << m_cachedBrightness;
        return m_cachedBrightness;
    }

    QImage img(path);
    if (img.isNull()) {
        qDebug() << "[ModernRecClock] WallpaperHelper::wallpaperBrightness → dark (null image for" << path << ")";
        return QStringLiteral("dark");
    }

    QImage scaled = img.scaled(50, 50, Qt::IgnoreAspectRatio, Qt::FastTransformation);
    int cx = scaled.width() / 2;
    int cy = scaled.height() / 2;
    double sumR = 0, sumG = 0, sumB = 0;
    int count = 0;

    for (int dx = -2; dx <= 2; dx++) {
        for (int dy = -2; dy <= 2; dy++) {
            int px = qBound(0, cx + dx, scaled.width() - 1);
            int py = qBound(0, cy + dy, scaled.height() - 1);
            QColor c = scaled.pixelColor(px, py);
            sumR += c.redF();
            sumG += c.greenF();
            sumB += c.blueF();
            count++;
        }
    }

    if (count == 0) {
        qDebug() << "[ModernRecClock] WallpaperHelper::wallpaperBrightness → dark (no pixels sampled)";
        return QStringLiteral("dark");
    }

    double brightness = 0.299 * (sumR / count) + 0.587 * (sumG / count) + 0.114 * (sumB / count);
    QString result = brightness < 0.5 ? QStringLiteral("dark") : QStringLiteral("light");
    qDebug() << "[ModernRecClock] WallpaperHelper::wallpaperBrightness" << path << "→" << result << "(luminance=" << brightness << ")";

    m_cachedBrightness = result;
    return result;
}

bool WallpaperHelper::isDarkColorScheme() const {
    bool dark = WallpaperConfig::isDarkColorScheme();
    qDebug() << "[Wallpaper] isDarkColorScheme:" << dark;
    return dark;
}

QString WallpaperHelper::wallpaperDataUrl() const {
    QString path = wallpaperPath();
    if (path.isEmpty()) {
        qDebug() << "[ModernRecClock] WallpaperHelper::wallpaperDataUrl → empty (no path)";
        return QString();
    }

    QImage img(path);
    if (img.isNull()) {
        qDebug() << "[ModernRecClock] WallpaperHelper::wallpaperDataUrl → empty (null image)";
        return QString();
    }

    if (img.width() > 800)
        img = img.scaledToWidth(800, Qt::SmoothTransformation);

    QByteArray ba;
    QBuffer buf(&ba);
    buf.open(QIODevice::WriteOnly);
    img.save(&buf, "JPEG", 80);
    buf.close();

    QString url = QStringLiteral("data:image/jpeg;base64,") + ba.toBase64();
    qDebug() << "[ModernRecClock] WallpaperHelper::wallpaperDataUrl →" << url.left(60) << "… (" << url.size() << " chars)";
    return url;
}

QString WallpaperHelper::wallpaperTempFile() const {
    QString path = wallpaperPath();
    if (path.isEmpty()) {
        qDebug() << "[ModernRecClock] WallpaperHelper::wallpaperTempFile → empty (no path)";
        return QString();
    }

    QImage img(path);
    if (img.isNull()) {
        qDebug() << "[ModernRecClock] WallpaperHelper::wallpaperTempFile → empty (null image)";
        return QString();
    }

    if (img.width() > 800)
        img = img.scaledToWidth(800, Qt::SmoothTransformation);

    QString tmpPath = QStringLiteral("/tmp/modernreclock_preview.jpg");
    bool saved = img.save(tmpPath, "JPEG", 80);
    qDebug() << "[ModernRecClock] WallpaperHelper::wallpaperTempFile →" << (saved ? tmpPath : "(save failed)");
    if (saved)
        return tmpPath;

    return QString();
}
