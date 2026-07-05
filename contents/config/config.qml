import QtQml
import org.kde.plasma.configuration
import org.kde.plasma.private.modernreclock as ModernRecClock

ConfigModel {
    Component.onCompleted: {
        ModernRecClock.Log.info("config", "ConfigModel loaded — 3 categories: Appearance, Themes, Debug");
    }

    ConfigCategory {
        name: i18n("Appearance")
        icon: "preferences-desktop-color"
        source: "configAppearance.qml"
    }
    ConfigCategory {
        name: i18n("Themes")
        icon: "preferences-desktop-theme"
        source: "configThemes.qml"
    }
    ConfigCategory {
        name: i18n("Debug")
        icon: "tools-report-bug"
        source: "configDebug.qml"
    }
}
