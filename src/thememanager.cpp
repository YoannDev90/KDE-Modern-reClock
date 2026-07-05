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
}

ThemeManager::~ThemeManager() {}

QString ThemeManager::cacheDir() const { return m_cacheDir; }

// ===== EXPORT =====

QString ThemeManager::exportTheme(const QString &filePath,
                                   const QString &jsonConfig,
                                   const QStringList &embedFonts)
{
    QList<MrtArchiveEntry> entries;
    entries.append({QStringLiteral("theme.json"), jsonConfig.toUtf8()});

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

    if (!MrtArchive::write(filePath, entries)) {
        emit errorOccurred(QStringLiteral("Cannot create: %1").arg(filePath));
        return {};
    }
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
