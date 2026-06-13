#include "timezonehelper.h"

TimeZoneHelper::TimeZoneHelper(QObject* parent)
    : QObject(parent) {}

bool TimeZoneHelper::isValidId(const QString& id) const {
    return QTimeZone::isTimeZoneIdAvailable(id.toUtf8());
}

QStringList TimeZoneHelper::availableTimeZoneIds() const {
    auto ids = QTimeZone::availableTimeZoneIds();
    QStringList result;
    result.reserve(ids.size());
    for (const auto& id : ids)
        result.append(QString::fromUtf8(id));
    return result;
}

int TimeZoneHelper::offsetAt(const QString& id, const QDateTime& dateTime) const {
    QTimeZone tz(id.toUtf8());
    if (!tz.isValid()) return 0;
    return tz.offsetFromUtc(dateTime);
}

QString TimeZoneHelper::displayName(const QString& id, const QDateTime& dateTime) const {
    QTimeZone tz(id.toUtf8());
    if (!tz.isValid()) return QString();
    return tz.displayName(dateTime);
}

QString TimeZoneHelper::abbreviation(const QString& id, const QDateTime& dateTime) const {
    QTimeZone tz(id.toUtf8());
    if (!tz.isValid()) return QString();
    return tz.abbreviation(dateTime);
}

bool TimeZoneHelper::isDaylightTime(const QString& id, const QDateTime& dateTime) const {
    QTimeZone tz(id.toUtf8());
    if (!tz.isValid()) return false;
    return tz.isDaylightTime(dateTime);
}

QVariantMap TimeZoneHelper::timeZoneObject(const QString& id) const {
    QTimeZone tz(id.toUtf8());
    if (!tz.isValid()) return QVariantMap();

    QVariantMap obj;
    auto now = QDateTime::currentDateTime();
    obj["offsetMinutes"] = tz.offsetFromUtc(now) / 60;
    obj["abbreviation"] = tz.abbreviation(now);
    return obj;
}

QString TimeZoneHelper::formatDateTimeInZone(const QDateTime& dateTime, const QString& format, const QString& tzId) const {
    QTimeZone tz(tzId.toUtf8());
    if (!tz.isValid()) return QString();
    QDateTime zoned = dateTime.toTimeZone(tz);
    return zoned.toString(format);
}
