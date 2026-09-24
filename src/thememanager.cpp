#include "thememanager.h"
#include "mrtarchive.h"
#include "logger.h"
#include "previewrenderer.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QStandardPaths>
#include <QNetworkRequest>
#include <QUrl>
#include <QFontDatabase>
#include <functional>
#include <QTimer>
#include <QScreen>
#include <QProcess>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMap>
#include <QDBusInterface>
#include <QDBusMessage>
#include <QDBusObjectPath>
#include <QRegularExpression>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QGuiApplication>
#include <QDebug>
#include <QPalette>
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

QStringList ThemeManager::configKeys() const
{
    return {
        QStringLiteral("show_day"), QStringLiteral("show_date"), QStringLiteral("show_time"),
        QStringLiteral("show_timezone"),
        QStringLiteral("day_font_size"), QStringLiteral("date_font_size"),
        QStringLiteral("time_font_size"),
        QStringLiteral("timezone_font_size"),
        QStringLiteral("day_letter_spacing"), QStringLiteral("date_letter_spacing"),
        QStringLiteral("time_letter_spacing"),
        QStringLiteral("timezone_letter_spacing"),
        QStringLiteral("day_font_color"), QStringLiteral("date_font_color"),
        QStringLiteral("time_font_color"),
        QStringLiteral("timezone_font_color"),
        QStringLiteral("day_font_bold"), QStringLiteral("date_font_bold"),
        QStringLiteral("time_font_bold"),
        QStringLiteral("timezone_font_bold"),
        QStringLiteral("day_format"), QStringLiteral("date_format"),
        QStringLiteral("time_format"), QStringLiteral("timezone_format"),
        QStringLiteral("time_character"),
        QStringLiteral("use_24_hour_format"), QStringLiteral("uppercase_day"),
        QStringLiteral("uppercase_date"),
        QStringLiteral("fontFamilyDay"), QStringLiteral("fontFamilyDate"),
        QStringLiteral("fontFamilyTime"),
        QStringLiteral("fontFamilyTimezone"),
        QStringLiteral("widget_spacing"), QStringLiteral("element_order"),
        QStringLiteral("auto_scale"), QStringLiteral("color_mode"), QStringLiteral("locale"),
        QStringLiteral("timezone_id"), QStringLiteral("timezone_label"),
        QStringLiteral("timezone_display_text")
    };
}

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
        if (!f.open(QIODevice::ReadOnly)) continue;
        QString name = QFileInfo(fontPath).fileName();
        entries.append({QStringLiteral("fonts/") + name, f.readAll()});

        // License file
        QString fontDir = QFileInfo(fontPath).absolutePath();
        for (const QString &sfx : {QStringLiteral("LICENSE"), QStringLiteral("OFL.txt"),
                                     QStringLiteral("LICENSE.txt"), QStringLiteral("LICENSE.md")}) {
            QString lic = fontDir + "/" + sfx;
            if (QFile::exists(lic)) {
                QFile lf(lic);
                if (lf.open(QIODevice::ReadOnly))
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

// ===== THEME WALLPAPER =====

bool ThemeManager::hasThemeWallpaper(const QString &themePath)
{
    const auto entries = MrtArchive::read(themePath);
    for (const auto &entry : entries) {
        if (entry.name.startsWith(QStringLiteral("wallpaper.")))
            return true;
    }
    return false;
}

QString ThemeManager::extractThemeWallpaper(const QString &themePath, const QString &themeId)
{
    const auto entries = MrtArchive::read(themePath);
    for (const auto &entry : entries) {
        if (!entry.name.startsWith(QStringLiteral("wallpaper.")) || entry.data.isEmpty())
            continue;

        // Sanitize theme id for use in a filename
        QString safeId = themeId;
        safeId.remove(QRegularExpression(QStringLiteral("[^A-Za-z0-9_-]")));
        if (safeId.isEmpty()) safeId = QStringLiteral("theme");

        const QString dir = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation)
                            + QStringLiteral("/wallpapers");
        QDir().mkpath(dir);

        const QString ext = entry.name.mid(QStringLiteral("wallpaper.").length());
        const QString dest = dir + QStringLiteral("/") + safeId + QStringLiteral(".") + ext;

        QFile out(dest);
        if (!out.open(QIODevice::WriteOnly)) {
            if (m_log) m_log->warn("theme", "cannot write wallpaper: " + dest);
            return {};
        }
        out.write(entry.data);
        out.close();
        if (m_log) m_log->info("theme", "theme wallpaper extracted: " + dest);
        return dest;
    }

    if (m_log) m_log->warn("theme", "no wallpaper entry in theme: " + themePath);
    return {};
}

void ThemeManager::setDesktopWallpaper(const QString &imagePath)
{
    const QFileInfo fi(imagePath);
    if (!fi.exists() || !fi.isReadable()) {
        if (m_log) m_log->warn("theme", "setDesktopWallpaper: unreadable image " + imagePath);
        return;
    }
    const QString fileUrl = QUrl::fromLocalFile(fi.absoluteFilePath()).toString();

    // Apply to the desktop containment(s) hosting our widget; all desktops as fallback.
    const QString js = QStringLiteral(
        "(function() {\n"
        "  var WIDGET = 'com.github.yoanndev90.modernreclock';\n"
        "  var URL = '%1';\n"
        "  function apply(d) {\n"
        "    d.wallpaperPlugin = 'org.kde.image';\n"
        "    d.currentConfigGroup = ['Wallpaper', 'org.kde.image', 'General'];\n"
        "    d.writeConfig('Image', URL);\n"
        "  }\n"
        "  var targets = [];\n"
        "  var ds = desktops();\n"
        "  for (var i = 0; i < ds.length; ++i) {\n"
        "    var ws = ds[i].widgets();\n"
        "    for (var j = 0; j < ws.length; ++j) {\n"
        "      if (String(ws[j].type) === WIDGET) { targets.push(ds[i]); break; }\n"
        "    }\n"
        "  }\n"
        "  if (targets.length === 0) targets = ds;\n"
        "  for (var k = 0; k < targets.length; ++k) apply(targets[k]);\n"
        "})();").arg(fileUrl);

    QDBusMessage msg = QDBusMessage::createMethodCall(
        QStringLiteral("org.kde.plasmashell"), QStringLiteral("/PlasmaShell"),
        QStringLiteral("org.kde.PlasmaShell"), QStringLiteral("evaluateScript"));
    msg << js;
    // Async on purpose: we run inside plasmashell itself — a blocking call
    // back into the same process could deadlock the main thread.
    QDBusConnection::sessionBus().asyncCall(msg);
    if (m_log) m_log->info("theme", "setDesktopWallpaper requested: " + fileUrl);
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

void ThemeManager::doFetch(const QUrl &url,
                            const std::function<void(QByteArray)> &onSuccess,
                            const std::function<void()> &onFailure,
                            int timeoutMs)
{
    QNetworkRequest request{url};
    // Set a reasonable timeout for network requests
    request.setTransferTimeout(timeoutMs);
    QNetworkReply *reply = m_net->get(request);

    QTimer *timer = new QTimer(reply);
    timer->setSingleShot(true);
    connect(timer, &QTimer::timeout, reply, [reply, timer, onFailure]() {
        reply->abort();
        reply->deleteLater();
        if (onFailure) onFailure();
    });
    timer->start(timeoutMs + 1000); // Slightly longer than transfer timeout

    connect(reply, &QNetworkReply::finished, this, [this, reply, timer, onSuccess, onFailure]() {
        timer->stop();
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            if (m_log) m_log->warn("theme", "network error: " + reply->errorString());
            if (onFailure) onFailure();
            return;
        }
        QByteArray data = reply->readAll();
        if (onSuccess) onSuccess(data);
    });
}

void ThemeManager::fetchIndex()
{
    doFetch(QUrl(INDEX_URL),
        [this](const QByteArray &data) {
            QFile file(m_cacheDir + "/index.json");
            if (file.open(QIODevice::WriteOnly)) {
                file.write(data);
                file.close();
            }
            emit indexFetchComplete(true, QString::fromUtf8(data));
        },
        [this]() {
            emit indexFetchComplete(false, {});
        }
    );
}

void ThemeManager::downloadTheme(const QString &themeId, const QString &url)
{
    doFetch(QUrl(url),
        [this, themeId](const QByteArray &data) {
            QFile file(m_cacheDir + "/themes/" + themeId + ".zip");
            if (!file.open(QIODevice::WriteOnly)) {
                emit themeDownloaded(themeId, false);
                return;
            }
            file.write(data);
            file.close();
            emit themeDownloaded(themeId, true);
        },
        [this, themeId]() {
            emit themeDownloaded(themeId, false);
        }
    );
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
    return m_cacheDir + "/themes/" + themeId + ".zip";
}

// ===== PREVIEW GENERATOR =====

QRect ThemeManager::findWidgetGeometry()
{
    // Read plasma config file to find our widget's geometry
    // Format: ~/.config/plasma-org.kde.plasma.desktop-appletsrc
    QString configPath = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation)
                          + QStringLiteral("/plasma-org.kde.plasma.desktop-appletsrc");
    QFile file(configPath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        if (m_log) m_log->info("theme", "plasma config not found: " + configPath);
        return {};
    }

    QByteArray data = file.readAll();
    file.close();
    QString text = QString::fromUtf8(data);
    if (m_log) m_log->info("theme", "plasma config: " + configPath + " (" + QByteArray::number(data.size()) + " bytes)");

    // Find the applet section containing our plugin
    int appletId = -1;
    int containmentId = -1;
    QRegularExpression pluginRe(QStringLiteral("plugin\\s*=\\s*com\\.github\\.yoanndev90\\.modernreclock"));
    QRegularExpression sectionRe(QStringLiteral("\\[Containments\\]\\[(\\d+)\\]\\[Applets\\]\\[(\\d+)\\]"));

    // Split into lines and find our applet
    QStringList lines = text.split(QLatin1Char('\n'));
    int currentContainment = -1;
    int currentApplet = -1;

    for (const QString &line : lines) {
        // Track which section we're in
        QRegularExpressionMatch m = sectionRe.match(line);
        if (m.hasMatch()) {
            currentContainment = m.captured(1).toInt();
            currentApplet = m.captured(2).toInt();
        }

        // Check if this line is our plugin
        if (pluginRe.match(line).hasMatch() && currentApplet >= 0) {
            appletId = currentApplet;
            containmentId = currentContainment;
            if (m_log) m_log->info("theme", "found applet: containment=" + QString::number(containmentId) + " applet=" + QString::number(appletId));
            break;
        }
    }

    if (appletId < 0) {
        if (m_log) m_log->info("theme", "modernreclock widget not found in plasma config");
        return {};
    }

    // Find geometry line: ItemGeometries-<width>x<height>=Applet-N:x,y,w,h,...
    QScreen *screen = QGuiApplication::primaryScreen();
    int screenW = screen ? screen->size().width() : 1920;
    int screenH = screen ? screen->size().height() : 1080;

    QRegularExpression geoRe(QStringLiteral("ItemGeometries-(\\d+)x(\\d+)\\s*=\\s*(.*)"));
    QString searchPrefix = QStringLiteral("Applet-%1:").arg(appletId);

    for (const QString &line : lines) {
        QRegularExpressionMatch gm = geoRe.match(line);
        if (!gm.hasMatch()) continue;
        int w = gm.captured(1).toInt();
        int h = gm.captured(2).toInt();

        // Match closest resolution
        if (qAbs(w - screenW) > 100 || qAbs(h - screenH) > 100) continue;

        QString values = gm.captured(3);
        // Parse: Applet-5:x,y,w,h,0;Applet-6:x,y,w,h,0;...
        // Split by semicolons and find our applet
        for (const QString &entry : values.split(QLatin1Char(';'), Qt::SkipEmptyParts)) {
            if (entry.startsWith(searchPrefix)) {
                QString coords = entry.mid(searchPrefix.length());
                QStringList parts = coords.split(QLatin1Char(','));
                if (parts.size() >= 4) {
                    QRect r(parts[0].toInt(), parts[1].toInt(), parts[2].toInt(), parts[3].toInt());
                    if (m_log) m_log->info("theme", "WIDGET GEOMETRY: " + QString("%1,%2 %3x%4").arg(r.x()).arg(r.y()).arg(r.width()).arg(r.height()));
                    return r;
                }
            }
        }
    }

    if (m_log) m_log->info("theme", "geometry not found for applet " + QString::number(appletId));
    return {};
}

