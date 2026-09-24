#pragma once

#include <QColor>
#include <QRect>
#include <QSize>
#include <QString>
#include <QStringList>

class Logger;

// Shared preview renderer for ThemeManager (sync + async).
// Mirrors ClockModel + main.qml so the KCM preview matches the widget.
struct PreviewParams {
    QString jsonConfig;
    QString wallpaperPath;
    QSize screenSize{1920, 1080};
    QRect widgetRect;
    QStringList loadedFamilies;
    QColor themeTextColor;
    QString outPath;
    QString customDate;
    QString customDayName;
    Logger *log = nullptr;
};

// Renders the preview PNG to p.outPath. Falls back to a placeholder image
// if the config JSON is invalid. Returns the output path.
QString renderPreviewImage(const PreviewParams &p);

// Writes a small static "Preview" placeholder PNG and returns outPath.
QString writeFallbackPreview(const QString &outPath);
