#include "thememanager.h"
#include "mrtarchive.h"
#include "logger.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QStandardPaths>
#include <QNetworkRequest>
#include <QUrl>
#include <QEventLoop>
#include <QFontDatabase>
#include <QScreen>
#include <QImage>
#include <QPixmap>
#include <QPainter>
#include <QProcess>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMap>
#include <QDBusInterface>
#include <QDBusMessage>
#include <QGuiApplication>
#include <QDebug>
#include <fontconfig/fontconfig.h>

static const QString FONTS_CACHE_SUBDIR = QStringLiteral("modernreclock-fonts");
static const QString INDEX_URL = QStringLiteral(
    "https://raw.githubusercontent.com/YoannDev90/KDE-Modern-reClock/"
    "main/community_themes/themes.json");

ThemeManager::ThemeManager(QObject *parent)
    : QObject(parent)
    , m_net(new QNetworkAccessManager(this))
{
    m_cacheDir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation)
                 + QStringLiteral("/modernreclock");
    QDir().mkpath(m_cacheDir);
    QDir().mkpath(m_cacheDir + QStringLiteral("/fonts"));
    QDir().mkpath(m_cacheDir + QStringLiteral("/themes"));
    QDir().mkpath(m_cacheDir + QStringLiteral("/previews"));
}

ThemeManager::~ThemeManager() {}

QString ThemeManager::cacheDir() const { return m_cacheDir; }

// ===== EXPORT =====

QString ThemeManager::exportTheme(const QString &filePath,
                                   const QString &jsonConfig,
                                   const QStringList &embedFonts,
                                   const QString &wallpaperPath)
{
    QList<MrtArchiveEntry> entries;
    // First entry = mimetype (ODF convention) for MIME detection by file managers
    entries.append({QStringLiteral("mimetype"), QStringLiteral("application/zip").toUtf8()});
    entries.append({QStringLiteral("theme.json"), jsonConfig.toUtf8()});

    if (m_log) m_log->info("theme", QString("exportTheme: %1").arg(filePath));
    if (m_log) m_log->info("theme", QString("jsonConfig size: %1").arg(jsonConfig.size()));
    if (m_log) m_log->info("theme", QString("embedFonts: [%1]").arg(embedFonts.join(", ")));
    if (m_log) m_log->info("theme", QString("wallpaperPath: %1").arg(wallpaperPath));

    // Preview image (if captured)
    QString previewPath = m_cacheDir + QStringLiteral("/previews/export_preview.png");
    if (m_log) m_log->info("theme", QString("checking preview: %1 exists: %2").arg(previewPath).arg(QFile::exists(previewPath)));
    if (QFile::exists(previewPath)) {
        QFile pf(previewPath);
        if (pf.open(QIODevice::ReadOnly)) {
            QByteArray data = pf.readAll();
            if (m_log) m_log->info("theme", QString("preview size: %1").arg(data.size()));
            entries.append({QStringLiteral("preview.png"), data});
            pf.close();
        }
    }

    for (const QString &fontPath : embedFonts) {
        QFile f(fontPath);
        if (!f.exists()) continue;
        f.open(QIODevice::ReadOnly);
        QString name = QFileInfo(fontPath).fileName();
        entries.append({QStringLiteral("fonts/") + name, f.readAll()});

        // License file
        QString fontDir = QFileInfo(fontPath).absolutePath();
        for (const QString &sfx : {QStringLiteral("LICENSE"), QStringLiteral("OFL.txt"),
                                     QStringLiteral("LICENSE.txt"), QStringLiteral("LICENSE.md")}) {
            QString lic = fontDir + "/" + sfx;
            if (QFile::exists(lic)) {
                QFile lf(lic);
                lf.open(QIODevice::ReadOnly);
                entries.append({QStringLiteral("fonts/") + name + QStringLiteral(".license"), lf.readAll()});
                break;
            }
        }
    }

    // Wallpaper image (if available and color_mode is wallpaper)
    if (m_log) m_log->info("theme", QString("checking wallpaper: %1 exists: %2").arg(wallpaperPath).arg(QFile::exists(wallpaperPath)));
    if (QFile::exists(wallpaperPath)) {
        QFile wf(wallpaperPath);
        if (wf.open(QIODevice::ReadOnly)) {
            QString ext = QFileInfo(wallpaperPath).suffix();
            if (ext.isEmpty()) ext = QStringLiteral("png");
            entries.append({QStringLiteral("wallpaper.") + ext, wf.readAll()});
            wf.close();
        }
    }

    if (m_log) m_log->info("theme", QString("entries count: %1").arg(entries.size()));
    if (!MrtArchive::write(filePath, entries)) {
        if (m_log) m_log->info("theme", "FAILED to write archive");
        emit errorOccurred(QStringLiteral("Cannot create: %1").arg(filePath));
        return {};
    }
    if (m_log) m_log->info("theme", "export OK");
    return filePath;
}