// ===== PREVIEW =====
// Renderer lives in previewrenderer.{h,cpp} (shared by sync + async paths).

QString ThemeManager::generatePreview(const QString &jsonConfig,
                                       const QString &wallpaperPath,
                                       int appletId,
                                       const QStringList &fontPaths,
                                       const QString &customDate,
                                       const QString &customDayName)
{
    Q_UNUSED(appletId)
    if (m_log) m_log->info("theme", "=== generatePreview START ===");
    QDir().mkpath(m_cacheDir + QStringLiteral("/previews"));
    QString outPath = m_cacheDir + QStringLiteral("/previews/export_preview.png");

    // Load fonts on calling (main) thread — QFontDatabase is not thread-safe
    QStringList loadedFamilies;
    for (const QString &fp : fontPaths) {
        int id = QFontDatabase::addApplicationFont(fp);
        QStringList families = QFontDatabase::applicationFontFamilies(id);
        if (m_log) m_log->info("theme", QString("font load: %1 id:%2 families:[%3]").arg(fp).arg(id).arg(families.join(", ")));
        loadedFamilies.append(families);
    }

    QScreen *screen = QGuiApplication::primaryScreen();
    PreviewParams params;
    params.jsonConfig = jsonConfig;
    params.wallpaperPath = wallpaperPath;
    params.screenSize = screen ? screen->size() : QSize(1920, 1080);
    params.widgetRect = findWidgetGeometry();
    params.loadedFamilies = loadedFamilies;
    params.themeTextColor = QGuiApplication::palette().color(QPalette::WindowText);
    params.outPath = outPath;
    params.customDate = customDate;
    params.customDayName = customDayName;
    params.log = m_log;
    return renderPreviewImage(params);
}

