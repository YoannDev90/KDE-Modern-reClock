#include "clockmodel.h"

#include <QDebug>
#include <QColor>
#include <QRegularExpression>
#include <QTimeZone>
#include <algorithm>

ClockModel::ClockModel(QObject* parent)
    : QAbstractListModel(parent)
    , m_now(QDateTime::currentDateTime()) {
    m_timer.setSingleShot(true);
    m_timer.setTimerType(Qt::PreciseTimer);
    connect(&m_timer, &QTimer::timeout, this, &ClockModel::tick);
    m_order = {"day", "date", "time", "timezone"};
    rebuildElements();
    scheduleNextTick();
}

int ClockModel::rowCount(const QModelIndex& parent) const {
    return parent.isValid() ? 0 : m_elements.size();
}

QVariant ClockModel::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= m_elements.size())
        return QVariant();
    const Element& e = m_elements.at(index.row());
    switch (role) {
    case TextRole: return e.text;
    case FontRole: return e.fontFamily;
    case SizeRole: return e.fontSize;
    case SpacingRole: return e.spacing;
    case BoldRole: return e.bold;
    case ColorRole: return e.color;
    case VisibleRole: return e.visible;
    case Qt::DisplayRole: return e.text;
    }
    return QVariant();
}

QHash<int, QByteArray> ClockModel::roleNames() const {
    return {
        { TextRole, "text" },
        { FontRole, "font" },
        { SizeRole, "size" },
        { SpacingRole, "spacing" },
        { BoldRole, "bold" },
        { ColorRole, "color" },
        { VisibleRole, "visible" }
    };
}

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

// "day" -> "Day" so config keys ("showDay", "sizeDay", ...) match the element type.
static QString capped(const QString& type) {
    if (type.isEmpty())
        return type;
    QString c = type;
    c[0] = c[0].toUpper();
    return c;
}

static QColor configColor(const QVariantMap& cfg, const QString& key, const QColor& fallback) {
    const QVariant v = cfg.value(key);
    if (!v.isValid())
        return fallback;
    if (v.userType() == QMetaType::QColor)
        return v.value<QColor>();
    const QString s = v.toString().trimmed();
    if (s.isEmpty())
        return fallback;
    return QColor(s);
}

void ClockModel::setConfig(const QVariantMap& config) {
    m_cfg = config;

    // Migration: adapt_to_theme bool -> color_mode string
    QString cm = m_cfg.value("colorMode").toString();
    if (m_cfg.value("adaptToTheme").toBool() && (cm.isEmpty() || cm == "custom"))
        cm = "theme";
    m_colorMode = cm.isEmpty() ? "custom" : cm;

    // Element order, validated + auto-append enabled elements (config migration)
    QStringList valid = {"day", "date", "time", "timezone"};
    QStringList base;
    const QString orderRaw = m_cfg.value("elementOrder").toString();
    if (!orderRaw.isEmpty()) {
        const auto parts = orderRaw.split(',');
        for (const QString& p : parts) {
            QString t = p.trimmed();
            if (valid.contains(t) && !base.contains(t))
                base.append(t);
        }
    } else {
        base = valid;
    }
    if (m_cfg.value("showTimezone").toBool() && !base.contains("timezone"))
        base.append("timezone");
    if (base.isEmpty())
        base = valid;
    m_order = base;

    m_now = currentDateTime();
    rebuildElements();
    scheduleNextTick();
}

void ClockModel::setThemeColors(const QColor& text, const QColor& bg) {
    m_systemTextColor = text.isValid() ? text : QColor(Qt::white);
    m_systemBgColor = bg.isValid() ? bg : QColor(Qt::black);
    recomputeElements();
}

void ClockModel::setWallpaperColor(const QColor& color) {
    m_hasWallpaperColor = color.isValid();
    m_wallpaperColor = color;
    recomputeElements();
}

void ClockModel::refresh() {
    m_now = currentDateTime();
    recomputeTexts();
}

QDateTime ClockModel::currentDateTime() const {
    QString custom = m_cfg.value("customDate").toString().trimmed();
    if (custom.isEmpty())
        return QDateTime::currentDateTime();
    QDateTime parsed = QDateTime::fromString(custom, Qt::ISODate);
    if (!parsed.isValid()) {
        QDate d = QDate::fromString(custom, Qt::ISODate);
        if (d.isValid())
            parsed = QDateTime(d, QTime(0, 0));
    }
    return parsed.isValid() ? parsed : QDateTime::currentDateTime();
}

// ---------------------------------------------------------------------------
// Model rebuild
// ---------------------------------------------------------------------------

void ClockModel::recomputeElements() {
    for (Element& e : m_elements) {
        e.color = resolveColor(e.type, configColor(m_cfg, "color" + capped(e.type), QColor(Qt::white)));
    }
    if (!m_elements.isEmpty())
        emit dataChanged(index(0), index(m_elements.size() - 1), {ColorRole});
}

