#pragma once

#include <QObject>
#include <QStringList>
#include <QFuture>
#include <QMutex>

// Cached system font list. Enumerating fonts via fontconfig is expensive
// (1-3s on first call). This caches the result in a process-wide static so
// repeated config-dialog opens are instant, and pre-fetches in a background
// thread at plugin init so the first open is fast too.
class FontHelper : public QObject {
    Q_OBJECT
public:
    explicit FontHelper(QObject *parent = nullptr);

    // Returns the cached font family list (computed once).
    Q_INVOKABLE QStringList fontFamilies();

    // Kick off a background enumeration so the cache is warm before the
    // user opens the config dialog.
    static void prefetch();

private:
    static QMutex s_mutex;
    static QStringList s_cache;
    static QFuture<void> s_future;
    static bool s_prefetchStarted;
};
