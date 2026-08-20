#include "thememanager.h"
#include "mrtarchive.h"
#include "logger.h"

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
#include <QImage>
#include <QPixmap>
#include <QPainter>
#include <QTextLayout>
#include <QProcess>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMap>
#include <QDBusInterface>
#include <QDBusMessage>
#include <QDBusObjectPath>
#include <QRegularExpression>
#include <QGuiApplication>
#include <QRandomGenerator>
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

QStringList ThemeManager::configKeys() const
{
    return {
        QStringLiteral("show_day"), QStringLiteral("show_date"), QStringLiteral("show_time"),
        QStringLiteral("show_custom"), QStringLiteral("show_timezone"),
        QStringLiteral("day_font_size"), QStringLiteral("date_font_size"),
        QStringLiteral("time_font_size"), QStringLiteral("custom_font_size"),
        QStringLiteral("timezone_font_size"),
        QStringLiteral("day_letter_spacing"), QStringLiteral("date_letter_spacing"),
        QStringLiteral("time_letter_spacing"), QStringLiteral("custom_letter_spacing"),
        QStringLiteral("timezone_letter_spacing"),
        QStringLiteral("day_font_color"), QStringLiteral("date_font_color"),
        QStringLiteral("time_font_color"), QStringLiteral("custom_font_color"),
        QStringLiteral("timezone_font_color"),
        QStringLiteral("day_font_bold"), QStringLiteral("date_font_bold"),
        QStringLiteral("time_font_bold"), QStringLiteral("custom_font_bold"),
        QStringLiteral("timezone_font_bold"),
        QStringLiteral("day_format"), QStringLiteral("date_format"),
        QStringLiteral("time_format"), QStringLiteral("timezone_format"),
        QStringLiteral("time_character"),
        QStringLiteral("use_24_hour_format"), QStringLiteral("uppercase_day"),
        QStringLiteral("uppercase_date"), QStringLiteral("custom_format"),
        QStringLiteral("custom_text"),
        QStringLiteral("fontFamilyDay"), QStringLiteral("fontFamilyDate"),
        QStringLiteral("fontFamilyTime"), QStringLiteral("fontFamilyCustom"),
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

    // Load fonts before rendering
    QStringList loadedFamilies;
    for (const QString &fp : fontPaths) {
        int id = QFontDatabase::addApplicationFont(fp);
        QStringList families = QFontDatabase::applicationFontFamilies(id);
        if (m_log) m_log->info("theme", QString("font load: %1 id:%2 families:[%3]").arg(fp).arg(id).arg(families.join(", ")));
        loadedFamilies.append(families);
    }
    if (m_log) m_log->info("theme", QString("all loaded families: [%1]").arg(loadedFamilies.join(", ")));

    auto resolveFamily = [&](const QString &configName) -> QString {
        if (configName.isEmpty()) return {};
        if (loadedFamilies.contains(configName)) return configName;
        QString lower = configName.toLower();
        for (const QString &f : loadedFamilies) {
            if (f.toLower() == lower || f.toLower().contains(lower) || lower.contains(f.toLower()))
                return f;
        }
        return configName;
    };

    QJsonDocument doc = QJsonDocument::fromJson(jsonConfig.toUtf8());
    if (doc.isNull() || !doc.isObject()) {
        if (m_log) m_log->info("theme", "ERROR: invalid config JSON");
        return fallbackPreview(outPath);
    }
    QJsonObject cfg = doc.object();

    // Log ALL config values
    if (m_log) {
        for (const QString &key : cfg.keys()) {
            m_log->info("theme", QString("cfg[%1] = %2").arg(key).arg(cfg[key].toVariant().toString().left(50)));
        }
    }

    // Load wallpaper full resolution
    QImage canvas;
    if (QFile::exists(wallpaperPath)) {
        canvas = QImage(wallpaperPath);
        if (m_log) m_log->info("theme", QString("wallpaper: %1x%2 bytes=%3").arg(canvas.width()).arg(canvas.height()).arg(canvas.sizeInBytes()));
    }
    if (canvas.isNull()) {
        canvas = QImage(1920, 1080, QImage::Format_ARGB32);
        canvas.fill(QColor(42, 42, 50));
        if (m_log) m_log->info("theme", "wallpaper: FALLBACK 1920x1080");
    }

    // Scale factor
    QScreen *screen = QGuiApplication::primaryScreen();
    double scaleX = 1.0, scaleY = 1.0;
    if (screen && !canvas.isNull()) {
        QSize screenSize = screen->size();
        scaleX = (double)canvas.width() / screenSize.width();
        scaleY = (double)canvas.height() / screenSize.height();
        if (m_log) m_log->info("theme", QString("screen: %1x%2 dpr=%3 scale: %4x%5").arg(screenSize.width()).arg(screenSize.height()).arg(screen->devicePixelRatio()).arg(scaleX, 0, 'f', 4).arg(scaleY, 0, 'f', 4));
    }

    // Widget geometry
    QRect widgetRect = findWidgetGeometry();
    if (m_log) m_log->info("theme", QString("widget screen: x=%1 y=%2 w=%3 h=%4 valid=%5").arg(widgetRect.x()).arg(widgetRect.y()).arg(widgetRect.width()).arg(widgetRect.height()).arg(widgetRect.isValid()));

    // Widget on wallpaper
    int wpX = widgetRect.isValid() ? qRound(widgetRect.x() * scaleX) : 0;
    int wpY = widgetRect.isValid() ? qRound(widgetRect.y() * scaleY) : 0;
    int wpW = widgetRect.isValid() ? qRound(widgetRect.width() * scaleX) : canvas.width();
    int wpH = widgetRect.isValid() ? qRound(widgetRect.height() * scaleY) : canvas.height();
    if (m_log) m_log->info("theme", QString("widget wallpaper: x=%1 y=%2 w=%3 h=%4").arg(wpX).arg(wpY).arg(wpW).arg(wpH));

    // Element order
    QString orderStr = cfg.value(QStringLiteral("element_order")).toString(QStringLiteral("day,date,time,custom,timezone"));
    QStringList order = orderStr.split(',');
    if (m_log) m_log->info("theme", QString("element_order: %1").arg(orderStr));

    // Config spacing
    int configSpacing = qRound(cfg.value(QStringLiteral("widget_spacing")).toDouble(5));
    if (m_log) m_log->info("theme", QString("widget_spacing: %1").arg(configSpacing));

    // Parse elements
    struct ClockElement {
        bool visible;
        int configSize;
        int letterSpacing;
        bool bold;
        QColor color;
        QString family;
        QString sampleText;
    };
    QMap<QString, ClockElement> elements;

    auto addElement = [&](const QString &name, const QString &fontKey, int defaultSize, const QString &sample) {
        ClockElement e;
        e.visible = cfg.value(QStringLiteral("show_") + name).toBool(true);
        e.family = cfg.value(QStringLiteral("fontFamily") + fontKey).toString();
        e.configSize = qRound(cfg.value(name + QStringLiteral("_font_size")).toDouble(defaultSize));
        e.letterSpacing = qRound(cfg.value(name + QStringLiteral("_letter_spacing")).toDouble(0));
        e.bold = cfg.value(name + QStringLiteral("_font_bold")).toBool(false);
        e.color = QColor(cfg.value(name + QStringLiteral("_font_color")).toString(QStringLiteral("#FFFFFF")));
        if (!e.color.isValid()) e.color = Qt::white;
        e.sampleText = sample.toUpper(); // Always uppercase
        elements.insert(name, e);
        if (m_log) m_log->info("theme", QString("element %1: show=%2 family=%3 size=%4 ls=%5 bold=%6 color=%7 text='%8'")
            .arg(name).arg(e.visible).arg(e.family).arg(e.configSize).arg(e.letterSpacing)
            .arg(e.bold).arg(e.color.name()).arg(e.sampleText.left(20)));
    };

    // Generate random date/time (no user timing info)
    QDateTime now;
    if (!customDate.isEmpty()) {
        now = QDateTime::fromString(customDate, Qt::ISODate);
    }
    if (!now.isValid()) {
        QRandomGenerator *rng = QRandomGenerator::global();
        int year = 2024 + rng->bounded(5);
        int month = 1 + rng->bounded(12);
        int day = 1 + rng->bounded(28);
        int hour = rng->bounded(24);
        int min = rng->bounded(60);
        int sec = rng->bounded(60);
        now = QDateTime(QDate(year, month, day), QTime(hour, min, sec));
    }
    QLocale locale(cfg.value(QStringLiteral("locale")).toString(QStringLiteral("en_US")));
    QString dateFormat = cfg.value(QStringLiteral("date_format")).toString(QStringLiteral("dd MMM yyyy"));
    QString timeFormat = cfg.value(QStringLiteral("time_format")).toString(QStringLiteral("HH:mm:ss"));
    QString timeChar = cfg.value(QStringLiteral("time_character")).toString();

    addElement(QStringLiteral("day"), QStringLiteral("Day"), 72,
               customDayName.isEmpty() ? locale.toString(now.date(), QStringLiteral("dddd")) : customDayName);
    addElement(QStringLiteral("date"), QStringLiteral("Date"), 19, locale.toString(now.date(), dateFormat));
    QString timeSample = locale.toString(now.time(), timeFormat);
    if (!timeChar.trimmed().isEmpty()) timeSample = timeChar + QStringLiteral(" ") + timeSample + QStringLiteral(" ") + timeChar;
    addElement(QStringLiteral("time"), QStringLiteral("Time"), 19, timeSample);
    addElement(QStringLiteral("custom"), QStringLiteral("Custom"), 19,
               cfg.value(QStringLiteral("custom_text")).toString(QStringLiteral("Custom Text")));
    QString tzText = cfg.value(QStringLiteral("timezone_display_text")).toString();
    if (tzText.isEmpty()) tzText = cfg.value(QStringLiteral("timezone_label")).toString();
    if (tzText.isEmpty()) tzText = QStringLiteral("UTC+8:00");
    addElement(QStringLiteral("timezone"), QStringLiteral("Timezone"), 14, tzText);

    // Measure natural text
    if (m_log) m_log->info("theme", "--- measuring natural text ---");
    int naturalWidth = 0;
    int naturalHeight = 0;
    for (const QString &el : order) {
        if (!elements.contains(el)) continue;
        auto &e = elements[el];
        if (!e.visible) continue;

        QString resolvedFam = resolveFamily(e.family);
        QFont mf;
        if (!resolvedFam.isEmpty()) mf = QFont(resolvedFam, qMax(8, e.configSize));
        else mf = QFont(QStringLiteral("sans-serif"), qMax(8, e.configSize));
        mf.setPixelSize(qMax(8, e.configSize));
        mf.setBold(e.bold);
        if (e.letterSpacing != 0) mf.setLetterSpacing(QFont::AbsoluteSpacing, e.letterSpacing);

        QTextLayout layout(e.sampleText, mf);
        layout.beginLayout();
        QTextLine line = layout.createLine();
        layout.endLayout();
        int tw = qCeil(line.naturalTextWidth());
        QFontMetrics fm(mf);
        int th = fm.height();
        if (tw > naturalWidth) naturalWidth = tw;
        naturalHeight += th;
        if (m_log) m_log->info("theme", QString("  %1: text='%2' tw=%3 th=%4 fam=%5 px=%6 bold=%7 ls=%8")
            .arg(el, e.sampleText.left(25)).arg(tw).arg(th)
            .arg(resolvedFam).arg(e.configSize).arg(e.bold).arg(e.letterSpacing));
    }
    naturalHeight += configSpacing * qMax(0, order.count() - 1);
    if (m_log) m_log->info("theme", QString("natural TOTAL: %1x%2 (spacing=%3 x %4)").arg(naturalWidth).arg(naturalHeight).arg(configSpacing).arg(order.count() - 1));

    // Auto-scale
    double widgetFontScale = 1.0;
    if (naturalWidth > 0 && naturalHeight > 0 && widgetRect.isValid()) {
        double sw = widgetRect.width() - 16;
        double sh = widgetRect.height() - 16;
        widgetFontScale = qMin(sw / naturalWidth, sh / naturalHeight);
        if (m_log) m_log->info("theme", QString("autoscale: sw=%1 sh=%2 natW=%3 natH=%4 → %5").arg(sw).arg(sh).arg(naturalWidth).arg(naturalHeight).arg(widgetFontScale, 0, 'f', 4));
    }
    double finalScale = widgetFontScale * scaleX;
    if (m_log) m_log->info("theme", QString("finalScale: %1 * %2 = %3").arg(widgetFontScale, 0, 'f', 4).arg(scaleX, 0, 'f', 4).arg(finalScale, 0, 'f', 4));

    // Render
    if (m_log) m_log->info("theme", "--- rendering ---");
    QPainter p(&canvas);
    p.setRenderHint(QPainter::TextAntialiasing);
    p.setRenderHint(QPainter::Antialiasing);

    int totalRenderedHeight = 0;
    for (const QString &el : order) {
        if (!elements.contains(el)) continue;
        auto &e = elements[el];
        if (!e.visible) continue;
        totalRenderedHeight += qMax(8, qRound(e.configSize * finalScale));
    }
    totalRenderedHeight += qRound(configSpacing * finalScale) * qMax(0, order.count() - 1);
    int y = wpY + qMax(0, (wpH - totalRenderedHeight) / 2);
    if (m_log) m_log->info("theme", QString("totalH=%1 centerY=%2 startY=%3").arg(totalRenderedHeight).arg(wpH / 2).arg(y));

    for (const QString &el : order) {
        if (!elements.contains(el)) continue;
        auto &e = elements[el];
        if (!e.visible) continue;

        int scaledSize = qMax(8, qRound(e.configSize * finalScale));
        int scaledSpacing = qRound(e.letterSpacing * finalScale);
        int scaledElemSpacing = qRound(configSpacing * finalScale);

        QString resolvedFamily = resolveFamily(e.family);
        QFont f;
        if (!resolvedFamily.isEmpty()) f = QFont(resolvedFamily, qMax(8, scaledSize));
        else f = QFont(QStringLiteral("sans-serif"), qMax(8, scaledSize));
        f.setPixelSize(qMax(8, scaledSize));
        f.setBold(e.bold);
        if (scaledSpacing != 0) f.setLetterSpacing(QFont::AbsoluteSpacing, scaledSpacing);

        p.setFont(f);
        p.setPen(e.color);
        QFontMetrics fm = p.fontMetrics();
        int textWidth = fm.horizontalAdvance(e.sampleText);
        int textX = wpX + qMax(0, (wpW - textWidth) / 2);
        int textH = fm.height();

        if (m_log) m_log->info("theme", QString("  DRAW %1: x=%2 y=%3 w=%4 h=%5 size=%6 ls=%7 text='%8'")
            .arg(el).arg(textX).arg(y).arg(textWidth).arg(textH)
            .arg(scaledSize).arg(scaledSpacing).arg(e.sampleText.left(15)));
        p.drawText(QRect(textX, y, textWidth + 10, textH), Qt::AlignLeft | Qt::AlignVCenter, e.sampleText);
        y += scaledSize + scaledElemSpacing;
    }

    p.end();
    canvas.save(outPath, "PNG");
    qint64 size = QFileInfo(outPath).size();
    if (m_log) m_log->info("theme", QString("=== saved: %1 bytes=%2 ===").arg(outPath).arg(size));
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

void ThemeManager::generatePreviewAsync(const QString &jsonConfig,
                                        const QString &wallpaperPath,
                                        int appletId,
                                        const QStringList &fontPaths,
                                        const QString &customDate,
                                        const QString &customDayName)
{
    // Pre-load fonts on main thread (QFontDatabase is not thread-safe)
    QStringList loadedFamilies;
    for (const QString &fp : fontPaths) {
        int id = QFontDatabase::addApplicationFont(fp);
        loadedFamilies.append(QFontDatabase::applicationFontFamilies(id));
    }

    // Capture screen info on main thread (QGuiApplication::primaryScreen not thread-safe)
    QScreen *screen = QGuiApplication::primaryScreen();
    QSize screenSize = screen ? screen->size() : QSize(1920, 1080);
    double dpr = screen ? screen->devicePixelRatio() : 1.0;

    // Capture widget geometry on main thread
    QRect widgetRect = findWidgetGeometry();

    QString cacheDir = m_cacheDir;
    Logger *log = m_log;

    [[maybe_unused]] auto future = QtConcurrent::run([this, jsonConfig, wallpaperPath, loadedFamilies, screenSize, dpr,
                        widgetRect, cacheDir, log, customDate, customDayName]() {
        QDir().mkpath(cacheDir + QStringLiteral("/previews"));
        QString outPath = cacheDir + QStringLiteral("/previews/export_preview.png");

        auto resolveFamily = [&](const QString &configName) -> QString {
            if (configName.isEmpty()) return {};
            if (loadedFamilies.contains(configName)) return configName;
            QString lower = configName.toLower();
            for (const QString &f : loadedFamilies) {
                if (f.toLower() == lower || f.toLower().contains(lower) || lower.contains(f.toLower()))
                    return f;
            }
            return configName;
        };

        QJsonDocument doc = QJsonDocument::fromJson(jsonConfig.toUtf8());
        if (doc.isNull() || !doc.isObject()) {
            if (log) log->info("theme", "ERROR: invalid config JSON");
            fallbackPreview(outPath);
            emit previewGenerated(outPath);
            return;
        }
        QJsonObject cfg = doc.object();

        // Load wallpaper
        QImage canvas;
        if (QFile::exists(wallpaperPath))
            canvas = QImage(wallpaperPath);
        if (canvas.isNull()) {
            canvas = QImage(1920, 1080, QImage::Format_ARGB32);
            canvas.fill(QColor(42, 42, 50));
        }

        // Scale factor
        double scaleX = 1.0, scaleY = 1.0;
        if (!canvas.isNull()) {
            scaleX = (double)canvas.width() / screenSize.width();
            scaleY = (double)canvas.height() / screenSize.height();
        }

        // Widget on wallpaper
        int wpX = widgetRect.isValid() ? qRound(widgetRect.x() * scaleX) : 0;
        int wpY = widgetRect.isValid() ? qRound(widgetRect.y() * scaleY) : 0;
        int wpW = widgetRect.isValid() ? qRound(widgetRect.width() * scaleX) : canvas.width();
        int wpH = widgetRect.isValid() ? qRound(widgetRect.height() * scaleY) : canvas.height();

        // Element order
        QString orderStr = cfg.value(QStringLiteral("element_order")).toString(QStringLiteral("day,date,time,custom,timezone"));
        QStringList order = orderStr.split(',');
        int configSpacing = qRound(cfg.value(QStringLiteral("widget_spacing")).toDouble(5));

        // Parse elements
        struct ClockElement {
            bool visible; int configSize; int letterSpacing;
            bool bold; QColor color; QString family; QString sampleText;
        };
        QMap<QString, ClockElement> elements;

        auto addElement = [&](const QString &name, const QString &fontKey, int defaultSize, const QString &sample) {
            ClockElement e;
            e.visible = cfg.value(QStringLiteral("show_") + name).toBool(true);
            e.family = cfg.value(QStringLiteral("fontFamily") + fontKey).toString();
            e.configSize = qRound(cfg.value(name + QStringLiteral("_font_size")).toDouble(defaultSize));
            e.letterSpacing = qRound(cfg.value(name + QStringLiteral("_letter_spacing")).toDouble(0));
            e.bold = cfg.value(name + QStringLiteral("_font_bold")).toBool(false);
            e.color = QColor(cfg.value(name + QStringLiteral("_font_color")).toString(QStringLiteral("#FFFFFF")));
            if (!e.color.isValid()) e.color = Qt::white;
            e.sampleText = sample.toUpper();
            elements.insert(name, e);
        };

        QDateTime now;
        if (!customDate.isEmpty())
            now = QDateTime::fromString(customDate, Qt::ISODate);
        if (!now.isValid()) {
            QRandomGenerator *rng = QRandomGenerator::global();
            now = QDateTime(QDate(2024 + rng->bounded(5), 1 + rng->bounded(12), 1 + rng->bounded(28)),
                            QTime(rng->bounded(24), rng->bounded(60), rng->bounded(60)));
        }
        QLocale locale(cfg.value(QStringLiteral("locale")).toString(QStringLiteral("en_US")));
        QString dateFormat = cfg.value(QStringLiteral("date_format")).toString(QStringLiteral("dd MMM yyyy"));
        QString timeFormat = cfg.value(QStringLiteral("time_format")).toString(QStringLiteral("HH:mm:ss"));
        QString timeChar = cfg.value(QStringLiteral("time_character")).toString();

        addElement(QStringLiteral("day"), QStringLiteral("Day"), 72,
                   customDayName.isEmpty() ? locale.toString(now.date(), QStringLiteral("dddd")) : customDayName);
        addElement(QStringLiteral("date"), QStringLiteral("Date"), 19, locale.toString(now.date(), dateFormat));
        QString timeSample = locale.toString(now.time(), timeFormat);
        if (!timeChar.trimmed().isEmpty()) timeSample = timeChar + QStringLiteral(" ") + timeSample + QStringLiteral(" ") + timeChar;
        addElement(QStringLiteral("time"), QStringLiteral("Time"), 19, timeSample);
        addElement(QStringLiteral("custom"), QStringLiteral("Custom"), 19,
                   cfg.value(QStringLiteral("custom_text")).toString(QStringLiteral("Custom Text")));
        QString tzText = cfg.value(QStringLiteral("timezone_display_text")).toString();
        if (tzText.isEmpty()) tzText = cfg.value(QStringLiteral("timezone_label")).toString();
        if (tzText.isEmpty()) tzText = QStringLiteral("UTC+8:00");
        addElement(QStringLiteral("timezone"), QStringLiteral("Timezone"), 14, tzText);

        // Measure natural text
        int naturalWidth = 0, naturalHeight = 0;
        for (const QString &el : order) {
            if (!elements.contains(el)) continue;
            auto &e = elements[el];
            if (!e.visible) continue;
            QString resolvedFam = resolveFamily(e.family);
            QFont mf(!resolvedFam.isEmpty() ? resolvedFam : QStringLiteral("sans-serif"), qMax(8, e.configSize));
            mf.setPixelSize(qMax(8, e.configSize));
            mf.setBold(e.bold);
            if (e.letterSpacing != 0) mf.setLetterSpacing(QFont::AbsoluteSpacing, e.letterSpacing);
            QTextLayout layout(e.sampleText, mf);
            layout.beginLayout();
            QTextLine line = layout.createLine();
            layout.endLayout();
            int tw = qCeil(line.naturalTextWidth());
            QFontMetrics fm(mf);
            if (tw > naturalWidth) naturalWidth = tw;
            naturalHeight += fm.height();
        }
        naturalHeight += configSpacing * qMax(0, order.count() - 1);

        // Auto-scale
        double widgetFontScale = 1.0;
        if (naturalWidth > 0 && naturalHeight > 0 && widgetRect.isValid()) {
            double sw = widgetRect.width() - 16;
            double sh = widgetRect.height() - 16;
            widgetFontScale = qMin(sw / naturalWidth, sh / naturalHeight);
        }
        double finalScale = widgetFontScale * scaleX;

        // Render
        QPainter p(&canvas);
        p.setRenderHint(QPainter::TextAntialiasing);
        p.setRenderHint(QPainter::Antialiasing);

        int totalRenderedHeight = 0;
        for (const QString &el : order) {
            if (!elements.contains(el)) continue;
            auto &e = elements[el];
            if (!e.visible) continue;
            totalRenderedHeight += qMax(8, qRound(e.configSize * finalScale));
        }
        totalRenderedHeight += qRound(configSpacing * finalScale) * qMax(0, order.count() - 1);
        int y = wpY + qMax(0, (wpH - totalRenderedHeight) / 2);

        for (const QString &el : order) {
            if (!elements.contains(el)) continue;
            auto &e = elements[el];
            if (!e.visible) continue;
            int scaledSize = qMax(8, qRound(e.configSize * finalScale));
            int scaledSpacing = qRound(e.letterSpacing * finalScale);
            int scaledElemSpacing = qRound(configSpacing * finalScale);
            QString resolvedFamily = resolveFamily(e.family);
            QFont f(!resolvedFamily.isEmpty() ? resolvedFamily : QStringLiteral("sans-serif"), qMax(8, scaledSize));
            f.setPixelSize(qMax(8, scaledSize));
            f.setBold(e.bold);
            if (scaledSpacing != 0) f.setLetterSpacing(QFont::AbsoluteSpacing, scaledSpacing);
            p.setFont(f);
            p.setPen(e.color);
            QFontMetrics fm = p.fontMetrics();
            int textWidth = fm.horizontalAdvance(e.sampleText);
            int textX = wpX + qMax(0, (wpW - textWidth) / 2);
            int textH = fm.height();
            p.drawText(QRect(textX, y, textWidth + 10, textH), Qt::AlignLeft | Qt::AlignVCenter, e.sampleText);
            y += scaledSize + scaledElemSpacing;
        }

        p.end();
        canvas.save(outPath, "PNG");
        emit previewGenerated(outPath);
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
