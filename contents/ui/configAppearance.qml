import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQControls
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.modernreclock as ModernRecClock

KCM.SimpleKCM {
    id: appearancePage

    // Logger shorthand
    readonly property var log: ModernRecClock.Log

    // properties
    property alias cfg_show_day: showDay.checked
    property alias cfg_show_date: showDate.checked
    property alias cfg_show_time: showTime.checked

    property alias cfg_day_font_size: dayFontSize.value
    property alias cfg_date_font_size: dateFontSize.value
    property alias cfg_time_font_size: timeFontSize.value

    property alias cfg_day_letter_spacing: dayLetterSpacing.value
    property alias cfg_date_letter_spacing: dateLetterSpacing.value
    property alias cfg_time_letter_spacing: timeLetterSpacing.value

    property alias cfg_day_font_color: dayFontColor.color
    property alias cfg_date_font_color: dateFontColor.color
    property alias cfg_time_font_color: timeFontColor.color

    property alias cfg_day_format: dayFormat.text
    property alias cfg_date_format: dateFormat.text
    property alias cfg_time_format: timeFormat.text
    property alias cfg_use_24_hour_format: use24HourFormat.checked
    property alias cfg_time_character: timeCharacter.text

    property alias cfg_uppercase_day: uppercaseDay.checked
    property alias cfg_uppercase_date: uppercaseDate.checked

    property alias cfg_day_font_bold: dayFontBold.checked
    property alias cfg_date_font_bold: dateFontBold.checked
    property alias cfg_time_font_bold: timeFontBold.checked

    property alias cfg_fontFamilyDay: _fontFamilyDayStorage.text
    property alias cfg_fontFamilyDate: _fontFamilyDateStorage.text
    property alias cfg_fontFamilyTime: _fontFamilyTimeStorage.text
    property alias cfg_fontFamilyCustom: _fontFamilyCustomStorage.text
    property alias cfg_fontFamilyTimezone: _fontFamilyTimezoneStorage.text

    property alias cfg_widget_spacing: widgetSpacing.value

    property alias cfg_locale: localeField.text
    property alias cfg_auto_scale: autoScale.checked
    property string cfg_alignMode: "none"
    property string cfg_color_mode: "custom"
    property bool cfg_adapt_to_theme: false // deprecated, kept for migration

    // ===== Custom text element properties =====
    property alias cfg_show_custom: showCustom.checked
    property alias cfg_custom_text: customTextField.text
    property alias cfg_custom_format: customFormat.checked
    property alias cfg_custom_font_size: customFontSize.value
    property alias cfg_custom_letter_spacing: customLetterSpacing.value
    property alias cfg_custom_font_bold: customFontBold.checked
    property alias cfg_custom_font_color: customFontColor.color

    // ===== Timezone element properties =====
    property alias cfg_show_timezone: showTimezone.checked
    property string cfg_timezone_id: ""
    property alias cfg_timezone_label: timezoneLabel.text
    property string cfg_timezone_display_text: ""
    property string cfg_custom_preview_date: ""
    property alias cfg_timezone_format: _timezoneFmtStorage.text
    property alias cfg_timezone_font_size: timezoneFontSize.value
    property alias cfg_timezone_letter_spacing: timezoneLetterSpacing.value
    property alias cfg_timezone_font_bold: timezoneFontBold.checked
    property alias cfg_timezone_font_color: timezoneFontColor.color

    property alias cfg_element_order: elementOrderField.text

    // ===== Saved themes (plain string alias for KCM sync) =====
    property alias cfg_saved_themes: _savedThemesStorage.text

    // ===== System font list =====
    readonly property var systemFontList: {
        var fonts = Qt.fontFamilies();
        var bundled = ["Anurati", "Poppins"];
        var result = bundled.slice();
        for (var i = 0; i < fonts.length; i++) {
            if (bundled.indexOf(fonts[i]) === -1)
                result.push(fonts[i]);
        }
        return result;
    }

    // ===== Theme management =====
    property string savedThemesJson: cfg_saved_themes || "[]"
    property var savedThemes: {
        try { return JSON.parse(savedThemesJson); }
        catch (e) { return []; }
    }

    // ===== System theme colors =====
    readonly property bool _hasTheme: typeof PlasmaCore.Theme !== 'undefined' && PlasmaCore.Theme !== null
    readonly property color systemTextColor: _hasTheme && PlasmaCore.Theme.textColor ? PlasmaCore.Theme.textColor : "#FFFFFF"
    readonly property color systemBgColor: {
        var r = 1.0 - systemTextColor.r;
        var g = 1.0 - systemTextColor.g;
        var b = 1.0 - systemTextColor.b;
        return Qt.rgba(r, g, b, 1.0);
    }

    // ===== C++ PREVIEW =====
    readonly property var themeManager: ModernRecClock.ThemeManager
    property string previewImagePath: ""

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
        var cfgJson = appearancePage.getFullConfig();
        var wpPath = ModernRecClock.Wallpaper ? (ModernRecClock.Wallpaper.wallpaperPath() || "") : "";
        log.info("config", "Generating preview...");
        // Pass all params explicitly — QML may not handle C++ default args
        var out = themeManager.generatePreview(cfgJson, wpPath, -1, [], "", "");
        log.info("config", "AFTER genPreview type=" + (typeof out) + " len=" + (out !== null && out !== undefined ? out.length : -1) + " val='" + (out || "") + "'");
        if (out !== undefined && out !== null && out.length > 0) {
            log.info("config", "Preview OK: " + out);
            previewImagePath = "file://" + out;
        } else {
            log.warn("config", "Preview generation returned empty path. out=" + (out === undefined ? "undefined" : out === null ? "null" : out));
        }
    }

    Timer {
        id: regenTimer
        interval: 400
        repeat: false
        running: false
        onTriggered: appearancePage._regeneratePreview()
    }

    // Auto-derived from all cfg_ aliases — computed once at init (not a binding to avoid loops)
    property var configKeys: []
    Component.onCompleted: {
        var keys = [];
        for (var prop in appearancePage) {
            if (prop.startsWith("cfg_") && typeof appearancePage[prop] !== "function") {
                keys.push(prop.substring(4));
            }
        }
        configKeys = keys;
        log.info("config", "Config page opened — " + keys.length + " config keys discovered");
        log.info("config", "color_mode=" + cfg_color_mode + " locale=" + (cfg_locale || "(default)") + " auto_scale=" + cfg_auto_scale);
        // Connect every known cfg_ signal to debounced regeneration (more reliable than for...in)
        for (var i = 0; i < configKeys.length; i++) {
            var sigName = "cfg_" + configKeys[i] + "Changed";
            try {
                var sig = appearancePage[sigName];
                if (typeof sig === 'function' && sig.connect) {
                    sig.connect(regenTimer.restart);
                }
            } catch(e) {}
        }
        // Initial preview generation
        _regeneratePreview();
        // Delayed retry in case KCM properties weren't synced yet
        retryTimer.start();
    }

    Timer {
        id: retryTimer
        interval: 500
        repeat: false
        onTriggered: {
            if (!appearancePage.previewImagePath || appearancePage.previewImagePath.length === 0)
                appearancePage._regeneratePreview();
        }
    }

    // ===== RESET FUNCTIONS (data-driven) =====
    readonly property var sectionDefaults: ({
        "day": { show: true, font: "Anurati", size: 72, spacing: 17, format: "dddd", uppercase: true, bold: false, color: "#FFFFFF" },
        "date": { show: true, font: "Poppins", size: 19, spacing: 3, format: "dd MMM yyyy", uppercase: true, bold: false, color: "#FFFFFF" },
        "time": { show: true, font: "Poppins", size: 19, spacing: 3, format: "", uppercase: false, bold: false, color: "#FFFFFF", h24: false, deco: "-" },
        "custom": { show: false, font: "Poppins", size: 19, spacing: 3, text: "", formatText: false, bold: false, color: "#FFFFFF" },
        "timezone": { show: false, font: "Poppins", size: 19, spacing: 3, id: "", label: "", bold: false, color: "#FFFFFF" }
    })

    function resetSection(type) {
        var d = sectionDefaults[type];
        if (!d) return;
        log.info("config", "Resetting section: " + type);
        if (type === "day") {
            showDay.checked = d.show;
            cfg_fontFamilyDay = d.font;
            dayFontCombo.currentIndex = Math.max(0, dayFontCombo.model.indexOf(d.font));
            dayFontSize.value = d.size;
            dayLetterSpacing.value = d.spacing;
            dayFormat.text = d.format;
            uppercaseDay.checked = d.uppercase;
            dayFontBold.checked = d.bold;
            dayFontColor.color = d.color;
        } else if (type === "date") {
            showDate.checked = d.show;
            cfg_fontFamilyDate = d.font;
            dateFontCombo.currentIndex = Math.max(0, dateFontCombo.model.indexOf(d.font));
            dateFontSize.value = d.size;
            dateLetterSpacing.value = d.spacing;
            dateFormat.text = d.format;
            uppercaseDate.checked = d.uppercase;
            dateFontBold.checked = d.bold;
            dateFontColor.color = d.color;
        } else if (type === "time") {
            showTime.checked = d.show;
            cfg_fontFamilyTime = d.font;
            timeFontCombo.currentIndex = Math.max(0, timeFontCombo.model.indexOf(d.font));
            timeFontSize.value = d.size;
            timeLetterSpacing.value = d.spacing;
            timeFormat.text = d.format || "";
            use24HourFormat.checked = d.h24 || false;
            timeCharacter.text = d.deco || "-";
            timeFontBold.checked = d.bold;
            timeFontColor.color = d.color;
        } else if (type === "custom") {
            showCustom.checked = d.show;
            cfg_fontFamilyCustom = d.font;
            customFontCombo.currentIndex = Math.max(0, customFontCombo.model.indexOf(d.font));
            customFontSize.value = d.size;
            customLetterSpacing.value = d.spacing;
            customTextField.text = d.text || "";
            customFormat.checked = d.formatText || false;
            customFontBold.checked = d.bold;
            customFontColor.color = d.color;
        } else if (type === "timezone") {
            showTimezone.checked = d.show;
            cfg_fontFamilyTimezone = d.font;
            timezoneFontCombo.currentIndex = Math.max(0, timezoneFontCombo.model.indexOf(d.font));
            timezoneFontSize.value = d.size;
            timezoneLetterSpacing.value = d.spacing;
            appearancePage.cfg_timezone_id = d.id || "";
            appearancePage.cfg_timezone_display_text = "";
            // Select matching preset in ComboBox or set custom text
            var tzVal = d.id || "";
            var found = false;
            for (var j = 0; j < timezoneIdField.model.count; j++) {
                if (timezoneIdField.model.get(j).value === tzVal) {
                    timezoneIdField.currentIndex = j;
                    timezoneIdField.editText = timezoneIdField.model.get(j).text;
                    appearancePage.cfg_timezone_display_text = timezoneIdField.model.get(j).text;
                    found = true;
                    break;
                }
            }
            if (!found && tzVal.length > 0) {
                timezoneIdField.editText = tzVal;
                appearancePage.cfg_timezone_display_text = tzVal;
            } else if (!found) {
                timezoneIdField.currentIndex = 0;
            }
            timezoneLabel.text = d.label || "";
            timezoneFmt.text = "";
            timezoneFontBold.checked = d.bold;
            timezoneFontColor.color = d.color;
        }
        regenTimer.restart();
    }

    function resetGlobal() {
        log.info("config", "Resetting all settings to defaults");
        autoScale.checked = false;
        _colorModeStorage.text = "custom";
        colorModeCombo.currentIndex = 0;
        widgetSpacing.value = 5;
        localeField.text = "";
        orderSection.resetRequested();
        languageCombo.currentIndex = 0;
        regenTimer.restart();
    }

    function resetDay() { resetSection("day"); }
    function resetDate() { resetSection("date"); }
    function resetTime() { resetSection("time"); }
    function resetCustom() { resetSection("custom"); }
    function resetTimezone() { resetSection("timezone"); }

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
        regenTimer.restart();
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



    // ================= SECTION: LIVE PREVIEW =================
    ColumnLayout {
        id: _appearanceLayout
        spacing: Kirigami.Units.largeSpacing

    Kirigami.Heading {
        text: i18n("Preview")
        level: 2
        Layout.fillWidth: true
    }

    // Centered preview — fixed 350px height, 16:9 width
    Rectangle {
        id: previewFrame
        Layout.fillWidth: true
        Layout.preferredHeight: 350
        Layout.maximumWidth: 350 * 16 / 9
        Layout.alignment: Qt.AlignHCenter
        color: "#2a2a2a"
        border.color: "#555"
        border.width: 1
        radius: Kirigami.Units.cornerRadius
        clip: true

        Image {
            id: previewImage
            anchors.centerIn: parent
            width: Math.min(parent.width - Kirigami.Units.gridUnit, 350 * 16 / 9)
            height: parent.height
            fillMode: Image.PreserveAspectFit
            source: appearancePage.previewImagePath
            onStatusChanged: {
                if (status === Image.Ready) log.info("config", "IMG ready: " + source);
                else if (status === Image.Error) log.warn("config", "IMG ERROR: " + source);
                else if (status === Image.Loading) log.info("config", "IMG loading: " + source);
            }

            QQC2.BusyIndicator {
                anchors.centerIn: parent
                running: parent.status === Image.Loading
            }

            QQC2.Label {
                anchors.centerIn: parent
                text: i18n("Adjust settings to generate preview")
                color: Kirigami.Theme.disabledTextColor
                visible: parent.status !== Image.Ready && parent.status !== Image.Loading
            }
        }
    }

    Kirigami.FormLayout {
        Layout.fillWidth: true

        // ================= SECTION: GLOBAL =================
        Kirigami.Heading {
            text: i18n("Global")
            level: 2
            Layout.fillWidth: true
            Kirigami.FormData.isSection: true
        }

        QQC2.CheckBox {
            id: autoScale
            text: i18n("Auto-scale (fitting widget size)")
            onCheckedChanged: {
                if (appearancePage.cfg_auto_scale !== checked) {
                    appearancePage.cfg_auto_scale = checked;
                }
            }
        }

        // Alignment mode
        RowLayout {
            Kirigami.FormData.label: i18n("Alignment:")
            spacing: Kirigami.Units.smallSpacing

            Repeater {
                model: [
                    { label: i18n("None"), value: "none" },
                    { label: i18n("Center"), value: "center" },
                    { label: i18n("Center H"), value: "centerH" },
                    { label: i18n("Center V"), value: "centerV" }
                ]
                QQC2.RadioButton {
                    text: modelData.label
                    checked: appearancePage.cfg_alignMode === modelData.value
                    onToggled: if (checked) appearancePage.cfg_alignMode = modelData.value
                }
            }
        }

        QQC2.ComboBox {
            id: colorModeCombo
            Kirigami.FormData.label: i18n("Color mode:")
            Layout.fillWidth: true
            model: [
                { text: i18n("Custom"), value: "custom" },
                { text: i18n("Follow system theme"), value: "theme" },
                { text: i18n("Inverse system theme"), value: "theme_inverse" },
                { text: i18n("Wallpaper-derived"), value: "wallpaper" }
            ]
            textRole: "text"
            valueRole: "value"
            currentIndex: {
                var mode = appearancePage.cfg_color_mode || "custom";
                for (var i = 0; i < model.length; i++) {
                    if (model[i].value === mode) return i;
                }
                return 0;
            }
            onActivated: {
                var v = model[currentIndex].value;
                _colorModeStorage.text = v;
                regenTimer.restart();
            }
            QQC2.ToolTip.text: i18n("Custom: each element has its own color.\\nFollow system theme: text color adapts to desktop theme.\\nInverse: inverted system colors for contrast.\\nWallpaper: text color derived from wallpaper brightness.")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 800
        }

        QQC2.SpinBox {
            id: widgetSpacing
            Kirigami.FormData.label: i18n("Element spacing:")
            from: 0
            to: 999
        }

        // ===== LOCALE SECTION =====
        QQC2.ComboBox {
            id: localePresetCombo
            Kirigami.FormData.label: i18n("Locale Preset:")
            Layout.fillWidth: true
            model: [
                { "text": i18n("System Default"), "locale": "", "day": "dddd", "date": "dd MMM yyyy", "time": "", "h24": true },
                { "text": i18n("French"), "locale": "fr_FR", "day": "dddd", "date": "d MMMM yyyy", "time": "HH\'h\'mm", "h24": true },
                { "text": i18n("English (US)"), "locale": "en_US", "day": "dddd", "date": "MMMM d, yyyy", "time": "h:mm AP", "h24": false },
                { "text": i18n("English (UK)"), "locale": "en_GB", "day": "dddd", "date": "d MMMM yyyy", "time": "HH:mm", "h24": true },
                { "text": i18n("German"), "locale": "de_DE", "day": "dddd", "date": "d. MMMM yyyy", "time": "HH:mm", "h24": true },
                { "text": i18n("Spanish"), "locale": "es_ES", "day": "dddd", "date": "d \'de\' MMMM \'de\' yyyy", "time": "HH:mm", "h24": true },
                { "text": i18n("Italian"), "locale": "it_IT", "day": "dddd", "date": "d MMMM yyyy", "time": "HH:mm", "h24": true },
                { "text": i18n("Dutch"), "locale": "nl_NL", "day": "dddd", "date": "d MMMM yyyy", "time": "HH:mm", "h24": true },
                { "text": i18n("Polish"), "locale": "pl_PL", "day": "dddd", "date": "d MMMM yyyy", "time": "HH:mm", "h24": true },
                { "text": i18n("Portuguese"), "locale": "pt_PT", "day": "dddd", "date": "d MMMM yyyy", "time": "HH:mm", "h24": true },
                { "text": i18n("Russian"), "locale": "ru_RU", "day": "dddd", "date": "d MMMM yyyy", "time": "HH:mm", "h24": true },
                { "text": i18n("Japanese"), "locale": "ja_JP", "day": "dddd", "date": "yyyy年M月d日", "time": "H:mm", "h24": true },
                { "text": i18n("Custom"), "locale": "custom" }
            ]
            textRole: "text"
            Component.onCompleted: {
                if (!appearancePage) return;
                let loc = appearancePage.cfg_locale;
                currentIndex = 0;
                for (let i = 0; i < model.length; i++) { if (model[i].locale === loc) { currentIndex = i; break; } }
                if (currentIndex === 0 && loc !== "") currentIndex = model.length - 1;
            }
            onActivated: {
                let item = model[currentIndex];
                if (item.locale !== "custom") {
                    appearancePage.cfg_locale = item.locale;
                    if (item.day !== undefined) appearancePage.cfg_day_format = item.day;
                    if (item.date !== undefined) appearancePage.cfg_date_format = item.date;
                    if (item.time !== undefined) appearancePage.cfg_time_format = item.time;
                    if (item.h24 !== undefined) appearancePage.cfg_use_24_hour_format = item.h24;
                }
            }
        }

        QQC2.ComboBox {
            id: textLanguageCombo
            Kirigami.FormData.label: i18n("Language:")
            Layout.fillWidth: true
            model: [
                { "text": i18n("System Default"), "locale": "" },
                { "text": i18n("French"), "locale": "fr_FR" },
                { "text": i18n("English (US)"), "locale": "en_US" },
                { "text": i18n("English (UK)"), "locale": "en_GB" },
                { "text": i18n("German"), "locale": "de_DE" },
                { "text": i18n("Spanish"), "locale": "es_ES" },
                { "text": i18n("Italian"), "locale": "it_IT" },
                { "text": i18n("Dutch"), "locale": "nl_NL" },
                { "text": i18n("Polish"), "locale": "pl_PL" },
                { "text": i18n("Portuguese"), "locale": "pt_PT" },
                { "text": i18n("Russian"), "locale": "ru_RU" },
                { "text": i18n("Japanese"), "locale": "ja_JP" }
            ]
            textRole: "text"
            Component.onCompleted: {
                if (!appearancePage) return;
                let loc = appearancePage.cfg_locale;
                currentIndex = 0;
                for (let i = 0; i < model.length; i++) { if (model[i].locale === loc) { currentIndex = i; break; } }
            }
            onActivated: {
                appearancePage.cfg_locale = model[currentIndex].locale;
                // Auto-switch locale preset to Custom
                for (let i = 0; i < localePresetCombo.model.length; i++) {
                    if (localePresetCombo.model[i].locale === "custom") { localePresetCombo.currentIndex = i; break; }
                }
            }
        }

        QQC2.ComboBox {
            id: dateFormatCombo
            Kirigami.FormData.label: i18n("Date/Time Format:")
            Layout.fillWidth: true
            model: [
                { "text": "dd MMMM yyyy / HH:mm", "date": "dd MMMM yyyy", "time": "HH:mm" },
                { "text": "d MMMM yyyy / HH:mm:ss", "date": "d MMMM yyyy", "time": "HH:mm:ss" },
                { "text": "dd/MM/yyyy / HH:mm", "date": "dd/MM/yyyy", "time": "HH:mm" },
                { "text": "MM/dd/yyyy / h:mm AP", "date": "MM/dd/yyyy", "time": "h:mm AP" },
                { "text": "yyyy-MM-dd / HH:mm", "date": "yyyy-MM-dd", "time": "HH:mm" },
                { "text": "MMMM d, yyyy / h:mm AP", "date": "MMMM d, yyyy", "time": "h:mm AP" },
                { "text": "d. MMMM yyyy / HH:mm", "date": "d. MMMM yyyy", "time": "HH:mm" },
                { "text": i18n("Custom"), "date": "custom", "time": "custom" }
            ]
            textRole: "text"
            Component.onCompleted: {
                if (!appearancePage) return;
                let d = appearancePage.cfg_date_format;
                let t = appearancePage.cfg_time_format;
                currentIndex = 0;
                for (let i = 0; i < model.length; i++) {
                    if (model[i].date === d && model[i].time === t) { currentIndex = i; break; }
                }
                if (currentIndex === 0 && (d !== model[0].date || t !== model[0].time)) currentIndex = model.length - 1;
            }
            onActivated: {
                let item = model[currentIndex];
                if (item.date !== "custom") {
                    appearancePage.cfg_date_format = item.date;
                    appearancePage.cfg_time_format = item.time;
                    for (let i = 0; i < localePresetCombo.model.length; i++) {
                        if (localePresetCombo.model[i].locale === "custom") { localePresetCombo.currentIndex = i; break; }
                    }
                }
            }
        }

        QQC2.TextField {
            id: localeField
            visible: dateFormatCombo.currentIndex === dateFormatCombo.model.length - 1
            Kirigami.FormData.label: i18n("Custom Locale:")
            Layout.fillWidth: true
            placeholderText: i18n("e.g. fr_BE, en_GB, nl_BE")
            text: appearancePage.cfg_locale
            onTextChanged: appearancePage.cfg_locale = text
        }

        QQC2.TextField {
            visible: dateFormatCombo.currentIndex === dateFormatCombo.model.length - 1
            Kirigami.FormData.label: i18n("Date Format:")
            Layout.fillWidth: true
            placeholderText: i18n("dd MMMM yyyy")
            text: appearancePage.cfg_date_format
            onTextChanged: appearancePage.cfg_date_format = text
        }

        QQC2.TextField {
            visible: dateFormatCombo.currentIndex === dateFormatCombo.model.length - 1
            Kirigami.FormData.label: i18n("Time Format:")
            Layout.fillWidth: true
            placeholderText: i18n("HH:mm:ss")
            text: appearancePage.cfg_time_format
            onTextChanged: appearancePage.cfg_time_format = text
        }

        QQC2.Button {
            text: i18n("Reset Global Settings")
            icon.name: "edit-undo"
            Layout.alignment: Qt.AlignRight
            onClicked: appearancePage.resetGlobal()
            QQC2.ToolTip.text: i18n("Restore global settings to defaults")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 800
        }

        // ================= SECTION: ELEMENT ORDER =================
        Kirigami.Heading {
            text: i18n("Element Order")
            level: 2
            Layout.fillWidth: true
            Kirigami.FormData.isSection: true
        }

        QQC2.Label {
            text: i18n("Use the arrows to reorder elements from top to bottom.")
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        // Hidden field for the alias
        QQC2.TextField {
            id: elementOrderField
            visible: false
        }

        // Hidden field for saved_themes KCM alias
        QQC2.TextField {
            id: _savedThemesStorage
            visible: false
            text: appearancePage.savedThemesJson
            onTextChanged: appearancePage.savedThemesJson = text
        }

        // Hidden fields for fontFamily KCM aliases
        QQC2.TextField { id: _fontFamilyDayStorage; visible: false; text: "Anurati" }
        QQC2.TextField { id: _fontFamilyDateStorage; visible: false; text: "Poppins" }
        QQC2.TextField { id: _fontFamilyTimeStorage; visible: false; text: "Poppins" }
        QQC2.TextField { id: _fontFamilyCustomStorage; visible: false; text: "Poppins" }
        QQC2.TextField { id: _fontFamilyTimezoneStorage; visible: false; text: "Poppins" }

        // Hidden field for timezone_format KCM alias
        QQC2.TextField { id: _timezoneFmtStorage; visible: false; text: "" }

        // Hidden field for color_mode KCM alias
        QQC2.TextField {
            id: _colorModeStorage
            visible: false
            text: appearancePage.cfg_color_mode
            onTextChanged: appearancePage.cfg_color_mode = text
        }

        // ===== ORDER SYSTEM (extracted to OrderSection.qml) =====
        OrderSection {
            id: orderSection
            Layout.fillWidth: true
            Layout.minimumHeight: 180
            elementOrder: appearancePage.cfg_element_order
            onOrderChanged: function(newOrder) {
                appearancePage.cfg_element_order = newOrder;
            }
        }

        // ================= SECTION: DAY =================
        Kirigami.Heading {
            text: i18n("Day")
            level: 2
            Layout.fillWidth: true
            Kirigami.FormData.isSection: true
        }

        QQC2.CheckBox {
            id: showDay
            text: i18n("Show day")
        }

        QQC2.ComboBox {
            id: dayFontCombo
            Kirigami.FormData.label: i18n("Font:")
            Layout.fillWidth: true
            model: appearancePage.systemFontList
            currentIndex: Math.max(0, model.indexOf(appearancePage.cfg_fontFamilyDay))
            editable: true
            onActivated: appearancePage.cfg_fontFamilyDay = model[currentIndex]
            onEditTextChanged: {
                if (editText !== undefined && model.indexOf(editText) !== -1) {
                    appearancePage.cfg_fontFamilyDay = editText;
                }
            }
        }

        QQC2.SpinBox {
            id: dayFontSize
            Kirigami.FormData.label: i18n("Font size:")
            from: 1
            to: 999
        }

        QQC2.SpinBox {
            id: dayLetterSpacing
            Kirigami.FormData.label: i18n("Letter spacing:")
            from: 0
            to: 999
        }

        QQC2.TextField {
            id: dayFormat
            Kirigami.FormData.label: i18n("Format:")
            Layout.fillWidth: true
            placeholderText: "dddd"
            QQC2.ToolTip.text: i18n("Use Qt date formats. For example: dddd = full weekday name, ddd = short weekday name.")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 800
        }

        QQC2.CheckBox {
            id: uppercaseDay
            text: i18n("Uppercase")
        }

        QQC2.CheckBox {
            id: dayFontBold
            text: i18n("Bold")
        }

        KQControls.ColorButton {
            id: dayFontColor
            Kirigami.FormData.label: i18n("Font color:")
            showAlphaChannel: false
        }

        QQC2.Button {
            text: i18n("Reset Day Settings")
            icon.name: "edit-undo"
            Layout.alignment: Qt.AlignRight
            onClicked: appearancePage.resetDay()
            QQC2.ToolTip.text: i18n("Restore day settings to defaults")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 800
        }

        // ================= SECTION: DATE =================
        Kirigami.Heading {
            text: i18n("Date")
            level: 2
            Layout.fillWidth: true
            Kirigami.FormData.isSection: true
        }

        QQC2.CheckBox {
            id: showDate
            text: i18n("Show date")
        }

        QQC2.ComboBox {
            id: dateFontCombo
            Kirigami.FormData.label: i18n("Font:")
            Layout.fillWidth: true
            model: appearancePage.systemFontList
            currentIndex: Math.max(0, model.indexOf(appearancePage.cfg_fontFamilyDate))
            editable: true
            onActivated: appearancePage.cfg_fontFamilyDate = model[currentIndex]
            onEditTextChanged: {
                if (editText !== undefined && model.indexOf(editText) !== -1) {
                    appearancePage.cfg_fontFamilyDate = editText;
                }
            }
        }

        QQC2.SpinBox {
            id: dateFontSize
            Kirigami.FormData.label: i18n("Font size:")
            from: 1
            to: 999
        }

        QQC2.SpinBox {
            id: dateLetterSpacing
            Kirigami.FormData.label: i18n("Letter spacing:")
            from: 0
            to: 999
        }

        QQC2.TextField {
            id: dateFormat
            Kirigami.FormData.label: i18n("Format:")
            Layout.fillWidth: true
            placeholderText: "dd MMM yyyy"
            QQC2.ToolTip.text: i18n("Use Qt date formats like dd MMM yyyy, MM/dd/yyyy, or dddd d MMMM yyyy.")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 800
        }

        QQC2.CheckBox {
            id: uppercaseDate
            text: i18n("Uppercase")
        }

        QQC2.CheckBox {
            id: dateFontBold
            text: i18n("Bold")
        }

        KQControls.ColorButton {
            id: dateFontColor
            Kirigami.FormData.label: i18n("Font color:")
            showAlphaChannel: false
        }

        QQC2.Button {
            text: i18n("Reset Date Settings")
            icon.name: "edit-undo"
            Layout.alignment: Qt.AlignRight
            onClicked: appearancePage.resetDate()
            QQC2.ToolTip.text: i18n("Restore date settings to defaults")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 800
        }

        // ================= SECTION: TIME =================
        Kirigami.Heading {
            text: i18n("Time")
            level: 2
            Layout.fillWidth: true
            Kirigami.FormData.isSection: true
        }

        QQC2.CheckBox {
            id: showTime
            text: i18n("Show time")
        }

        QQC2.ComboBox {
            id: timeFontCombo
            Kirigami.FormData.label: i18n("Font:")
            Layout.fillWidth: true
            model: appearancePage.systemFontList
            currentIndex: Math.max(0, model.indexOf(appearancePage.cfg_fontFamilyTime))
            editable: true
            onActivated: appearancePage.cfg_fontFamilyTime = model[currentIndex]
            onEditTextChanged: {
                if (editText !== undefined && model.indexOf(editText) !== -1) {
                    appearancePage.cfg_fontFamilyTime = editText;
                }
            }
        }

        QQC2.SpinBox {
            id: timeFontSize
            Kirigami.FormData.label: i18n("Font size:")
            from: 1
            to: 999
        }

        QQC2.SpinBox {
            id: timeLetterSpacing
            Kirigami.FormData.label: i18n("Letter spacing:")
            from: 0
            to: 999
        }

        QQC2.TextField {
            id: timeFormat
            Kirigami.FormData.label: i18n("Format:")
            Layout.fillWidth: true
            placeholderText: i18n("hh:mm")
            QQC2.ToolTip.text: i18n("Use Qt time formats like hh:mm, hh:mm:ss, or hh:mm AP. Leave empty to use the 12/24-hour setting.")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 800
        }

        QQC2.CheckBox {
            id: use24HourFormat
            text: i18n("Use 24-hour format")
        }

        QQC2.CheckBox {
            id: timeFontBold
            text: i18n("Bold")
        }

        KQControls.ColorButton {
            id: timeFontColor
            Kirigami.FormData.label: i18n("Font color:")
            showAlphaChannel: false
        }

        QQC2.TextField {
            id: timeCharacter
            Kirigami.FormData.label: i18n("Decoration character:")
            Layout.fillWidth: true
            placeholderText: "-"
            QQC2.ToolTip.text: i18n("A character displayed on both sides of the time. Leave empty to show no decoration.")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 800
        }

        QQC2.Button {
            text: i18n("Reset Time Settings")
            icon.name: "edit-undo"
            Layout.alignment: Qt.AlignRight
            onClicked: appearancePage.resetTime()
            QQC2.ToolTip.text: i18n("Restore time settings to defaults")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 800
        }

        // ================= SECTION: CUSTOM TEXT =================
        Kirigami.Heading {
            text: i18n("Custom Text")
            level: 2
            Layout.fillWidth: true
            Kirigami.FormData.isSection: true
        }

        QQC2.CheckBox {
            id: showCustom
            text: i18n("Show custom text")
        }

        QQC2.TextField {
            id: customTextField
            Kirigami.FormData.label: i18n("Text:")
            Layout.fillWidth: true
            placeholderText: i18n("e.g. Good Morning, or HH:mm for live time")
            QQC2.ToolTip.text: i18n("Static text, or a Qt date/time format (e.g. dddd, HH:mm, yyyy-MM-dd)")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 800
        }

        QQC2.CheckBox {
            id: customFormat
            text: i18n("Interpret as date/time format")
            QQC2.ToolTip.text: i18n("When enabled, Qt format tokens like dddd or HH:mm are replaced with the current date/time")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 800
        }

        QQC2.ComboBox {
            id: customFontCombo
            Kirigami.FormData.label: i18n("Font:")
            Layout.fillWidth: true
            model: appearancePage.systemFontList
            currentIndex: Math.max(0, model.indexOf(appearancePage.cfg_fontFamilyCustom))
            editable: true
            onActivated: appearancePage.cfg_fontFamilyCustom = model[currentIndex]
            onEditTextChanged: {
                if (editText !== undefined && model.indexOf(editText) !== -1) {
                    appearancePage.cfg_fontFamilyCustom = editText;
                }
            }
        }

        QQC2.SpinBox {
            id: customFontSize
            Kirigami.FormData.label: i18n("Font size:")
            from: 1
            to: 999
        }

        QQC2.SpinBox {
            id: customLetterSpacing
            Kirigami.FormData.label: i18n("Letter spacing:")
            from: 0
            to: 999
        }

        QQC2.CheckBox {
            id: customFontBold
            text: i18n("Bold")
        }

        KQControls.ColorButton {
            id: customFontColor
            Kirigami.FormData.label: i18n("Font color:")
            showAlphaChannel: false
        }

        QQC2.Button {
            text: i18n("Reset Custom Text Settings")
            icon.name: "edit-undo"
            Layout.alignment: Qt.AlignRight
            onClicked: appearancePage.resetCustom()
            QQC2.ToolTip.text: i18n("Restore custom text settings to defaults")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 800
        }

        // ================= SECTION: TIMEZONE =================
        Kirigami.Heading {
            text: i18n("Secondary Timezone")
            level: 2
            Layout.fillWidth: true
            Kirigami.FormData.isSection: true
        }

        QQC2.CheckBox {
            id: showTimezone
            text: i18n("Show secondary timezone")
        }

        QQC2.ComboBox {
            id: timezoneIdField
            Kirigami.FormData.label: i18n("Timezone:")
            Layout.fillWidth: true
            editable: true
            model: ListModel {
                ListElement { text: "—"; value: "" }
                ListElement { text: "UTC+0:00 — London / Dublin / Lisbon"; value: "Europe/London" }
                ListElement { text: "UTC+1:00 — Paris / Berlin / Rome / Madrid"; value: "Europe/Paris" }
                ListElement { text: "UTC+1:00 — Amsterdam / Brussels / Zurich / Vienna"; value: "Europe/Amsterdam" }
                ListElement { text: "UTC+1:00 — Warsaw / Prague / Budapest"; value: "Europe/Warsaw" }
                ListElement { text: "UTC+2:00 — Athens / Helsinki / Bucharest"; value: "Europe/Athens" }
                ListElement { text: "UTC+2:00 — Istanbul"; value: "Europe/Istanbul" }
                ListElement { text: "UTC+3:00 — Moscow"; value: "Europe/Moscow" }
                ListElement { text: "UTC+3:00 — Riyadh / Kuwait / Baghdad"; value: "Asia/Riyadh" }
                ListElement { text: "UTC+3:30 — Tehran"; value: "Asia/Tehran" }
                ListElement { text: "UTC+4:00 — Dubai / Abu Dhabi"; value: "Asia/Dubai" }
                ListElement { text: "UTC+4:30 — Kabul"; value: "Asia/Kabul" }
                ListElement { text: "UTC+5:00 — Karachi / Lahore"; value: "Asia/Karachi" }
                ListElement { text: "UTC+5:30 — Mumbai / Delhi / Kolkata"; value: "Asia/Kolkata" }
                ListElement { text: "UTC+5:45 — Kathmandu"; value: "Asia/Kathmandu" }
                ListElement { text: "UTC+6:00 — Dhaka / Almaty"; value: "Asia/Dhaka" }
                ListElement { text: "UTC+6:30 — Yangon"; value: "Asia/Yangon" }
                ListElement { text: "UTC+7:00 — Bangkok / Ho Chi Minh / Jakarta"; value: "Asia/Bangkok" }
                ListElement { text: "UTC+8:00 — Shanghai / Beijing"; value: "Asia/Shanghai" }
                ListElement { text: "UTC+8:00 — Hong Kong / Singapore"; value: "Asia/Hong_Kong" }
                ListElement { text: "UTC+8:00 — Perth / Taipei"; value: "Asia/Perth" }
                ListElement { text: "UTC+9:00 — Tokyo / Seoul"; value: "Asia/Tokyo" }
                ListElement { text: "UTC+9:30 — Adelaide"; value: "Australia/Adelaide" }
                ListElement { text: "UTC+10:00 — Sydney / Melbourne"; value: "Australia/Sydney" }
                ListElement { text: "UTC+10:00 — Brisbane / Guam"; value: "Australia/Brisbane" }
                ListElement { text: "UTC+12:00 — Auckland / Wellington"; value: "Pacific/Auckland" }
                ListElement { text: "UTC+12:00 — Fiji"; value: "Pacific/Fiji" }
                ListElement { text: "UTC-5:00 — New York / Toronto / Montreal"; value: "America/New_York" }
                ListElement { text: "UTC-6:00 — Chicago / Mexico City"; value: "America/Chicago" }
                ListElement { text: "UTC-7:00 — Denver / Phoenix"; value: "America/Denver" }
                ListElement { text: "UTC-8:00 — Los Angeles / Vancouver"; value: "America/Los_Angeles" }
                ListElement { text: "UTC-9:00 — Anchorage"; value: "America/Anchorage" }
                ListElement { text: "UTC-10:00 — Honolulu"; value: "Pacific/Honolulu" }
                ListElement { text: "UTC-3:00 — São Paulo / Buenos Aires"; value: "America/Sao_Paulo" }
                ListElement { text: "UTC-3:30 — St. John's"; value: "America/St_Johns" }
                ListElement { text: "UTC-4:00 — Halifax"; value: "America/Halifax" }
            }
            textRole: "text"
            valueRole: "value"
            onActivated: {
                var v = model.get(currentIndex).value;
                appearancePage.cfg_timezone_id = v;
                appearancePage.cfg_timezone_display_text = (currentIndex >= 0 && currentIndex < model.count)
                    ? model.get(currentIndex).text : "";
            }
            onEditTextChanged: {
                if (editText !== undefined && editText.length > 0 && editText !== "—") {
                    var matched = false;
                    for (var i = 0; i < model.count; i++) {
                        if (model.get(i).text === editText) {
                            appearancePage.cfg_timezone_id = model.get(i).value;
                            appearancePage.cfg_timezone_display_text = editText;
                            matched = true;
                            break;
                        }
                    }
                    if (!matched) {
                        for (var i = 0; i < model.count; i++) {
                            if (model.get(i).value === editText) {
                                appearancePage.cfg_timezone_id = editText;
                                matched = true;
                                break;
                            }
                        }
                    }
                    if (!matched) {
                        appearancePage.cfg_timezone_id = editText;
                    }
                }
            }
            Component.onCompleted: {
                Qt.callLater(function() {
                    var d = appearancePage.cfg_timezone_display_text || "";
                    if (d.length > 0) {
                        for (var i = 0; i < timezoneIdField.model.count; i++) {
                            if (timezoneIdField.model.get(i).text === d) {
                                timezoneIdField.currentIndex = i;
                                return;
                            }
                        }
                    }
                    var id = appearancePage.cfg_timezone_id || "";
                    if (id.length > 0) {
                        for (var i = 0; i < timezoneIdField.model.count; i++) {
                            if (timezoneIdField.model.get(i).value === id) {
                                timezoneIdField.currentIndex = i;
                                return;
                            }
                        }
                        timezoneIdField.editText = id;
                    }
                });
            }
            QQC2.ToolTip.text: i18n("Select a timezone or type a custom IANA ID")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 800
        }

        QQC2.TextField {
            id: timezoneLabel
            Kirigami.FormData.label: i18n("Label:")
            Layout.fillWidth: true
            placeholderText: i18n("e.g. NYC, Tokyo")
            QQC2.ToolTip.text: i18n("Short label displayed before the timezone time. Leave empty for no label.")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 800
        }

        // Timezone format is now automatically derived from main time format (no seconds)
        // Hidden field to keep config key alive for backward compatibility
        QQC2.TextField {
            id: timezoneFmt
            visible: false
            text: ""
        }

        QQC2.ComboBox {
            id: timezoneFontCombo
            Kirigami.FormData.label: i18n("Font:")
            Layout.fillWidth: true
            model: appearancePage.systemFontList
            currentIndex: Math.max(0, model.indexOf(appearancePage.cfg_fontFamilyTimezone))
            editable: true
            onActivated: appearancePage.cfg_fontFamilyTimezone = model[currentIndex]
            onEditTextChanged: {
                if (editText !== undefined && model.indexOf(editText) !== -1) {
                    appearancePage.cfg_fontFamilyTimezone = editText;
                }
            }
        }

        QQC2.SpinBox {
            id: timezoneFontSize
            Kirigami.FormData.label: i18n("Font size:")
            from: 1
            to: 999
        }

        QQC2.SpinBox {
            id: timezoneLetterSpacing
            Kirigami.FormData.label: i18n("Letter spacing:")
            from: 0
            to: 999
        }

        QQC2.CheckBox {
            id: timezoneFontBold
            text: i18n("Bold")
        }

        KQControls.ColorButton {
            id: timezoneFontColor
            Kirigami.FormData.label: i18n("Font color:")
            showAlphaChannel: false
        }

        QQC2.Button {
            text: i18n("Reset Timezone Settings")
            icon.name: "edit-undo"
            Layout.alignment: Qt.AlignRight
            onClicked: appearancePage.resetTimezone()
            QQC2.ToolTip.text: i18n("Restore timezone settings to defaults")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 800
        }

        // ================= SECTION: THEMES =================
        Kirigami.Heading {
            text: i18n("Themes")
            level: 2
            Layout.fillWidth: true
            Kirigami.FormData.isSection: true
        }

        QQC2.Button {
            text: i18n("Save Current Theme")
            icon.name: "document-save"
            onClicked: themeSheets.openSave()
        }

        Repeater {
            model: appearancePage.savedThemes
            delegate: RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.fillWidth: true
                    QQC2.Label {
                        text: modelData.name || i18n("Untitled")
                        font.bold: true
                    }
                    QQC2.Label {
                        text: modelData.description || ""
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.7
                        visible: text.length > 0
                    }
                }

                QQC2.Button {
                    icon.name: "document-open"
                    onClicked: appearancePage.loadThemeConfig(index)
                    QQC2.ToolTip.text: i18n("Load this theme")
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: 800
                }

                QQC2.Button {
                    icon.name: "document-export"
                    onClicked: themeSheets.openExport(index)
                    QQC2.ToolTip.text: i18n("Export this theme")
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: 800
                }

                QQC2.Button {
                    icon.name: "edit-delete"
                    onClicked: appearancePage.deleteTheme(index)
                    QQC2.ToolTip.text: i18n("Delete this theme")
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: 800
                }
            }
        }

        QQC2.Label {
            text: i18n("No saved themes yet.")
            visible: appearancePage.savedThemes.length === 0
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.Button {
                text: i18n("Import Theme")
                icon.name: "document-import"
                onClicked: themeSheets.openImport()
            }

            QQC2.Button {
                text: i18n("Advanced: Raw JSON")
                icon.name: "text-x-generic"
                onClicked: themeSheets.openRawJson()
            }
        }
    }
    }

    // ===== Theme Sheets =====
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
