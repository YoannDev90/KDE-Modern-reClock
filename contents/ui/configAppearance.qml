import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15

import org.kde.kcmutils 1.0 as KCM
import org.kde.kirigami 2.0 as Kirigami
import org.kde.plasma.private.modernreclock 1.0 as ModernRecClock

KCM.SimpleKCM {
    id: appearancePage

    // Logger shorthand — fallback to no-op if C++ plugin not loaded
    readonly property var log: ModernRecClock.Log ?? ({
        debug: function(cat, msg) {},
        info: function(cat, msg) {},
        warn: function(cat, msg) {},
        error: function(cat, msg) {}
    })

    // ===== Config keys — plain properties (no hidden controls needed) =====
    property bool cfg_show_day: true
    property bool cfg_show_date: true
    property bool cfg_show_time: true

    property int cfg_day_font_size: 72
    property int cfg_date_font_size: 19
    property int cfg_time_font_size: 19

    property int cfg_day_letter_spacing: 17
    property int cfg_date_letter_spacing: 3
    property int cfg_time_letter_spacing: 3

    property string cfg_day_font_color: "#FFFFFF"
    property string cfg_date_font_color: "#FFFFFF"
    property string cfg_time_font_color: "#FFFFFF"

    property string cfg_day_format: "dddd"
    property string cfg_date_format: "dd MMM yyyy"
    property string cfg_time_format: ""
    property bool cfg_use_24_hour_format: false
    property string cfg_time_character: "-"

    property bool cfg_uppercase_day: true
    property bool cfg_uppercase_date: true

    property bool cfg_day_font_bold: false
    property bool cfg_date_font_bold: false
    property bool cfg_time_font_bold: false

    property string cfg_fontFamilyDay: "Anurati"
    property string cfg_fontFamilyDate: "Poppins"
    property string cfg_fontFamilyTime: "Poppins"
    property string cfg_fontFamilyTimezone: "Poppins"

    property int cfg_widget_spacing: 5

    property string cfg_locale: ""
    property bool cfg_auto_scale: false
    property string cfg_alignMode: "none"
    property string cfg_color_mode: "custom"

    // ===== Timezone element properties =====
    property bool cfg_show_timezone: false
    property string cfg_timezone_id: ""
    property string cfg_timezone_label: ""
    property string cfg_timezone_display_text: ""
    property string cfg_custom_preview_date: ""
    property string cfg_timezone_format: "HH:mm"
    property int cfg_timezone_font_size: 19
    property int cfg_timezone_letter_spacing: 3
    property bool cfg_timezone_font_bold: false
    property string cfg_timezone_font_color: "#FFFFFF"

    property string cfg_element_order: "day,date,time,timezone"

    // ===== Saved themes =====
    property string cfg_saved_themes: ""

    // ===== System font list (shared JS array — assigned in one shot, no per-item signals) =====
    property var fontArray: []
    // O(1) font name → index lookup (built once during population)
    property var fontIndexCache: ({})

    // ===== Theme management =====
    // savedThemesJson is a simple bridge: KCM writes cfg_saved_themes → this mirrors it
    property string savedThemesJson: cfg_saved_themes || "[]"
    // Parse lazily: only when savedThemesJson actually changes, not as a binding
    property var savedThemes: []
    onSavedThemesJsonChanged: {
        try { savedThemes = JSON.parse(savedThemesJson); }
        catch (e) { savedThemes = []; }
    }

    // ===== C++ PREVIEW =====
    readonly property var themeManager: ModernRecClock.ThemeManager ?? null
    property string previewImagePath: ""

    Connections {
        target: appearancePage.themeManager
        function onPreviewGenerated(outPath) {
            appearancePage.previewImagePath = "file://" + outPath;
        }
    }

    // Serialize all cfg_ properties to JSON string
    function getFullConfig() {
        let cfg = {};
        configKeys.forEach(function(k) {
            cfg[k] = appearancePage["cfg_" + k];
        });
        return JSON.stringify(cfg);
    }

    // Apply a JSON config string back to cfg_ properties
    function applyConfig(jsonString) {
        try {
            let cfg = JSON.parse(jsonString);
            var count = 0;
            for (let k in cfg) {
                if (configKeys.indexOf(k) !== -1) {
                    appearancePage["cfg_" + k] = cfg[k];
                    count++;
                }
            }
            log.info("config", "applyConfig: applied " + count + " keys");
            return true;
        } catch (e) {
            log.warn("config", "applyConfig failed: " + e.message);
            return false;
        }
    }

    function _regeneratePreview() {
        if (!themeManager) return;
        var cfgJson = appearancePage.getFullConfig();
        var wpPath = ModernRecClock.Wallpaper ? (ModernRecClock.Wallpaper.wallpaperPath() || "") : "";
        log.info("config", "Generating preview (async)...");
        themeManager.generatePreviewAsync(cfgJson, wpPath, -1, [], "", "");
    }

    // Debounced: only fire after user stops interacting for a while
    Timer {
        id: regenTimer
        interval: 900
        repeat: false
        running: false
        onTriggered: appearancePage._regeneratePreview()
    }

    function refreshPreview() { regenTimer.restart(); }

    // Auto-derived from all cfg_ aliases — computed once at init (not a binding to avoid loops)
    property var configKeys: []
    Component.onCompleted: {
        // Defer all heavy init to after first paint — lets QML render the UI immediately
        Qt.callLater(function() {
            // Build full font list (single JS array) — assigned in ONE shot, no per-item signals.
            // Fonts come from the C++ cache (ModernRecClock.Fonts) — enumerated once per
            // plasmashell session in a background thread at plugin init, so subsequent
            // config opens are instant.
            var fonts = ModernRecClock.Fonts.fontFamilies();
            var all = ["Anurati", "Poppins"];
            for (var i = 0; i < fonts.length; i++) {
                if (all.indexOf(fonts[i]) === -1)
                    all.push(fonts[i]);
            }
            // Build O(1) name→index cache in the same single pass
            var cache = {};
            for (var j = 0; j < all.length; j++)
                cache[all[j]] = j;
            fontIndexCache = cache;
            // One-shot assignment: no ListModel.append() signal storm
            fontArray = all;
            log.info("config", "Font list loaded: " + all.length + " families");

            var keys = [];
            for (var prop in appearancePage) {
                if (prop.startsWith("cfg_") && typeof appearancePage[prop] !== "function") {
                    keys.push(prop.substring(4));
                }
            }
            configKeys = keys;
            log.info("config", "Config page opened — " + keys.length + " config keys discovered");
            log.info("config", "color_mode=" + cfg_color_mode + " locale=" + (cfg_locale || "(default)") + " auto_scale=" + cfg_auto_scale);
            // Every cfg_* change → debounced preview refresh
            for (var i = 0; i < configKeys.length; i++) {
                var sigName = "cfg_" + configKeys[i] + "Changed";
                try {
                    var sig = appearancePage[sigName];
                    if (typeof sig === 'function' && sig.connect) {
                        sig.connect(regenTimer.restart);
                    }
                } catch(e) {}
            }
            // Initial preview (Preview tab is active by default)
            _regeneratePreview();
        });
    }

    // ===== RESET FUNCTIONS (data-driven) =====
    // Refresh preview when the Preview tab becomes visible
    readonly property var sectionDefaults: ({
        "day": { show: true, font: "Anurati", size: 72, spacing: 17, format: "dddd", uppercase: true, bold: false, color: "#FFFFFF" },
        "date": { show: true, font: "Poppins", size: 19, spacing: 3, format: "dd MMM yyyy", uppercase: true, bold: false, color: "#FFFFFF" },
        "time": { show: true, font: "Poppins", size: 19, spacing: 3, format: "", uppercase: false, bold: false, color: "#FFFFFF", h24: false, deco: "-" },
        "timezone": { show: false, font: "Poppins", size: 19, spacing: 3, id: "", label: "", bold: false, color: "#FFFFFF" }
    })

    function resetSection(type) {
        var d = sectionDefaults[type];
        if (!d) return;
        log.info("config", "Resetting section: " + type);
        if (type === "day") {
            cfg_show_day = d.show;
            cfg_fontFamilyDay = d.font;
            cfg_day_font_size = d.size;
            cfg_day_letter_spacing = d.spacing;
            cfg_day_format = d.format;
            cfg_uppercase_day = d.uppercase;
            cfg_day_font_bold = d.bold;
            cfg_day_font_color = d.color;
        } else if (type === "date") {
            cfg_show_date = d.show;
            cfg_fontFamilyDate = d.font;
            cfg_date_font_size = d.size;
            cfg_date_letter_spacing = d.spacing;
            cfg_date_format = d.format;
            cfg_uppercase_date = d.uppercase;
            cfg_date_font_bold = d.bold;
            cfg_date_font_color = d.color;
        } else if (type === "time") {
            cfg_show_time = d.show;
            cfg_fontFamilyTime = d.font;
            cfg_time_font_size = d.size;
            cfg_time_letter_spacing = d.spacing;
            cfg_time_format = d.format || "";
            cfg_use_24_hour_format = d.h24 || false;
            cfg_time_character = d.deco || "-";
            cfg_time_font_bold = d.bold;
            cfg_time_font_color = d.color;
        } else if (type === "timezone") {
            cfg_show_timezone = d.show;
            cfg_fontFamilyTimezone = d.font;
            cfg_timezone_font_size = d.size;
            cfg_timezone_letter_spacing = d.spacing;
            cfg_timezone_id = d.id || "";
            cfg_timezone_display_text = "";
            cfg_timezone_label = d.label || "";
            cfg_timezone_format = "HH:mm";
            cfg_timezone_font_bold = d.bold;
            cfg_timezone_font_color = d.color;
        }
        refreshPreview();
    }

    // ===== THEME FUNCTIONS =====
    function saveCurrentTheme(name, description) {
        log.info("theme", "Saving theme: \"" + name + "\" — " + description);
        let cfg = {};
        configKeys.forEach(k => cfg[k] = appearancePage["cfg_" + k]);
        let themes = savedThemes.slice();
        themes.push({ "name": name, "description": description, "config": cfg });
        savedThemesJson = JSON.stringify(themes);
        cfg_saved_themes = savedThemesJson;
        log.info("theme", "Theme saved — total themes: " + themes.length);
    }

    function loadThemeConfig(index) {
        if (index < 0 || index >= savedThemes.length)
            return;
        let theme = savedThemes[index];
        if (!theme || !theme.config) {
            log.warn("theme", "Theme at index " + index + " has no valid config");
            return;
        }
        log.info("theme", "Loading theme: \"" + theme.name + "\"");
        applyConfig(JSON.stringify(theme.config));
        refreshPreview();
        log.info("theme", "Theme loaded successfully");
    }

    function deleteTheme(index) {
        if (index < 0 || index >= savedThemes.length)
            return;
        var name = savedThemes[index].name || "unnamed";
        log.info("theme", "Deleting theme: \"" + name + "\" (index " + index + ")");
        let themes = savedThemes.slice();
        themes.splice(index, 1);
        savedThemesJson = JSON.stringify(themes);
        cfg_saved_themes = savedThemesJson;
        log.info("theme", "Theme deleted — remaining: " + themes.length);
    }

    function themeToJSON(index) {
        if (index < 0 || index >= savedThemes.length)
            return "";
        return JSON.stringify(savedThemes[index], null, 4);
    }

    // ===== UI: tabbed layout (all pages preloaded) =====
    ColumnLayout {
        Layout.fillWidth: true
        Layout.maximumWidth: Kirigami.Units.gridUnit * 32
        Layout.alignment: Qt.AlignHCenter
        spacing: Kirigami.Units.largeSpacing

        QQC2.TabBar {
            id: tabBar
            Layout.fillWidth: true

            QQC2.TabButton { text: i18n("Preview") }
            QQC2.TabButton { text: i18n("Global") }
            QQC2.TabButton { text: i18n("Day") }
            QQC2.TabButton { text: i18n("Date") }
            QQC2.TabButton { text: i18n("Time") }
            QQC2.TabButton { text: i18n("Timezone") }
            QQC2.TabButton { text: i18n("Saved Themes") }
        }

        StackLayout {
            id: stack
            Layout.fillWidth: true
            currentIndex: tabBar.currentIndex
            onCurrentIndexChanged: {
                // Regenerate preview when switching back to the Preview tab
                if (currentIndex === 0) regenTimer.restart();
            }

            configPreviewPage {
                ctx: appearancePage
                Layout.fillWidth: true
            }
            configGlobalPage {
                ctx: appearancePage
                Layout.fillWidth: true
            }
            configDayPage {
                ctx: appearancePage
                Layout.fillWidth: true
            }
            configDatePage {
                ctx: appearancePage
                Layout.fillWidth: true
            }
            configTimePage {
                ctx: appearancePage
                Layout.fillWidth: true
            }
            configTimezonePage {
                ctx: appearancePage
                Layout.fillWidth: true
            }
            Loader {
                id: savedThemesTab
                Layout.fillWidth: true
                active: true
                source: "configSavedThemesPage.qml"
                onLoaded: item.ctx = appearancePage
            }
        }
    }

    // ===== Theme Sheets (kept on the shell; used by Preview/Saved Themes tabs) =====
    ThemeSheets {
        id: themeSheets
        getFullConfig: appearancePage.getFullConfig
        applyConfig: appearancePage.applyConfig
        updatePreview: function() { regenTimer.restart(); }
        saveThemeFn: appearancePage.saveCurrentTheme
        deleteThemeFn: appearancePage.deleteTheme
        loadThemeFn: appearancePage.loadThemeConfig
        themeToJSONFn: appearancePage.themeToJSON
        themes: appearancePage.savedThemes
        setThemesJson: function(json) {
            appearancePage.savedThemesJson = json;
            cfg_saved_themes = json;
        }
    }
}