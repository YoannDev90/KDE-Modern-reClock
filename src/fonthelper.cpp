#include "fonthelper.h"

#include <QFontDatabase>
#include <QtConcurrentRun>
#include <QFuture>

QStringList FontHelper::s_cache;
QFuture<void> FontHelper::s_future;
bool FontHelper::s_prefetchStarted = false;
QMutex FontHelper::s_mutex;

FontHelper::FontHelper(QObject *parent)
    : QObject(parent)
{
}

QStringList FontHelper::fontFamilies()
{
    QMutexLocker lock(&s_mutex);
    if (s_cache.isEmpty()) {
        // Cache miss (or prefetch not finished yet) — compute synchronously.
        s_cache = QFontDatabase::families();
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
        QStringList families = QFontDatabase::families();
        QMutexLocker lock(&s_mutex);
        s_cache = families;
    });
}
