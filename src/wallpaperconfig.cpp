#include "wallpaperconfig.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QStandardPaths>
#include <QTextStream>
#include <QDebug>
#include <QRegularExpression>

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

    // Collect all lines once; we need several passes (widget lookup + sections)
    QStringList lines;
    {
        QTextStream in(&configFile);
        while (!in.atEnd())
            lines << in.readLine();
    }
    configFile.close();

    // --- Pass 1: find the containment that hosts our widget, if any ---
    const QRegularExpression pluginRe(
        QStringLiteral("plugin\\s*=\\s*com\\.github\\.yoanndev90\\.modernreclock"));
    const QRegularExpression appletSectionRe(
        QStringLiteral("\\[Containments\\]\\[(\\d+)\\]\\[Applets\\]\\[(\\d+)\\]"));

    int targetContainment = -1;
    int currentContainment = -1;
    int currentApplet = -1;
    for (const QString& rawLine : lines) {
        const QString line = rawLine.trimmed();

        const auto sectionMatch = appletSectionRe.match(line);
        if (sectionMatch.hasMatch()) {
            currentContainment = sectionMatch.captured(1).toInt();
            currentApplet = sectionMatch.captured(2).toInt();
        }

        if (currentApplet >= 0 && pluginRe.match(line).hasMatch()) {
            targetContainment = currentContainment;
            break;
        }
    }
    qDebug() << "[ModernRecClock] WallpaperConfig: widget containment =" << targetContainment;

    // --- Pass 2: collect Image= keys with containment-aware priority ---
    //   bucketA: [Containments][T][Wallpaper][org.kde.image][General]  (target, exact)
    //   bucketB: any [Containments][T][Wallpaper][...]                 (target)
    //   bucketC: any [Containments][*][Wallpaper][org.kde.image][General]
    //   bucketD: first Image= anywhere (legacy behaviour, last resort)
    const QRegularExpression headerRe(QStringLiteral("^\\[(.+)\\]$"));
    QString secA, secB, secC, secD;
    QString currentSection;
    bool isTarget = false;
    bool isTargetExactGeneral = false;
    bool isAnyImageGeneral = false;

    for (const QString& rawLine : lines) {
        const QString line = rawLine.trimmed();
        if (line.isEmpty() || line.startsWith('#'))
            continue;

        const auto headerMatch = headerRe.match(line);
        if (headerMatch.hasMatch()) {
            currentSection = headerMatch.captured(1);
            const QString targetPrefix =
                QStringLiteral("Containments][%1][Wallpaper]").arg(targetContainment);
            isTarget = targetContainment >= 0 && currentSection.startsWith(targetPrefix);
            isTargetExactGeneral = isTarget &&
                currentSection == targetPrefix + QStringLiteral("org.kde.image][General]");
            isAnyImageGeneral =
                currentSection.startsWith(QStringLiteral("Containments]")) &&
                currentSection.endsWith(QStringLiteral("[org.kde.image][General]"));
            continue;
        }

        if (!line.startsWith(QStringLiteral("Image=")))
            continue;
        const QString value = line.mid(6).trimmed();
        if (value.isEmpty())
            continue;

        if (secD.isEmpty()) secD = value;
        if (isAnyImageGeneral && secC.isEmpty()) secC = value;
        if (isTarget && secB.isEmpty()) secB = value;
        if (isTargetExactGeneral && secA.isEmpty()) secA = value;
    }

    qDebug() << "[ModernRecClock] WallpaperConfig buckets:"
             << "A=" << secA << "B=" << secB << "C=" << secC << "D=" << secD;

    QString imagePath;
    if (!secA.isEmpty())
        imagePath = secA;
    else if (!secB.isEmpty())
        imagePath = secB;
    else if (!secC.isEmpty())
        imagePath = secC;
    else
        imagePath = secD;

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
