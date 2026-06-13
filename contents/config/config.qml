import QtQml
import org.kde.plasma.configuration
import org.kde.plasma.private.modernreclock as ModernRecClock

ConfigModel {
    Component.onCompleted: {
        ModernRecClock.Log.info("config", "ConfigModel loaded — 2 categories: Appearance, Debug");
    }

    ConfigCategory {
        name: i18n("Appearance")
        icon: "preferences-desktop-color"
        source: "configAppearance.qml"
    }
    ConfigCategory {
        name: i18n("Debug")
        icon: "tools-report-bug"
        source: "configDebug.qml"
    }
}
