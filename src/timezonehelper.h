#pragma once

#include <QObject>
#include <QTimeZone>
#include <QDateTime>
#include <QString>
#include <QStringList>
#include <QVariantMap>

class TimeZoneHelper : public QObject {
    Q_OBJECT
public:
    explicit TimeZoneHelper(QObject* parent = nullptr);

    Q_INVOKABLE bool isValidId(const QString& id) const;
    Q_INVOKABLE QStringList availableTimeZoneIds() const;
    Q_INVOKABLE int offsetAt(const QString& id, const QDateTime& dateTime) const;
    Q_INVOKABLE QString displayName(const QString& id, const QDateTime& dateTime) const;
    Q_INVOKABLE QString abbreviation(const QString& id, const QDateTime& dateTime) const;
    Q_INVOKABLE bool isDaylightTime(const QString& id, const QDateTime& dateTime) const;
    Q_INVOKABLE QVariantMap timeZoneObject(const QString& id) const;
    Q_INVOKABLE QString formatDateTimeInZone(const QDateTime& dateTime, const QString& format, const QString& tzId) const;
};
