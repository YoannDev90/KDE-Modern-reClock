#include <QQmlExtensionPlugin>
#include <QQmlEngine>
#include <QJSEngine>

#include "timezonehelper.h"
#include "wallpaperhelper.h"
#include "logger.h"
#include "wallpaperimageprovider.h"

class ModernRecClockPlugin : public QQmlExtensionPlugin {
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QQmlExtensionInterface/1.0")
public:
    void registerTypes(const char* uri) override {
        qDebug() << "[ModernRecClock] ModernRecClockPlugin::registerTypes uri=" << uri;
        Q_ASSERT(uri == QLatin1String("org.kde.plasma.private.modernreclock"));
        qmlRegisterSingletonType<TimeZoneHelper>(uri, 1, 0, "TimeZone",
            [](QQmlEngine*, QJSEngine*) -> QObject* {
                qDebug() << "[ModernRecClock] Creating TimeZoneHelper singleton";
                return new TimeZoneHelper();
            });
        qmlRegisterSingletonType<WallpaperHelper>(uri, 1, 0, "Wallpaper",
            [](QQmlEngine*, QJSEngine*) -> QObject* {
                qDebug() << "[ModernRecClock] Creating WallpaperHelper singleton";
                return new WallpaperHelper();
            });
        qmlRegisterSingletonType<Logger>(uri, 1, 0, "Log",
            [](QQmlEngine*, QJSEngine*) -> QObject* {
                qDebug() << "[ModernRecClock] Creating Logger singleton";
                return new Logger();
            });
        qDebug() << "[ModernRecClock] ModernRecClockPlugin::registerTypes done";
    }

    void initializeEngine(QQmlEngine* engine, const char* uri) override {
        qDebug() << "[ModernRecClock] ModernRecClockPlugin::initializeEngine uri=" << uri << "engine=" << engine;
        engine->addImageProvider(QStringLiteral("modernreclock"), new WallpaperImageProvider());
        qDebug() << "[ModernRecClock] Image provider 'modernreclock' registered for engine" << engine;
    }
};

#include "plugin.moc"