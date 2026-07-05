#include "thememanager.h"
#include "mrtarchive.h"

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

    qDebug() << "[ThemeManager] exportTheme:" << filePath;
    qDebug() << "[ThemeManager]   jsonConfig size:" << jsonConfig.size();
    qDebug() << "[ThemeManager]   embedFonts:" << embedFonts;
    qDebug() << "[ThemeManager]   wallpaperPath:" << wallpaperPath;

    // Preview image (if captured)
    QString previewPath = m_cacheDir + QStringLiteral("/previews/export_preview.png");
    qDebug() << "[ThemeManager]   checking preview:" << previewPath << "exists:" << QFile::exists(previewPath);
    if (QFile::exists(previewPath)) {
        QFile pf(previewPath);
        if (pf.open(QIODevice::ReadOnly)) {
            QByteArray data = pf.readAll();
            qDebug() << "[ThemeManager]   preview size:" << data.size();
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
    qDebug() << "[ThemeManager]   checking wallpaper:" << wallpaperPath << "exists:" << QFile::exists(wallpaperPath);
    if (QFile::exists(wallpaperPath)) {
        QFile wf(wallpaperPath);
        if (wf.open(QIODevice::ReadOnly)) {
            QString ext = QFileInfo(wallpaperPath).suffix();
            if (ext.isEmpty()) ext = QStringLiteral("png");
            entries.append({QStringLiteral("wallpaper.") + ext, wf.readAll()});
            wf.close();
        }
    }

    qDebug() << "[ThemeManager]   entries count:" << entries.size();
    if (!MrtArchive::write(filePath, entries)) {
        qDebug() << "[ThemeManager]   FAILED to write archive";
        emit errorOccurred(QStringLiteral("Cannot create: %1").arg(filePath));
        return {};
    }
    qDebug() << "[ThemeManager]   export OK";
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

QString ThemeManager::generatePreview(const QString &jsonConfig,
                                       const QString &wallpaperPath)
{
    qDebug() << "[ThemeManager] generatePreview called";
    QDir().mkpath(m_cacheDir + QStringLiteral("/previews"));
    QString outPath = m_cacheDir + QStringLiteral("/previews/export_preview.png");

    // Parse config
    QJsonDocument doc = QJsonDocument::fromJson(jsonConfig.toUtf8());
    if (doc.isNull() || !doc.isObject()) {
        qDebug() << "[ThemeManager]   invalid config JSON";
        return fallbackPreview(outPath);
    }
    QJsonObject cfg = doc.object();

    // Read order
    QString orderStr = cfg.value(QStringLiteral("element_order")).toString(QStringLiteral("day,date,time,custom,timezone"));
    QStringList order = orderStr.split(',');

    // Load wallpaper or fallback background
    QImage bg;
    if (QFile::exists(wallpaperPath)) {
        bg = QImage(wallpaperPath);
        qDebug() << "[ThemeManager]   loaded wallpaper:" << wallpaperPath << bg.size();
    }
    if (bg.isNull()) {
        bg = QImage(400, 225, QImage::Format_ARGB32);
        bg.fill(QColor(42, 42, 50));
    }

    // Scale to preview size
    QImage canvas = bg.scaled(400, 225, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    if (canvas.width() < 400 || canvas.height() < 225) {
        // Extend with blurred edge or just center
        QImage padded(400, 225, QImage::Format_ARGB32);
        padded.fill(QColor(42, 42, 50));
        QPainter pp(&padded);
        pp.drawImage((400 - canvas.width()) / 2, (225 - canvas.height()) / 2, canvas);
        pp.end();
        canvas = padded;
    }

    // Calculate total height of visible elements
    int spacing = static_cast<int>(cfg.value(QStringLiteral("widget_spacing")).toDouble(5));
    struct ClockElement {
        bool visible;
        QString fontFamily;
        int fontSize;
        bool bold;
        QColor color;
        QString sampleText;
    };
    QMap<QString, ClockElement> elements;

    auto addElement = [&](const QString &name, const QString &fontKey, int defaultSize,
                          const QString &sample, const QString formatKey = {}) {
        ClockElement e;
        e.visible = cfg.value(QStringLiteral("show_") + name).toBool(true);
        e.fontFamily = cfg.value(QStringLiteral("fontFamily") + fontKey).toString();
        e.fontSize = static_cast<int>(cfg.value(name + QStringLiteral("_font_size")).toDouble(defaultSize));
        e.bold = cfg.value(name + QStringLiteral("_font_bold")).toBool(false);
        QString colStr = cfg.value(name + QStringLiteral("_font_color")).toString(QStringLiteral("#FFFFFF"));
        e.color = QColor(colStr);
        if (!e.color.isValid()) e.color = Qt::white;
        e.sampleText = sample;
        elements.insert(name, e);
    };

    addElement(QStringLiteral("day"),    QStringLiteral("Day"),    72, QStringLiteral("Wednesday"));
    addElement(QStringLiteral("date"),  QStringLiteral("Date"),   19, QStringLiteral("15 Jan 2026"));
    addElement(QStringLiteral("time"),  QStringLiteral("Time"),   19, QStringLiteral("14:30:00"));
    addElement(QStringLiteral("custom"),QStringLiteral("Custom"), 19, cfg.value(QStringLiteral("custom_text")).toString(QStringLiteral("Custom Text")));
    // timezone not in export config keys, use placeholder
    addElement(QStringLiteral("timezone"), QStringLiteral("Timezone"), 14, QStringLiteral("UTC+8:00"));

    // Calculate layout
    int totalHeight = 0;
    for (const QString &el : order) {
        if (!elements.contains(el)) continue;
        auto &e = elements[el];
        if (!e.visible) continue;
        totalHeight += e.fontSize + spacing;
    }
    if (totalHeight > 0) totalHeight -= spacing; // remove last spacing

    // Paint
    int y = (225 - totalHeight) / 2;
    if (y < 10) y = 10; // min top padding

    QPainter p(&canvas);
    p.setRenderHint(QPainter::TextAntialiasing);
    QString lastFamily;

    for (const QString &el : order) {
        if (!elements.contains(el)) continue;
        auto &e = elements[el];
        if (!e.visible) continue;

        QFont f;
        if (!e.fontFamily.isEmpty()) {
            f = QFont(e.fontFamily, qMax(8, e.fontSize));
        } else {
            f = QFont(QStringLiteral("sans-serif"), qMax(8, e.fontSize));
        }
        f.setPixelSize(qMax(8, e.fontSize));
        f.setBold(e.bold);
        p.setFont(f);
        p.setPen(e.color);
        p.drawText(QRect(10, y, 380, e.fontSize + 4), Qt::AlignHCenter | Qt::AlignVCenter, e.sampleText);
        y += e.fontSize + spacing;
    }

    p.end();
    canvas.save(outPath, "PNG");
    qDebug() << "[ThemeManager]   saved preview:" << outPath;
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

// ===== SCREENSHOT =====

QString ThemeManager::captureScreenshot(int delayMs)
{
    Q_UNUSED(delayMs)
    qDebug() << "[ThemeManager] captureScreenshot called";
    QString outPath = m_cacheDir + QStringLiteral("/previews/export_preview.png");
    QDir().mkpath(m_cacheDir + QStringLiteral("/previews"));

    bool isWayland = !qEnvironmentVariableIsEmpty("WAYLAND_DISPLAY");
    bool ok = false;

    if (isWayland) {
        qDebug() << "[ThemeManager]   Wayland detected, using spectacle";
        QStringList args;
        args << QStringLiteral("-b") << QStringLiteral("-n")
             << QStringLiteral("-o") << outPath;
        int ret = QProcess::execute(QStringLiteral("spectacle"), args);
        if (ret == 0) {
            qDebug() << "[ThemeManager]   spectacle OK";
            ok = true;
        } else {
            qDebug() << "[ThemeManager]   spectacle failed, exit code:" << ret;
        }
    } else {
        qDebug() << "[ThemeManager]   X11/Wayland not detected, using grabWindow";
        QScreen *screen = QGuiApplication::primaryScreen();
        if (screen) {
            QPixmap full = screen->grabWindow(0);
            qDebug() << "[ThemeManager]   grabbed:" << full.width() << "x" << full.height();
            if (!full.isNull()) {
                QImage thumb = full.toImage().scaled(400, 225, Qt::KeepAspectRatio, Qt::SmoothTransformation);
                ok = thumb.save(outPath, "PNG");
            }
        }
    }

    if (!ok) {
        qDebug() << "[ThemeManager]   capture failed, creating fallback image";
        QPixmap fb(400, 225);
        fb.fill(QColor(42, 42, 50));
        QPainter p(&fb);
        p.setPen(Qt::white);
        p.setFont(QFont(QStringLiteral("sans-serif"), 12));
        p.drawText(fb.rect(), Qt::AlignCenter, QStringLiteral("Preview: capture unavailable.\nInstall 'spectacle' or run on X11."));
        p.end();
        ok = fb.toImage().save(outPath, "PNG");
    }

    qint64 size = ok ? QFileInfo(outPath).size() : 0;
    qDebug() << "[ThemeManager]   saved:" << ok << "size:" << size;
    return ok ? outPath : QString{};
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