// ===== IMPORT =====

QString ThemeManager::parseTheme(const QString &filePath)
{
    QByteArray data = MrtArchive::readSingle(filePath, QStringLiteral("theme.json"));
    if (data.isEmpty()) {
        emit errorOccurred(QStringLiteral("Cannot open: %1").arg(filePath));
        return {};
    }
    return QString::fromUtf8(data);
}

// ===== FONTS =====

QStringList ThemeManager::installThemeFonts(const QString &themePath)
{
    QStringList fontPaths;
    QList<MrtArchiveEntry> entries = MrtArchive::read(themePath);
    QString fontsDir = m_cacheDir + QStringLiteral("/fonts");
    QDir().mkpath(fontsDir);

    for (const auto &entry : entries) {
        if (!entry.name.startsWith(QStringLiteral("fonts/")))
            continue;
        QString fileName = entry.name.mid(6); // strip "fonts/"
        if (!fileName.endsWith(QStringLiteral(".ttf"), Qt::CaseInsensitive) &&
            !fileName.endsWith(QStringLiteral(".otf"), Qt::CaseInsensitive))
            continue;

        QString dest = fontsDir + "/" + fileName;
        QFile out(dest);
        if (!out.open(QIODevice::WriteOnly)) continue;
        out.write(entry.data);
        out.close();

        int id = QFontDatabase::addApplicationFont(dest);
        if (id != -1) fontPaths.append(dest);
    }

    return fontPaths;
}

void ThemeManager::cleanupTempFonts(const QStringList &fontPaths)
{
    for (const QString &path : fontPaths)
        QFile::remove(path);
}

QString ThemeManager::resolveFontPath(const QString &familyName)
{
    FcPattern *pattern = FcPatternCreate();
    FcPatternAddString(pattern, FC_FAMILY,
        reinterpret_cast<const FcChar8 *>(familyName.toUtf8().constData()));
    FcConfigSubstitute(nullptr, pattern, FcMatchPattern);
    FcDefaultSubstitute(pattern);

    FcResult result;
    FcPattern *match = FcFontMatch(nullptr, pattern, &result);
    if (!match) {
        FcPatternDestroy(pattern);
        return {};
    }

    FcChar8 *path = nullptr;
    QString out;
    if (FcPatternGetString(match, FC_FILE, 0, &path) == FcResultMatch)
        out = QString::fromUtf8(reinterpret_cast<const char *>(path));

    FcPatternDestroy(match);
    FcPatternDestroy(pattern);
    return out;
}

// ===== GALLERY NETWORK =====

void ThemeManager::fetchIndex()
{
    QNetworkRequest request{QUrl(INDEX_URL)};
    QNetworkReply *reply = m_net->get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit indexFetchComplete(false);
            return;
        }
        QByteArray data = reply->readAll();
        QFile file(m_cacheDir + "/index.json");
        if (file.open(QIODevice::WriteOnly)) {
            file.write(data);
            file.close();
        }
        emit indexFetchComplete(true);
    });
}

bool ThemeManager::downloadTheme(const QString &themeId, const QString &url)
{
    QNetworkRequest request{QUrl(url)};
    QNetworkReply *reply = m_net->get(request);
    QEventLoop loop;
    connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
    loop.exec();

    if (reply->error() != QNetworkReply::NoError) {
        reply->deleteLater();
        emit themeDownloaded(themeId, false);
        return false;
    }

    QByteArray data = reply->readAll();
    reply->deleteLater();

    QFile file(m_cacheDir + "/themes/" + themeId + ".mrt");
    if (!file.open(QIODevice::WriteOnly)) {
        emit themeDownloaded(themeId, false);
        return false;
    }
    file.write(data);
    file.close();

    emit themeDownloaded(themeId, true);
    return true;
}

void ThemeManager::clearCache()
{
    QDir(m_cacheDir + "/themes").removeRecursively();
    QDir(m_cacheDir + "/fonts").removeRecursively();
    QDir().mkpath(m_cacheDir + "/themes");
    QDir().mkpath(m_cacheDir + "/fonts");
}

// ===== GALLERY CACHE =====

QString ThemeManager::cachedPreviewPath(const QString &themeId)
{
    return m_cacheDir + "/previews/" + themeId + ".png";
}

QString ThemeManager::cachedThemePath(const QString &themeId)
{
    return m_cacheDir + "/themes/" + themeId + ".mrt";
}

// ===== PREVIEW GENERATOR =====

