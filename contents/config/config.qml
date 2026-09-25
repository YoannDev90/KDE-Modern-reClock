import QtQml
import org.kde.plasma.configuration
import org.kde.plasma.private.modernreclock as ModernRecClock

ConfigModel {
    Component.onCompleted: {
        if (ModernRecClock.Log)
            ModernRecClock.Log.info("config", "ConfigModel loaded — 2 categories: Appearance, Themes");
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
}