QString ThemeManager::fallbackPreview(const QString &outPath)
{
    return writeFallbackPreview(outPath);
}

void ThemeManager::generatePreviewAsync(const QString &jsonConfig,
                                        const QString &wallpaperPath,
                                        int appletId,
                                        const QStringList &fontPaths,
                                        const QString &customDate,
                                        const QString &customDayName)
{
    // Guard: if a render is already in progress, queue the latest request
    if (m_previewBusy) {
        m_pendingPreviewConfig = jsonConfig;
        m_pendingPreviewWp = wallpaperPath;
        m_pendingPreviewAppletId = appletId;
        m_pendingPreviewFonts = fontPaths;
        m_pendingPreviewDate = customDate;
        m_pendingPreviewDay = customDayName;
        return;
    }
    m_previewBusy = true;

    // Pre-load fonts on main thread (QFontDatabase is not thread-safe)
    QStringList loadedFamilies;
    for (const QString &fp : fontPaths) {
        int id = QFontDatabase::addApplicationFont(fp);
        loadedFamilies.append(QFontDatabase::applicationFontFamilies(id));
    }

    // Capture thread-unsafe state on main thread
    QScreen *screen = QGuiApplication::primaryScreen();
    QSize screenSize = screen ? screen->size() : QSize(1920, 1080);
    QRect widgetRect = findWidgetGeometry();
    QColor themeTextColor = QGuiApplication::palette().color(QPalette::WindowText);

    QString cacheDir = m_cacheDir;
    Logger *log = m_log;
    QPointer<ThemeManager> guard(this);

    [[maybe_unused]] auto future = QtConcurrent::run(
        [guard, jsonConfig, wallpaperPath, loadedFamilies, screenSize, widgetRect,
         cacheDir, log, customDate, customDayName, themeTextColor]() {
            if (!guard) return;
            QDir().mkpath(cacheDir + QStringLiteral("/previews"));

            PreviewParams params;
            params.jsonConfig = jsonConfig;
            params.wallpaperPath = wallpaperPath;
            params.screenSize = screenSize;
            params.widgetRect = widgetRect;
            params.loadedFamilies = loadedFamilies;
            params.themeTextColor = themeTextColor;
            params.outPath = cacheDir + QStringLiteral("/previews/export_preview.png");
            params.customDate = customDate;
            params.customDayName = customDayName;
            params.log = log;

            const QString outPath = renderPreviewImage(params);
            if (guard) emit guard->previewGenerated(outPath);

            // Drain pending request on main thread
            if (guard) {
                QMetaObject::invokeMethod(guard, [guard]() {
                    if (!guard) return; // ThemeManager destroyed; drop pending work
                    guard->m_previewBusy = false;
                    if (!guard->m_pendingPreviewConfig.isEmpty()) {
                        QString cfg = guard->m_pendingPreviewConfig;
                        QString wp = guard->m_pendingPreviewWp;
                        int aid = guard->m_pendingPreviewAppletId;
                        QStringList fonts = guard->m_pendingPreviewFonts;
                        QString date = guard->m_pendingPreviewDate;
                        QString day = guard->m_pendingPreviewDay;
                        guard->m_pendingPreviewConfig.clear();
                        guard->generatePreviewAsync(cfg, wp, aid, fonts, date, day);
                    }
                }, Qt::QueuedConnection);
            }
        });
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
