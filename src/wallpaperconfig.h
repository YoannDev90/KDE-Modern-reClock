#pragma once

#include <QString>

namespace WallpaperConfig {

/// Parse ~/.config/kdeglobals and return the ColorScheme name.
QString readKdeColorScheme();

/// Return true if the current KDE color scheme name contains "dark".
bool isDarkColorScheme();

/// Parse ~/.config/plasma-org.kde.plasma.desktop-appletsrc,
/// find the Image= key, resolve file:// and directory wallpapers.
/// Returns empty string on failure.
QString readWallpaperPath();

} // namespace WallpaperConfig