static QRect queryWidgetGeometry(int appletId)
{
    if (appletId < 0) return {};
    QDBusInterface iface(QStringLiteral("org.kde.plasmashell"),
                          QStringLiteral("/Applets/%1").arg(appletId),
                          QStringLiteral("org.kde.plasma.Applet"));
    if (!iface.isValid()) return {};

    QDBusMessage reply = iface.call(QStringLiteral("geometry"));
    if (reply.type() == QDBusMessage::ReplyMessage && reply.arguments().size() == 1) {
        QVariant v = reply.arguments().first();
        if (v.canConvert<QRect>()) return v.toRect();
    }

    QDBusInterface props(QStringLiteral("org.kde.plasmashell"),
                          QStringLiteral("/Applets/%1").arg(appletId),
                          QStringLiteral("org.freedesktop.DBus.Properties"));
    QDBusMessage get = props.call(QStringLiteral("Get"),
                                   QStringLiteral("org.kde.plasma.Applet"),
                                   QStringLiteral("geometry"));
    if (get.type() == QDBusMessage::ReplyMessage && get.arguments().size() == 1) {
        QVariant v = get.arguments().first();
        if (v.canConvert<QRect>()) return v.toRect();
    }

    return {};
}

QString ThemeManager::generatePreview(const QString &jsonConfig,
                                       const QString &wallpaperPath,
                                       int appletId,
                                       const QStringList &fontPaths)
{
    if (m_log) m_log->info("theme", QString("generatePreview appletId: %1").arg(appletId));
    QDir().mkpath(m_cacheDir + QStringLiteral("/previews"));
    QString outPath = m_cacheDir + QStringLiteral("/previews/export_preview.png");

    // Load fonts before rendering
    QStringList loadedFamilies;
    for (const QString &fp : fontPaths) {
        int id = QFontDatabase::addApplicationFont(fp);
        QStringList families = QFontDatabase::applicationFontFamilies(id);
        if (m_log) m_log->info("theme", QString("font: %1 id: %2 families: %3").arg(fp).arg(id).arg(families.join(", ")));
        loadedFamilies.append(families);
    }
    if (m_log) m_log->info("theme", QString("all loaded families: [%1]").arg(loadedFamilies.join(", ")));

    // Build a lookup from config family name to actual loaded family name
    auto resolveFamily = [&](const QString &configName) -> QString {
        if (configName.isEmpty()) return {};
        // Exact match
        if (loadedFamilies.contains(configName)) return configName;
        // Case-insensitive or partial match
        QString lower = configName.toLower();
        for (const QString &f : loadedFamilies) {
            if (f.toLower() == lower || f.toLower().contains(lower) || lower.contains(f.toLower()))
                return f;
        }
        return configName; // fallback to config name
    };

    QJsonDocument doc = QJsonDocument::fromJson(jsonConfig.toUtf8());
    if (doc.isNull() || !doc.isObject()) {
        if (m_log) m_log->info("theme", "invalid config JSON");
        return fallbackPreview(outPath);
    }
    QJsonObject cfg = doc.object();

    // Load wallpaper full resolution
    QImage canvas;
    if (QFile::exists(wallpaperPath)) {
        canvas = QImage(wallpaperPath);
        if (m_log) m_log->info("theme", QString("wallpaper: %1x%2").arg(canvas.width()).arg(canvas.height()));
    }
    if (canvas.isNull()) {
        canvas = QImage(1920, 1080, QImage::Format_ARGB32);
        canvas.fill(QColor(42, 42, 50));
    }

    // Scale factor from screen to wallpaper
    QScreen *screen = QGuiApplication::primaryScreen();
    double scaleX = 1.0, scaleY = 1.0;
    if (screen && !canvas.isNull()) {
        QSize screenSize = screen->size();
        scaleX = (double)canvas.width() / screenSize.width();
        scaleY = (double)canvas.height() / screenSize.height();
        if (m_log) m_log->info("theme", QString("screen: %1 scale: %2x%3").arg(screenSize.width()).arg(scaleX, 0, 'f', 2).arg(scaleY, 0, 'f', 2));
    }

    // Widget geometry on screen
    QRect widgetRect = queryWidgetGeometry(appletId);
    if (m_log) m_log->info("theme", QString("widget geomscreen: %1,%2 %3x%4").arg(widgetRect.x()).arg(widgetRect.y()).arg(widgetRect.width()).arg(widgetRect.height()));

    // Position on wallpaper
    int baseX = widgetRect.isValid() ? qRound(widgetRect.x() * scaleX) : 0;
    int baseY = widgetRect.isValid() ? qRound(widgetRect.y() * scaleY) : 0;
    int elemWidth = widgetRect.isValid() ? qRound(widgetRect.width() * scaleX) : canvas.width();
    // Font scale: use geometric mean of scale factors
    double fontScale = qMin(scaleX, scaleY);

    // Parse order
    QString orderStr = cfg.value(QStringLiteral("element_order"))
                          .toString(QStringLiteral("day,date,time,custom,timezone"));
    QStringList order = orderStr.split(',');

    int spacing = qRound(cfg.value(QStringLiteral("widget_spacing")).toDouble(5) * fontScale);

    struct ClockElement {
        bool visible;
        int fontSize;
        bool bold;
        QColor color;
        QString family;
        QString sampleText;
    };
    QMap<QString, ClockElement> elements;

    auto addElement = [&](const QString &name, const QString &fontKey, int defaultSize,
                          const QString &sample) {
        ClockElement e;
        e.visible = cfg.value(QStringLiteral("show_") + name).toBool(true);
        e.family = cfg.value(QStringLiteral("fontFamily") + fontKey).toString();
        e.fontSize = qRound(cfg.value(name + QStringLiteral("_font_size")).toDouble(defaultSize) * fontScale);
        e.bold = cfg.value(name + QStringLiteral("_font_bold")).toBool(false);
        e.color = QColor(cfg.value(name + QStringLiteral("_font_color")).toString(QStringLiteral("#FFFFFF")));
        if (!e.color.isValid()) e.color = Qt::white;
        e.sampleText = sample;
        elements.insert(name, e);
    };

    addElement(QStringLiteral("day"),    QStringLiteral("Day"),    72, QStringLiteral("Wednesday"));
    addElement(QStringLiteral("date"),  QStringLiteral("Date"),   19, QStringLiteral("15 Jan 2026"));
    addElement(QStringLiteral("time"),  QStringLiteral("Time"),   19, QStringLiteral("14:30:00"));
    addElement(QStringLiteral("custom"),QStringLiteral("Custom"), 19,
               cfg.value(QStringLiteral("custom_text")).toString(QStringLiteral("Custom Text")));
    addElement(QStringLiteral("timezone"), QStringLiteral("Timezone"), 14, QStringLiteral("UTC+8:00"));

    // Paint
    QPainter p(&canvas);
    p.setRenderHint(QPainter::TextAntialiasing);
    p.setRenderHint(QPainter::Antialiasing);
    int y = baseY;

    for (const QString &el : order) {
        if (!elements.contains(el)) continue;
        auto &e = elements[el];
        if (!e.visible) continue;

        QString resolvedFamily = resolveFamily(e.family);
        QFont f;
        if (!resolvedFamily.isEmpty())
            f = QFont(resolvedFamily, qMax(8, e.fontSize));
        else
            f = QFont(QStringLiteral("sans-serif"), qMax(8, e.fontSize));
        f.setPixelSize(qMax(8, e.fontSize));
        f.setBold(e.bold);
        if (m_log) m_log->info("theme", QString("paint %1 family: %2 → %3 size: %4 bold: %5").arg(el, e.family, resolvedFamily).arg(e.fontSize).arg(e.bold ? "yes" : "no"));
        p.setFont(f);
        p.setPen(e.color);
        p.drawText(QRect(baseX, y, elemWidth, e.fontSize + 4),
                   Qt::AlignLeft | Qt::AlignVCenter, e.sampleText);
        y += e.fontSize + spacing;
    }

    p.end();
    canvas.save(outPath, "PNG");
    qint64 size = QFileInfo(outPath).size();
    if (m_log) m_log->info("theme", QString("saved: %1 size: %2").arg(outPath).arg(size));
    return outPath;
}

QString ThemeManager::fallbackPreview(const QString &outPath)
{
    QPixmap fb(400, 225);
    fb.fill(QColor(42, 42, 50));
    QPainter p(&fb);
    p.setPen(Qt::white);
    p.setFont(QFont(QStringLiteral("sans-serif"), 12));
    p.drawText(fb.rect(), Qt::AlignCenter, QStringLiteral("Preview"));
    p.end();
    fb.toImage().save(outPath, "PNG");
    return outPath;
}



// ===== FONT PERSISTENCE =====

void ThemeManager::persistActiveFonts(const QStringList &fontPaths)
{
    QFile file(m_cacheDir + QStringLiteral("/active_fonts.txt"));
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) return;
    for (const QString &path : fontPaths)
        file.write(path.toUtf8() + "\n");
    file.close();
}

void ThemeManager::restorePersistedFonts()
{
    QFile file(m_cacheDir + QStringLiteral("/active_fonts.txt"));
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return;

    while (!file.atEnd()) {
        QString path = QString::fromUtf8(file.readLine()).trimmed();
        if (!path.isEmpty() && QFile::exists(path))
            QFontDatabase::addApplicationFont(path);
    }
    file.close();
}
