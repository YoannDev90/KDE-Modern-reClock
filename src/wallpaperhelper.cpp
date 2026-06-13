#include "wallpaperhelper.h"
#include <QFile>
#include <QTextStream>
#include <QDir>
#include <QFileInfo>
#include <QStandardPaths>
#include <QImage>
#include <QColor>

// ── Color scheme detection ──

QString WallpaperHelper::readKdeColorScheme() {
    // Read ColorScheme= from ~/.config/kdeglobals
    QString globalsPath = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation)
        + QStringLiteral("/kdeglobals");
    QFile f(globalsPath);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text))
        return QString();

    QTextStream in(&f);
    bool inGeneral = false;
    while (!in.atEnd()) {
        QString line = in.readLine().trimmed();
        if (line.startsWith('[')) {
            inGeneral = (line == QStringLiteral("[General]"));
            continue;
        }
        if (inGeneral && line.startsWith(QStringLiteral("ColorScheme="))) {
            f.close();
            return line.mid(12).trimmed();
        }
    }
    f.close();
    return QString();
}

bool WallpaperHelper::isDarkColorScheme() const {
    QString scheme = readKdeColorScheme();
    if (scheme.isEmpty())
        return true; // default to dark if unknown
    // KDE color scheme names containing "dark" (case-insensitive) indicate dark mode
    return scheme.contains(QStringLiteral("dark"), Qt::CaseInsensitive);
}

// ── Wallpaper path detection ──

WallpaperHelper::WallpaperHelper(QObject* parent)
    : QObject(parent) {}

QString WallpaperHelper::wallpaperPath() const {
    // 1. Find the Plasma desktop applet config file
    QString configPath = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation)
        + QStringLiteral("/plasma-org.kde.plasma.desktop-appletsrc");
    QFile configFile(configPath);
    if (!configFile.open(QIODevice::ReadOnly | QIODevice::Text))
        return QString();

    // 2. Parse the INI-style config to find wallpaper image path
    //    Format: [Containments][N][Wallpaper][org.kde.image][General]\nImage=file:///...
    QString imagePath;
    QTextStream in(&configFile);
    while (!in.atEnd()) {
        QString line = in.readLine().trimmed();
        if (line.isEmpty() || line.startsWith('#'))
            continue;
        // Look for Image= key inside a wallpaper section
        if (line.startsWith(QStringLiteral("Image="))) {
            imagePath = line.mid(6).trimmed();
            break;
        }
    }
    configFile.close();

    if (imagePath.isEmpty())
        return QString();

    // 3. Resolve the path — handle file:// scheme and directories
    QString localPath = imagePath;
    if (localPath.startsWith(QStringLiteral("file://")))
        localPath = localPath.mid(7);

    QFileInfo info(localPath);
    if (info.isDir()) {
        // KDE wallpaper dirs contain contents/images/ and/or contents/images_dark/
        // Pick the directory matching the current color scheme first
        bool dark = isDarkColorScheme();
        QStringList subDirs;
        if (dark) {
            subDirs = {
                QStringLiteral("/contents/images_dark"),
                QStringLiteral("/contents/images")
            };
        } else {
            subDirs = {
                QStringLiteral("/contents/images"),
                QStringLiteral("/contents/images_dark")
            };
        }
        QStringList filters = {QStringLiteral("*.jpg"), QStringLiteral("*.jpeg"),
                               QStringLiteral("*.png"), QStringLiteral("*.svg")};
        for (const QString& sub : subDirs) {
            QDir imgDir(localPath + sub);
            if (imgDir.exists()) {
                QStringList entries = imgDir.entryList(filters, QDir::Files, QDir::Size);
                if (!entries.isEmpty())
                    return imgDir.absoluteFilePath(entries.first());
            }
        }
        return QString();
    }

    return localPath;
}

QString WallpaperHelper::wallpaperBrightness(const QString& path) const {
    if (path.isEmpty())
        return QStringLiteral("dark");

    QImage img(path);
    if (img.isNull())
        return QStringLiteral("dark");

    // Scale down to 50x50 for fast processing
    QImage scaled = img.scaled(50, 50, Qt::IgnoreAspectRatio, Qt::FastTransformation);

    // Sample a 5×5 grid from the center
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

    if (count == 0)
        return QStringLiteral("dark");

    double brightness = 0.299 * (sumR / count) + 0.587 * (sumG / count) + 0.114 * (sumB / count);
    return brightness < 0.5 ? QStringLiteral("dark") : QStringLiteral("light");
}
