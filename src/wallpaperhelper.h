#pragma once

#include <QObject>
#include <QString>
#include <QFileSystemWatcher>

class WallpaperHelper : public QObject {
    Q_OBJECT
public:
    explicit WallpaperHelper(QObject* parent = nullptr);

    Q_INVOKABLE QString wallpaperPath() const;
    Q_INVOKABLE QString wallpaperBrightness(const QString& path) const;
    Q_INVOKABLE bool isDarkColorScheme() const;
    Q_INVOKABLE QString wallpaperDataUrl() const;
    Q_INVOKABLE QString wallpaperTempFile() const;

signals:
    void wallpaperChanged();

private:
    mutable QString m_cachedPath;
    mutable QString m_cachedBrightness;
    QFileSystemWatcher* m_watcher = nullptr;
    void setupWatcher(const QString& path);
};
