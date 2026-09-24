#include "previewrenderer.h"
#include "logger.h"

#include <QDateTime>
#include <QFile>
#include <QFileInfo>
#include <QFont>
#include <QFontMetrics>
#include <QGuiApplication>
#include <QImage>
#include <QJsonObject>
#include <QJsonDocument>
#include <QLocale>
#include <QMap>
#include <QPainter>
#include <QPalette>
#include <QPixmap>
#include <QRandomGenerator>
#include <QRegularExpression>
#include <QTimeZone>
#include <QVector>

namespace {

QString resolveFamilyName(const QString &configName, const QStringList &loadedFamilies)
{
    if (configName.isEmpty()) return {};
    if (loadedFamilies.contains(configName)) return configName;
    QString lower = configName.toLower();
    for (const QString &f : loadedFamilies) {
        QString fl = f.toLower();
        if (fl == lower || fl.contains(lower) || lower.contains(fl))
            return f;
    }
    return configName;
}

// Mirrors WallpaperHelper::wallpaperBrightness (center 5x5 of 50x50 scale)
// and main.qml: light → #000000, dark → #FFFFFF.
QColor wallpaperDerivedTextColor(const QImage &canvas)
{
    QImage scaled = canvas.scaled(50, 50, Qt::IgnoreAspectRatio, Qt::FastTransformation);
    int cx = scaled.width() / 2;
    int cy = scaled.height() / 2;
    double sumR = 0, sumG = 0, sumB = 0;
    int count = 0;
    for (int dx = -2; dx <= 2; ++dx) {
        for (int dy = -2; dy <= 2; ++dy) {
            int px = qBound(0, cx + dx, scaled.width() - 1);
            int py = qBound(0, cy + dy, scaled.height() - 1);
            QColor c = scaled.pixelColor(px, py);
            sumR += c.redF();
            sumG += c.greenF();
            sumB += c.blueF();
            ++count;
        }
    }
    if (count == 0)
        return QColor(Qt::white);
    double brightness = 0.299 * (sumR / count) + 0.587 * (sumG / count) + 0.114 * (sumB / count);
    return brightness < 0.5 ? QColor(Qt::white) : QColor(Qt::black);
}

// Mirrors ClockModel::timezoneText / timezoneTimeFormat.
// Ignores timezone_display_text (UI ComboBox only).
QString timezoneSampleText(const QDateTime &now, const QJsonObject &cfg, const QString &timeFormat)
{
    QString tzId = cfg.value(QStringLiteral("timezone_id")).toString();
    if (tzId.isEmpty())
        return {};
    QString label = cfg.value(QStringLiteral("timezone_label")).toString();

    QString tzFmt = timeFormat;
    tzFmt.remove(QRegularExpression(QStringLiteral("[sz]{1,3}")));
    tzFmt.remove(QRegularExpression(QStringLiteral("[:\\s.]+$")));
    if (tzFmt.trimmed().isEmpty()) {
        tzFmt = cfg.value(QStringLiteral("use_24_hour_format")).toBool()
            ? QStringLiteral("HH:mm") : QStringLiteral("hh:mm");
    }

    QTimeZone tz(tzId.toUtf8());
    QString formatted;
    if (tz.isValid())
        formatted = now.toTimeZone(tz).toString(tzFmt);
    if (formatted.isEmpty())
        formatted = QStringLiteral("??");
    return label.isEmpty() ? formatted : label + QStringLiteral(" ") + formatted;
}

} // namespace

QString writeFallbackPreview(const QString &outPath)
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

