import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("Appearance")
        icon: "preferences-desktop-color"
        source: "configAppearance.qml"
    }
    ConfigCategory {
        name: i18n("About")
        icon: "help-about"
        source: "configAbout.qml"
    }
}