void ClockModel::rebuildElements() {
    beginResetModel();
    m_elements.clear();

    auto showRole = [this](const QString& type) {
        return m_cfg.value("show" + capped(type)).toBool();
    };
    auto fontRole = [this](const QString& type) {
        QString f = m_cfg.value("font" + capped(type)).toString().trimmed();
        if (f.isEmpty())
            f = type == "day" ? QStringLiteral("Anurati") : QStringLiteral("Poppins");
        return f;
    };
    auto sizeRole = [this](const QString& type) {
        return m_cfg.value("size" + capped(type)).toInt();
    };
    auto spacingRole = [this](const QString& type) {
        return m_cfg.value("spacing" + capped(type)).toInt();
    };
    auto boldRole = [this](const QString& type) {
        return m_cfg.value("bold" + capped(type)).toBool();
    };

    for (const QString& type : m_order) {
        Element e;
        e.type = type;
        e.visible = showRole(type);
        e.fontFamily = fontRole(type);
        e.fontSize = sizeRole(type);
        e.spacing = spacingRole(type);
        e.bold = boldRole(type);
        e.color = resolveColor(type, configColor(m_cfg, "color" + capped(type), QColor(Qt::white)));
        m_elements.append(e);
    }
    endResetModel();

    recomputeTexts();
}

void ClockModel::recomputeTexts() {
    for (Element& e : m_elements) {
        if (e.type == "day") e.text = dayText();
        else if (e.type == "date") e.text = dateText();
        else if (e.type == "time") e.text = timeText();
        else if (e.type == "timezone") e.text = timezoneText();
    }
    if (!m_elements.isEmpty())
        emit dataChanged(index(0), index(m_elements.size() - 1), {TextRole});
}

// ---------------------------------------------------------------------------
// Timer
// ---------------------------------------------------------------------------

void ClockModel::scheduleNextTick() {
    const QDateTime now = QDateTime::currentDateTime();
    m_usesSeconds = currentTimeFormat().contains('s');

    int delay;
    if (m_usesSeconds) {
        delay = 1000 - now.time().msec();
    } else {
        delay = 60000 - (now.time().second() * 1000) - now.time().msec();
    }
    m_timer.start(std::max(50, delay));
}

void ClockModel::tick() {
    m_now = currentDateTime();
    recomputeTexts();
    scheduleNextTick();
}

// ---------------------------------------------------------------------------
// Text formatting (all locale-aware, all in native code)
// ---------------------------------------------------------------------------

QLocale ClockModel::effectiveLocale() const {
    QString custom = m_cfg.value("locale").toString().trimmed();
    if (custom.isEmpty())
        return QLocale();
    return QLocale(custom.replace(QStringLiteral("-"), QStringLiteral("_")));
}

QString ClockModel::currentTimeFormat() const {
    QString custom = m_cfg.value("timeFormat").toString().trimmed();
    if (!custom.isEmpty())
        return custom;
    bool h24 = m_cfg.value("use24HourFormat").toBool();
    return h24 ? QStringLiteral("HH:mm") : QStringLiteral("hh:mm AP");
}

QString ClockModel::timezoneTimeFormat() const {
    QString base = currentTimeFormat();
    base.remove(QRegularExpression(QStringLiteral("[sz]{1,3}")));
    base.remove(QRegularExpression(QStringLiteral("[:\\s.]+$")));
    if (base.trimmed().isEmpty())
        base = m_cfg.value("use24HourFormat").toBool()
            ? QStringLiteral("HH:mm") : QStringLiteral("hh:mm");
    return base;
}

QString ClockModel::formatDate(const QDateTime& dt, const QString& format, bool uppercase) const {
    QLocale locale = effectiveLocale();
    QString text = locale.toString(dt, format);
    if (text.isEmpty())
        text = QLocale().toString(dt, format);
    return uppercase ? text.toUpper() : text;
}

QString ClockModel::formatTime(const QDateTime& dt, const QString& format) const {
    QLocale locale = effectiveLocale();
    QString text = locale.toString(dt, format);
    if (text.isEmpty())
        text = QLocale().toString(dt, format);
    return text;
}

QString ClockModel::dayText() const {
    QString format = m_cfg.value("dayFormat").toString().trimmed();
    if (format.isEmpty()) format = QStringLiteral("dddd");
    return formatDate(m_now, format, m_cfg.value("uppercaseDay").toBool());
}

QString ClockModel::dateText() const {
    QString format = m_cfg.value("dateFormat").toString().trimmed();
    if (format.isEmpty()) format = QStringLiteral("dd MMM yyyy");
    return formatDate(m_now, format, m_cfg.value("uppercaseDate").toBool());
}

QString ClockModel::timeText() const {
    QString text = formatTime(m_now, currentTimeFormat());
    QString deco = m_cfg.value("timeCharacter").toString().trimmed();
    if (deco.isEmpty())
        return text;
    return deco + " " + text + " " + deco;
}

QString ClockModel::timezoneText() const {
    QString tzId = m_cfg.value("timezoneId").toString();
    QString label = m_cfg.value("timezoneLabel").toString();
    if (tzId.isEmpty())
        return QString();

    QTimeZone tz(tzId.toUtf8());
    QString formatted;
    if (tz.isValid()) {
        QDateTime zoned = m_now.toTimeZone(tz);
        formatted = zoned.toString(timezoneTimeFormat());
    }
    if (formatted.isEmpty())
        formatted = QStringLiteral("??");
    return label.isEmpty() ? formatted : label + " " + formatted;
}

// ---------------------------------------------------------------------------
// Colors
// ---------------------------------------------------------------------------

QColor ClockModel::resolveColor(const QString& type, const QColor& custom) const {
    Q_UNUSED(type);
    if (m_colorMode == "theme")
        return m_systemTextColor;
    if (m_colorMode == "theme_inverse")
        return m_systemBgColor;
    if (m_colorMode == "wallpaper" && m_hasWallpaperColor)
        return m_wallpaperColor;
    return custom.isValid() ? custom : QColor(Qt::white);
}