#include "timezonehelper.h"
#include <QDebug>

TimeZoneHelper::TimeZoneHelper(QObject* parent)
    : QObject(parent) {
    qDebug() << "[ModernRecClock] TimeZoneHelper created";
}

bool TimeZoneHelper::isValidId(const QString& id) const {
    bool valid = QTimeZone::isTimeZoneIdAvailable(id.toUtf8());
    qDebug() << "[ModernRecClock] TimeZoneHelper::isValidId" << id << "→" << valid;
    return valid;
}

QStringList TimeZoneHelper::availableTimeZoneIds() const {
    auto ids = QTimeZone::availableTimeZoneIds();
    QStringList result;
    result.reserve(ids.size());
    for (const auto& id : ids)
        result.append(QString::fromUtf8(id));
    qDebug() << "[ModernRecClock] TimeZoneHelper::availableTimeZoneIds →" << result.size() << "zones";
    return result;
}

int TimeZoneHelper::offsetAt(const QString& id, const QDateTime& dateTime) const {
    QTimeZone tz(id.toUtf8());
    if (!tz.isValid()) {
        qDebug() << "[ModernRecClock] TimeZoneHelper::offsetAt INVALID tz:" << id;
        return 0;
    }
    int offset = tz.offsetFromUtc(dateTime);
    qDebug() << "[ModernRecClock] TimeZoneHelper::offsetAt" << id << "→" << offset;
    return offset;
}

QString TimeZoneHelper::displayName(const QString& id, const QDateTime& dateTime) const {
    QTimeZone tz(id.toUtf8());
    if (!tz.isValid()) {
        qDebug() << "[ModernRecClock] TimeZoneHelper::displayName INVALID tz:" << id;
        return QString();
    }
    QString name = tz.displayName(dateTime);
    qDebug() << "[ModernRecClock] TimeZoneHelper::displayName" << id << "→" << name;
    return name;
}

QString TimeZoneHelper::abbreviation(const QString& id, const QDateTime& dateTime) const {
    QTimeZone tz(id.toUtf8());
    if (!tz.isValid()) {
        qDebug() << "[ModernRecClock] TimeZoneHelper::abbreviation INVALID tz:" << id;
        return QString();
    }
    QString abbr = tz.abbreviation(dateTime);
    qDebug() << "[ModernRecClock] TimeZoneHelper::abbreviation" << id << "→" << abbr;
    return abbr;
}

bool TimeZoneHelper::isDaylightTime(const QString& id, const QDateTime& dateTime) const {
    QTimeZone tz(id.toUtf8());
    if (!tz.isValid()) {
        qDebug() << "[ModernRecClock] TimeZoneHelper::isDaylightTime INVALID tz:" << id;
        return false;
    }
    bool dst = tz.isDaylightTime(dateTime);
    qDebug() << "[ModernRecClock] TimeZoneHelper::isDaylightTime" << id << "→" << dst;
    return dst;
}

QVariantMap TimeZoneHelper::timeZoneObject(const QString& id) const {
    QTimeZone tz(id.toUtf8());
    if (!tz.isValid()) {
        qDebug() << "[ModernRecClock] TimeZoneHelper::timeZoneObject INVALID tz:" << id;
        return QVariantMap();
    }
    auto now = QDateTime::currentDateTime();
    QVariantMap obj;
    obj["offsetMinutes"] = tz.offsetFromUtc(now) / 60;
    obj["abbreviation"] = tz.abbreviation(now);
    qDebug() << "[ModernRecClock] TimeZoneHelper::timeZoneObject" << id << "→ offset=" << obj["offsetMinutes"] << "abbr=" << obj["abbreviation"];
    return obj;
}

QString TimeZoneHelper::formatDateTimeInZone(const QDateTime& dateTime, const QString& format, const QString& tzId) const {
    QTimeZone tz(tzId.toUtf8());
    if (!tz.isValid()) {
        qDebug() << "[ModernRecClock] TimeZoneHelper::formatDateTimeInZone INVALID tz:" << tzId;
        return QString();
    }
    QDateTime zoned = dateTime.toTimeZone(tz);
    QString result = zoned.toString(format);
    qDebug() << "[ModernRecClock] TimeZoneHelper::formatDateTimeInZone" << tzId << "fmt=" << format << "→" << result;
    return result;
}
