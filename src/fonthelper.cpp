#include "fonthelper.h"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QFontDatabase>
#include <QFuture>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSaveFile>
#include <QStandardPaths>
#include <QtConcurrentRun>

namespace {
// Re-enumerate system fonts at most once a week.
constexpr qint64 kRefreshIntervalMs = 7LL * 24 * 60 * 60 * 1000;
// Tolerate a clock skewed forward by up to a day.
constexpr qint64 kFutureToleranceMs = 24LL * 60 * 60 * 1000;
}

QStringList FontHelper::s_cache;
QFuture<void> FontHelper::s_future;
bool FontHelper::s_prefetchStarted = false;
QMutex FontHelper::s_mutex;

FontHelper::FontHelper(QObject *parent)
    : QObject(parent)
{
}

QString FontHelper::jsonPath()
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)
        + QStringLiteral("/modernreclock/fonts.json");
}

// Bundled fonts are not in QFontDatabase until the widget loads them, but the
// config must always offer them first (Anurati = day default, Poppins = rest).
QStringList FontHelper::withBundledFirst(const QStringList &families)
{
    QStringList out{QStringLiteral("Anurati"), QStringLiteral("Poppins")};
    out.reserve(families.size() + 2);
    for (const QString &f : families) {
        if (!out.contains(f, Qt::CaseInsensitive))
            out.append(f);
    }
    return out;
}

bool FontHelper::loadFromJson(QStringList *families, qint64 *updatedMs)
{
    QFile f(jsonPath());
    if (!f.open(QIODevice::ReadOnly))
        return false;
    QJsonParseError err{};
    const QJsonDocument doc = QJsonDocument::fromJson(f.readAll(), &err);
    if (err.error != QJsonParseError::NoError || !doc.isObject())
        return false;
    const QJsonObject o = doc.object();
    *updatedMs = static_cast<qint64>(o.value(QStringLiteral("updatedMs")).toDouble());
    families->clear();
    const QJsonArray arr = o.value(QStringLiteral("families")).toArray();
    families->reserve(arr.size());
    for (const QJsonValue &v : arr) {
        if (v.isString() && !v.toString().isEmpty())
            families->append(v.toString());
    }
    return !families->isEmpty();
}

bool FontHelper::saveToJson(const QStringList &families)
{
    const QString path = jsonPath();
    QDir().mkpath(QFileInfo(path).absolutePath());
    QJsonObject o;
    o.insert(QStringLiteral("version"), 1);
    o.insert(QStringLiteral("updatedMs"),
             static_cast<double>(QDateTime::currentMSecsSinceEpoch()));
    QJsonArray arr;
    for (const QString &f : families)
        arr.append(f);
    o.insert(QStringLiteral("families"), arr);
    QSaveFile f(path);
    if (!f.open(QIODevice::WriteOnly))
        return false;
    f.write(QJsonDocument(o).toJson(QJsonDocument::Compact));
    return f.commit();
}

QStringList FontHelper::loadOrRefresh()
{
    QStringList cached;
    qint64 updated = 0;
    if (loadFromJson(&cached, &updated)) {
        const qint64 now = QDateTime::currentMSecsSinceEpoch();
        if (updated <= now + kFutureToleranceMs && now - updated < kRefreshIntervalMs)
            return withBundledFirst(cached);
    }
    // Missing, corrupt or older than a week — enumerate and persist.
    QStringList fresh = withBundledFirst(QFontDatabase::families());
    saveToJson(fresh);
    return fresh;
}

QStringList FontHelper::fontFamilies()
{
    QMutexLocker lock(&s_mutex);
    if (s_cache.isEmpty()) {
        // Cache miss (or prefetch not finished yet) — compute synchronously.
        s_cache = loadOrRefresh();
    }
    return s_cache;
}

void FontHelper::prefetch()
{
    QMutexLocker lock(&s_mutex);
    if (s_prefetchStarted || !s_cache.isEmpty())
        return;
    s_prefetchStarted = true;
    s_future = QtConcurrent::run([]() {
        const QStringList families = loadOrRefresh();
        QMutexLocker lock(&s_mutex);
        if (s_cache.isEmpty())
            s_cache = families;
    });
}
