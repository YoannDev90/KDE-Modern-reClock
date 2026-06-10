#include <QQmlExtensionPlugin>
#include <QJSEngine>
#include <QTimeZone>
#include <QDateTime>
#include <QDebug>
#include <QtQml/qqmlregistration.h>

class TimeZoneHelper : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
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
        return tz.standardTimeOffset(dateTime) + (tz.isDaylightTime(dateTime) ? tz.daylightTimeOffset(dateTime) : 0);
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

    // Returns an object compatible with Qt.formatDateTime(date, format, tz)
    Q_INVOKABLE QJSValue timeZoneObject(const QString& id) const {
        QTimeZone tz(id.toUtf8());
        if (!tz.isValid()) return QJSValue();

        QJSEngine engine;
        QJSValue obj = engine.newObject();
        auto now = QDateTime::currentDateTime();

        int offset = tz.standardTimeOffset(now);
        if (tz.isDaylightTime(now))
            offset += tz.daylightTimeOffset(now);

        obj.setProperty("offsetMinutes", offset / 60);
        obj.setProperty("abbreviation", tz.abbreviation(now));
        return obj;
    }
};

class ModernRecClockPlugin : public QQmlExtensionPlugin {
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QQmlExtensionInterface/1.0")
public:
    void registerTypes(const char* uri) override {
        Q_ASSERT(uri == QLatin1String("org.kde.plasma.private.modernreclock"));
        // Singleton is auto-registered via QML_ELEMENT + QML_SINGLETON
    }
};

#include "timezoneplugin.moc"