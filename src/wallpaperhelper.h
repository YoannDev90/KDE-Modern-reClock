#pragma once

#include <QObject>
#include <QString>

class WallpaperHelper : public QObject {
    Q_OBJECT
public:
    explicit WallpaperHelper(QObject* parent = nullptr);

    /// Read the current wallpaper image path from KDE Plasma config
    Q_INVOKABLE QString wallpaperPath() const;

    /// Extract average brightness from an image file.
    /// Returns "light" or "dark" based on perceived brightness (ITU-R BT.601).
    Q_INVOKABLE QString wallpaperBrightness(const QString& path) const;

    /// Returns true if the current KDE color scheme is dark.
    Q_INVOKABLE bool isDarkColorScheme() const;

private:
    /// Parse kdeglobals to read the ColorScheme key.
    static QString readKdeColorScheme();
};
