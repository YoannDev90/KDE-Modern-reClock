#include <QQmlExtensionPlugin>
#include <QQmlEngine>
#include <QJSEngine>

#include "timezonehelper.h"
#include "wallpaperhelper.h"
#include "logger.h"
#include "wallpaperimageprovider.h"
#include "thememanager.h"
#include "fonthelper.h"

class ModernRecClockPlugin : public QQmlExtensionPlugin {
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QQmlExtensionInterface/1.0")
    static Logger *s_logger;
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
                s_logger = new Logger();
                return s_logger;
            });
        qmlRegisterSingletonType<ThemeManager>(uri, 1, 0, "ThemeManager",
            [](QQmlEngine*, QJSEngine*) -> QObject* {
                ThemeManager *tm = new ThemeManager();
                if (s_logger) tm->setLogger(s_logger);
                return tm;
            });
        qmlRegisterSingletonType<FontHelper>(uri, 1, 0, "Fonts",
            [](QQmlEngine*, QJSEngine*) -> QObject* {
                return new FontHelper();
            });
    }

    void initializeEngine(QQmlEngine* engine, const char* uri) override {
        qDebug() << "[ModernRecClock] ModernRecClockPlugin::initializeEngine uri=" << uri << "engine=" << engine;
        engine->addImageProvider(QStringLiteral("modernreclock"), new WallpaperImageProvider());
        qDebug() << "[ModernRecClock] Image provider 'modernreclock' registered for engine" << engine;
        // Pre-fetch the (expensive) system font list in the background so the
        // first config-dialog open doesn't pay the fontconfig enumeration cost.
        FontHelper::prefetch();
    }
};

Logger* ModernRecClockPlugin::s_logger = nullptr;

#include "plugin.moc"