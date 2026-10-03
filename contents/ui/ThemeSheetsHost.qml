import QtQuick 2.15

/**
 * Hosts ThemeSheets with live bindings for configAppearance.qml.
 * Kept in its own file so the taskbar package can drop both this file
 * and ThemeSheets.qml without configAppearance.qml referencing them.
 */
Item {
    id: host

    property var ctx: null

    ThemeSheets {
        id: sheets
        getFullConfig: host.ctx.getFullConfig
        applyConfig: host.ctx.applyConfig
        updatePreview: function() { host.ctx.refreshPreview(); }
        saveThemeFn: host.ctx.saveCurrentTheme
        deleteThemeFn: host.ctx.deleteTheme
        loadThemeFn: host.ctx.loadThemeConfig
        themeToJSONFn: host.ctx.themeToJSON
        themes: host.ctx.savedThemes
        setThemesJson: function(json) {
            host.ctx.savedThemesJson = json;
            host.ctx.cfg_saved_themes = json;
        }
    }
}
