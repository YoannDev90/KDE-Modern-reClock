#pragma once

#include <QObject>
#include <QStringList>
#include <QFuture>
#include <QMutex>

// Cached system font list. Enumerating fonts via fontconfig is expensive
// (1-3s on first call). The list is persisted as JSON under
// GenericDataLocation/modernreclock/fonts.json so config dialogs open
// instantly; it is re-enumerated only when the file is older than 7 days.
// A background prefetch at plugin init keeps the first open fast too.
class FontHelper : public QObject {
    Q_OBJECT
public:
    explicit FontHelper(QObject *parent = nullptr);

    // Returns the cached font family list (computed once per process).
    Q_INVOKABLE QStringList fontFamilies();

    // Kick off a background load/enumeration so the cache is warm before the
    // user opens the config dialog.
    static void prefetch();

private:
    static QMutex s_mutex;
    static QStringList s_cache;
    static QFuture<void> s_future;
    static bool s_prefetchStarted;

    static QString jsonPath();
    static bool loadFromJson(QStringList *families, qint64 *updatedMs);
    static bool saveToJson(const QStringList &families);
    static QStringList withBundledFirst(const QStringList &families);
    // Read the JSON cache; enumerate + rewrite it when missing or stale.
    static QStringList loadOrRefresh();
};
