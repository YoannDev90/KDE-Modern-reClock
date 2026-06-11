#include <QQmlExtensionPlugin>
#include <QQmlEngine>
#include <QJSEngine>
#include <QTimeZone>
#include <QDateTime>
#include <QDebug>

class TimeZoneHelper : public QObject {
    Q_OBJECT
public:
    explicit TimeZoneHelper(QObject* parent = nullptr) : QObject(parent) {}

    Q_INVOKABLE bool isValidId(const QString& id) const {
        return QTimeZone::isTimeZoneIdAvailable(id.toUtf8());
    }

    Q_INVOKABLE QStringList availableTimeZoneIds() const {
        auto ids = QTimeZone::availableTimeZoneIds();
        QStringList result;
        result.reserve(ids.size());
        for (const auto& id : ids)
            result.append(QString::fromUtf8(id));
        return result;
    }

    Q_INVOKABLE int offsetAt(const QString& id, const QDateTime& dateTime) const {
        QTimeZone tz(id.toUtf8());
        if (!tz.isValid()) return 0;
        return tz.offsetFromUtc(dateTime);
    }

    Q_INVOKABLE QString displayName(const QString& id, const QDateTime& dateTime) const {
        QTimeZone tz(id.toUtf8());
        if (!tz.isValid()) return QString();
        return tz.displayName(dateTime);
    }

    Q_INVOKABLE QString abbreviation(const QString& id, const QDateTime& dateTime) const {
        QTimeZone tz(id.toUtf8());
        if (!tz.isValid()) return QString();
        return tz.abbreviation(dateTime);
    }

    Q_INVOKABLE bool isDaylightTime(const QString& id, const QDateTime& dateTime) const {
        QTimeZone tz(id.toUtf8());
        if (!tz.isValid()) return false;
        return tz.isDaylightTime(dateTime);
    }

    // Returns a QVariantMap safe for QML consumption (no dangling QJSValue)
    Q_INVOKABLE QVariantMap timeZoneObject(const QString& id) const {
        QTimeZone tz(id.toUtf8());
        if (!tz.isValid()) return QVariantMap();

        QVariantMap obj;
        auto now = QDateTime::currentDateTime();
        obj["offsetMinutes"] = tz.offsetFromUtc(now) / 60;
        obj["abbreviation"] = tz.abbreviation(now);
        return obj;
    }

    // Format a datetime string for a given timezone
    Q_INVOKABLE QString formatDateTimeInZone(const QDateTime& dateTime, const QString& format, const QString& tzId) const {
        QTimeZone tz(tzId.toUtf8());
        if (!tz.isValid()) return QString();
        QDateTime zoned = dateTime.toTimeZone(tz);
        return zoned.toString(format);
    }
};

class ModernRecClockPlugin : public QQmlExtensionPlugin {
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QQmlExtensionInterface/1.0")
public:
    void registerTypes(const char* uri) override {
        Q_ASSERT(uri == QLatin1String("org.kde.plasma.private.modernreclock"));
        qmlRegisterSingletonType<TimeZoneHelper>(uri, 1, 0, "TimeZone",
            [](QQmlEngine*, QJSEngine*) -> QObject* {
                return new TimeZoneHelper();
            });
    }
};

#include "timezoneplugin.moc"