QString renderPreviewImage(const PreviewParams &p)
{
    Logger *log = p.log;
    if (log) log->info("theme", "=== renderPreviewImage START ===");

    QJsonDocument doc = QJsonDocument::fromJson(p.jsonConfig.toUtf8());
    if (doc.isNull() || !doc.isObject()) {
        if (log) log->info("theme", "ERROR: invalid config JSON");
        return writeFallbackPreview(p.outPath);
    }
    QJsonObject cfg = doc.object();

    // Wallpaper canvas
    QImage canvas;
    if (QFile::exists(p.wallpaperPath))
        canvas = QImage(p.wallpaperPath);
    if (canvas.isNull()) {
        canvas = QImage(1920, 1080, QImage::Format_ARGB32);
        canvas.fill(QColor(42, 42, 50));
        if (log) log->info("theme", "wallpaper: FALLBACK 1920x1080");
    }

    // Screen → wallpaper scale (widget pixels map onto the wallpaper image)
    double scaleX = 1.0, scaleY = 1.0;
    if (p.screenSize.width() > 0 && p.screenSize.height() > 0) {
        scaleX = double(canvas.width()) / p.screenSize.width();
        scaleY = double(canvas.height()) / p.screenSize.height();
    }

    // Widget rect on wallpaper (fallback: full canvas)
    const QRect &widgetRect = p.widgetRect;
    int wpX = widgetRect.isValid() ? qRound(widgetRect.x() * scaleX) : 0;
    int wpY = widgetRect.isValid() ? qRound(widgetRect.y() * scaleY) : 0;
    int wpW = widgetRect.isValid() ? qRound(widgetRect.width() * scaleX) : canvas.width();
    int wpH = widgetRect.isValid() ? qRound(widgetRect.height() * scaleY) : canvas.height();

    // Element order — validate like ClockModel::setConfig
    const QStringList valid = {QStringLiteral("day"), QStringLiteral("date"),
                               QStringLiteral("time"), QStringLiteral("timezone")};
    QStringList order;
    const QString orderRaw = cfg.value(QStringLiteral("element_order")).toString();
    if (!orderRaw.isEmpty()) {
        const auto parts = orderRaw.split(QLatin1Char(','));
        for (const QString &part : parts) {
            QString t = part.trimmed();
            if (valid.contains(t) && !order.contains(t))
                order.append(t);
        }
    } else {
        order = valid;
    }
    const bool showTimezone = cfg.value(QStringLiteral("show_timezone")).toBool(false);
    if (showTimezone && !order.contains(QStringLiteral("timezone")))
        order.append(QStringLiteral("timezone"));
    if (order.isEmpty())
        order = valid;

    const int configSpacing = qMax(0, qRound(cfg.value(QStringLiteral("widget_spacing")).toDouble(5)));

    // Locale — empty → system (ClockModel::effectiveLocale)
    QString localeStr = cfg.value(QStringLiteral("locale")).toString().trimmed();
    QLocale locale = localeStr.isEmpty()
        ? QLocale()
        : QLocale(QString(localeStr).replace(QLatin1Char('-'), QLatin1Char('_')));

    // Formats — fallbacks match ClockModel
    QString dayFormat = cfg.value(QStringLiteral("day_format")).toString().trimmed();
    if (dayFormat.isEmpty())
        dayFormat = QStringLiteral("dddd");
    QString dateFormat = cfg.value(QStringLiteral("date_format")).toString().trimmed();
    if (dateFormat.isEmpty())
        dateFormat = QStringLiteral("dd MMM yyyy");
    QString timeFormat = cfg.value(QStringLiteral("time_format")).toString().trimmed();
    if (timeFormat.isEmpty()) {
        timeFormat = cfg.value(QStringLiteral("use_24_hour_format")).toBool()
            ? QStringLiteral("HH:mm") : QStringLiteral("hh:mm AP");
    }
    const QString timeChar = cfg.value(QStringLiteral("time_character")).toString().trimmed();

    // Date/time source: explicit arg → cfg custom_preview_date → random demo date
    QDateTime now;
    QString dateOverride = p.customDate;
    if (dateOverride.isEmpty())
        dateOverride = cfg.value(QStringLiteral("custom_preview_date")).toString().trimmed();
    if (!dateOverride.isEmpty()) {
        now = QDateTime::fromString(dateOverride, Qt::ISODate);
        if (!now.isValid()) {
            QDate d = QDate::fromString(dateOverride, Qt::ISODate);
            if (d.isValid())
                now = QDateTime(d, QTime(0, 0));
        }
    }
    if (!now.isValid()) {
        QRandomGenerator *rng = QRandomGenerator::global();
        now = QDateTime(QDate(2024 + rng->bounded(5), 1 + rng->bounded(12), 1 + rng->bounded(28)),
                        QTime(rng->bounded(24), rng->bounded(60), rng->bounded(60)));
    }

    // Color mode — migration + resolution like ClockModel::resolveColor
    QString colorMode = cfg.value(QStringLiteral("color_mode")).toString();
    if (cfg.value(QStringLiteral("adapt_to_theme")).toBool()
        && (colorMode.isEmpty() || colorMode == QLatin1String("custom")))
        colorMode = QStringLiteral("theme");
    if (colorMode.isEmpty())
        colorMode = QStringLiteral("custom");

    QColor themeText = p.themeTextColor;
    if (!themeText.isValid())
        themeText = QGuiApplication::palette().color(QPalette::WindowText);

    QColor wallpaperText;
    if (colorMode == QLatin1String("wallpaper"))
        wallpaperText = wallpaperDerivedTextColor(canvas);

    auto resolveColor = [&](const QColor &custom) -> QColor {
        if (colorMode == QLatin1String("theme"))
            return themeText;
        if (colorMode == QLatin1String("theme_inverse"))
            return QColor(255 - themeText.red(), 255 - themeText.green(), 255 - themeText.blue());
        if (colorMode == QLatin1String("wallpaper"))
            return wallpaperText;
        return custom.isValid() ? custom : QColor(Qt::white);
    };

    struct ClockElement {
        bool visible = true;
        int configSize = 1;
        int letterSpacing = 0;
        bool bold = false;
        QColor color = Qt::white;
        QString family;
        QString sampleText;
    };
    QMap<QString, ClockElement> elements;

    auto defaultFamily = [](const QString &name) -> QString {
        return name == QLatin1String("day") ? QStringLiteral("Anurati")
                                             : QStringLiteral("Poppins");
    };

    auto addElement = [&](const QString &name, const QString &fontKey, int defaultSize,
                          const QString &sample, bool uppercase, bool showDefault) {
        ClockElement e;
        e.visible = cfg.value(QStringLiteral("show_") + name).toBool(showDefault);
        QString fam = cfg.value(QStringLiteral("fontFamily") + fontKey).toString().trimmed();
        e.family = fam.isEmpty() ? defaultFamily(name) : fam;
        e.configSize = qMax(1, qRound(cfg.value(name + QStringLiteral("_font_size")).toDouble(defaultSize)));
        e.letterSpacing = qMax(0, qRound(cfg.value(name + QStringLiteral("_letter_spacing")).toDouble(0)));
        e.bold = cfg.value(name + QStringLiteral("_font_bold")).toBool(false);
        e.color = resolveColor(QColor(cfg.value(name + QStringLiteral("_font_color")).toString(QStringLiteral("#FFFFFF"))));
        e.sampleText = uppercase ? sample.toUpper() : sample;
        elements.insert(name, e);
    };

    addElement(QStringLiteral("day"), QStringLiteral("Day"), 72,
               p.customDayName.isEmpty() ? locale.toString(now.date(), dayFormat) : p.customDayName,
               cfg.value(QStringLiteral("uppercase_day")).toBool(true), true);
    addElement(QStringLiteral("date"), QStringLiteral("Date"), 19,
               locale.toString(now.date(), dateFormat),
               cfg.value(QStringLiteral("uppercase_date")).toBool(true), true);
    QString timeSample = locale.toString(now.time(), timeFormat);
    if (!timeChar.isEmpty())
        timeSample = timeChar + QStringLiteral(" ") + timeSample + QStringLiteral(" ") + timeChar;
    addElement(QStringLiteral("time"), QStringLiteral("Time"), 19, timeSample, false, true);
    addElement(QStringLiteral("timezone"), QStringLiteral("Timezone"), 19,
               timezoneSampleText(now, cfg, timeFormat), false, false);

    auto makeFont = [&](const ClockElement &e, int pixelSize) -> QFont {
        QString resolved = resolveFamilyName(e.family, p.loadedFamilies);
        QFont f(resolved.isEmpty() ? defaultFamily(QString()) : resolved);
        f.setPixelSize(qMax(1, pixelSize));
        f.setBold(e.bold);
        if (e.letterSpacing != 0)
            f.setLetterSpacing(QFont::AbsoluteSpacing, e.letterSpacing);
        return f;
    };

    // Natural measure (metricsColumn equivalent): visible items only,
    // height = fm.height() per item, spacing × (visibleCount - 1).
    int naturalWidth = 0;
    int naturalHeight = 0;
    int visibleCount = 0;
    for (const QString &el : order) {
        if (!elements.contains(el)) continue;
        const ClockElement &e = elements[el];
        if (!e.visible) continue;
        ++visibleCount;
        QFont mf = makeFont(e, e.configSize);
        QFontMetrics fm(mf);
        naturalWidth = qMax(naturalWidth, fm.horizontalAdvance(e.sampleText));
        naturalHeight += fm.height();
    }
    naturalHeight += configSpacing * qMax(0, visibleCount - 1);
    if (log) {
        log->info("theme", QString("natural: %1x%2 visible=%3 spacing=%4 colorMode=%5")
                      .arg(naturalWidth).arg(naturalHeight).arg(visibleCount)
                      .arg(configSpacing).arg(colorMode));
    }

    // auto_scale gate — widget only scales font when auto_scale is true
    const bool autoScale = cfg.value(QStringLiteral("auto_scale")).toBool(false);
    double widgetFontScale = 1.0;
    if (autoScale && naturalWidth > 0 && naturalHeight > 0 && widgetRect.isValid()) {
        double sw = widgetRect.width() - 16;
        double sh = widgetRect.height() - 16;
        widgetFontScale = qMin(sw / naturalWidth, sh / naturalHeight);
    }
    const double finalScale = widgetFontScale * scaleX;
    if (log) {
        log->info("theme", QString("auto_scale=%1 widgetFontScale=%2 scaleX=%3 finalScale=%4")
                      .arg(autoScale).arg(widgetFontScale, 0, 'f', 4)
                      .arg(scaleX, 0, 'f', 4).arg(finalScale, 0, 'f', 4));
    }

    // Pre-measure scaled heights for vertical centering (QML Column: fm.height() each)
    struct ScaledItem {
        const ClockElement *el;
        int pixelSize;
        int letterSpacing;
        int height;
    };
    QVector<ScaledItem> items;
    items.reserve(visibleCount);
    int totalRenderedHeight = 0;
    for (const QString &el : order) {
        if (!elements.contains(el)) continue;
        const ClockElement &e = elements[el];
        if (!e.visible) continue;
        int scaledSize = qMax(1, qRound(e.configSize * finalScale));
        QFont f = makeFont(e, scaledSize);
        QFontMetrics fm(f);
        int h = fm.height();
        items.append({&e, scaledSize, qRound(e.letterSpacing * finalScale), h});
        totalRenderedHeight += h;
    }
    totalRenderedHeight += qRound(configSpacing * finalScale) * qMax(0, items.count() - 1);

    int y = wpY + qMax(0, (wpH - totalRenderedHeight) / 2);
    if (log) {
        log->info("theme", QString("totalH=%1 widgetRect=(%2,%3 %4x%5) startY=%6")
                      .arg(totalRenderedHeight).arg(widgetRect.x()).arg(widgetRect.y())
                      .arg(widgetRect.width()).arg(widgetRect.height()).arg(y));
    }

    QPainter painter(&canvas);
    painter.setRenderHint(QPainter::TextAntialiasing);
    painter.setRenderHint(QPainter::Antialiasing);

    for (const ScaledItem &item : items) {
        const ClockElement &e = *item.el;
        QFont f = makeFont(e, item.pixelSize);
        if (item.letterSpacing != 0)
            f.setLetterSpacing(QFont::AbsoluteSpacing, item.letterSpacing);
        painter.setFont(f);
        painter.setPen(e.color);
        QFontMetrics fm = painter.fontMetrics();
        int textWidth = fm.horizontalAdvance(e.sampleText);
        int textX = wpX + qMax(0, (wpW - textWidth) / 2);
        int textH = fm.height();
        painter.drawText(QRect(textX, y, textWidth + 10, textH),
                         Qt::AlignLeft | Qt::AlignVCenter, e.sampleText);
        y += textH + qRound(configSpacing * finalScale);
    }
    painter.end();

    canvas.save(p.outPath, "PNG");
    if (log) {
        log->info("theme", QString("=== saved: %1 bytes=%2 ===")
                      .arg(p.outPath).arg(QFileInfo(p.outPath).size()));
    }
    return p.outPath;
}
