#include <QQmlExtensionPlugin>
#include <QQmlEngine>
#include <QJSEngine>

#include "timezonehelper.h"
#include "wallpaperhelper.h"
#include "logger.h"

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
        qmlRegisterSingletonType<WallpaperHelper>(uri, 1, 0, "Wallpaper",
            [](QQmlEngine*, QJSEngine*) -> QObject* {
                return new WallpaperHelper();
            });
        qmlRegisterSingletonType<Logger>(uri, 1, 0, "Log",
            [](QQmlEngine*, QJSEngine*) -> QObject* {
                return new Logger();
            });
    }
};

#include "plugin.moc"