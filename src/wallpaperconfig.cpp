#include "wallpaperconfig.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QStandardPaths>
#include <QTextStream>
#include <QDebug>

QString WallpaperConfig::readKdeColorScheme() {
    QString globalsPath = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation)
        + QStringLiteral("/kdeglobals");
    QFile f(globalsPath);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qDebug() << "[ModernRecClock] WallpaperConfig::readKdeColorScheme FAILED to open" << globalsPath;
        return QString();
    }

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
            QString scheme = line.mid(12).trimmed();
            qDebug() << "[ModernRecClock] WallpaperConfig::readKdeColorScheme →" << scheme;
            return scheme;
        }
    }
    f.close();
    qDebug() << "[ModernRecClock] WallpaperConfig::readKdeColorScheme → (not found)";
    return QString();
}

bool WallpaperConfig::isDarkColorScheme() {
    QString scheme = readKdeColorScheme();
    if (scheme.isEmpty()) {
        qDebug() << "[ModernRecClock] WallpaperConfig::isDarkColorScheme → true (default)";
        return true;
    }
    bool dark = scheme.contains(QStringLiteral("dark"), Qt::CaseInsensitive);
    qDebug() << "[ModernRecClock] WallpaperConfig::isDarkColorScheme →" << dark;
    return dark;
}

QString WallpaperConfig::readWallpaperPath() {
    QString configPath = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation)
        + QStringLiteral("/plasma-org.kde.plasma.desktop-appletsrc");
    QFile configFile(configPath);
    if (!configFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qDebug() << "[ModernRecClock] WallpaperConfig::readWallpaperPath FAILED to open" << configPath;
        return QString();
    }

    QString imagePath;
    QTextStream in(&configFile);
    while (!in.atEnd()) {
        QString line = in.readLine().trimmed();
        if (line.isEmpty() || line.startsWith('#'))
            continue;
        if (line.startsWith(QStringLiteral("Image="))) {
            imagePath = line.mid(6).trimmed();
            break;
        }
    }
    configFile.close();

    if (imagePath.isEmpty()) {
        qDebug() << "[ModernRecClock] WallpaperConfig::readWallpaperPath → no Image= key found";
        return QString();
    }

    // Detect slideshow (XML) or color wallpapers
    if (imagePath.endsWith(QStringLiteral(".xml"), Qt::CaseInsensitive)) {
        qDebug() << "[ModernRecClock] WallpaperConfig::readWallpaperPath → slideshow XML, not a direct image:" << imagePath;
        return QStringLiteral("slideshow:") + imagePath;
    }
    if (imagePath.startsWith('#')) {
        qDebug() << "[ModernRecClock] WallpaperConfig::readWallpaperPath → color wallpaper:" << imagePath;
        return QString();
    }

    QString localPath = imagePath;
    if (localPath.startsWith(QStringLiteral("file://")))
        localPath = localPath.mid(7);

    QFileInfo info(localPath);
    if (info.isDir()) {
        bool dark = isDarkColorScheme();
        QStringList subDirs;
        if (dark) {
            subDirs = { QStringLiteral("/contents/images_dark"), QStringLiteral("/contents/images") };
        } else {
            subDirs = { QStringLiteral("/contents/images"), QStringLiteral("/contents/images_dark") };
        }
        QStringList filters = { QStringLiteral("*.jpg"), QStringLiteral("*.jpeg"),
                                QStringLiteral("*.png"), QStringLiteral("*.svg") };
        for (const QString& sub : subDirs) {
            QDir imgDir(localPath + sub);
            if (imgDir.exists()) {
                QStringList entries = imgDir.entryList(filters, QDir::Files, QDir::Size);
                if (!entries.isEmpty()) {
                    QString found = imgDir.absoluteFilePath(entries.first());
                    qDebug() << "[ModernRecClock] WallpaperConfig::readWallpaperPath →" << found;
                    return found;
                }
            }
        }
        qDebug() << "[ModernRecClock] WallpaperConfig::readWallpaperPath → dir but no images in" << localPath;
        return QString();
    }

    qDebug() << "[ModernRecClock] WallpaperConfig::readWallpaperPath →" << localPath;
    return localPath;
}
