import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Window

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
    property alias cfg_timezone_id: _timezoneIdStorage.text
    property alias cfg_timezone_label: timezoneLabel.text
    property alias cfg_timezone_display_text: _timezoneDisplayStorage.text
    // Timezone format is now automatically derived from main time format (no seconds)
    // Kept as empty string; the real format is computed in main.qml timezoneFormat()
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

    function _previewResolvedColor(cfgColor) {
        var mode = appearancePage.cfg_color_mode || "custom";
        if (mode === "theme") return appearancePage.systemTextColor;
        if (mode === "theme_inverse") return appearancePage.systemBgColor;
        if (mode === "wallpaper") {
            try {
                var path = ModernRecClock.Wallpaper.wallpaperPath();
                if (path && path.length > 0) {
                    var brightness = ModernRecClock.Wallpaper.wallpaperBrightness(path);
                    log.debug("wallpaper", "Preview wallpaper brightness: " + brightness + " for " + path);
                    return brightness === "light" ? "#000000" : "#FFFFFF";
                }
            } catch (e) {
                log.warn("wallpaper", "Preview wallpaper color resolution failed: " + e.message);
            }
            return appearancePage.systemTextColor;
        }
        return cfgColor;
    }

    // Scale factor for preview — updated by updatePreview()
    // 1.0 = use configured font sizes as-is; auto_scale reduces if text overflows
    property real _previewScale: 1.0

    // ===== WALLPAPER PREVIEW =====
    function _loadPreviewWallpaper() {
        if (previewWallpaperImage)
            previewWallpaperImage.source = "image://modernreclock/wallpaper";
        log.info("wallpaper", "Preview wallpaper source set to image://modernreclock/wallpaper");
    }

    // ===== Live preview =====
    property string previewDayText: ""
    property string previewDateText: ""
    property string previewTimeText: ""
    property string previewCustomText: ""
    property string previewTimezoneText: ""
    // Reuses the same parsing logic as main.qml elementOrderArray
    readonly property var validElements: ["day", "date", "time", "custom", "timezone"]
    property var previewOrderArray: {
        if (!cfg_element_order) return validElements.slice();
        var arr = cfg_element_order.split(",").map(function(x) { return x.trim(); }).filter(function(x) {
            return validElements.indexOf(x) !== -1;
        });
        return arr.length > 0 ? arr : validElements.slice();
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
        updatePreview();
        _loadPreviewWallpaper();
        log.info("config", "Config page opened — " + keys.length + " config keys discovered");
        log.info("config", "color_mode=" + cfg_color_mode + " locale=" + (cfg_locale || "(default)") + " auto_scale=" + cfg_auto_scale);
    }

    function getFullConfig() {
        let cfg = {};
        configKeys.forEach(k => cfg[k] = appearancePage["cfg_" + k]);
        return JSON.stringify(cfg, null, 4);
    }

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
            log.info("config", "applyConfig: applied " + count + " keys from JSON");
            return true;
        } catch (e) {
            log.error("config", "applyConfig failed: " + e.message);
            return false;
        }
    }

    // ===== PREVIEW FUNCTIONS =====
    function previewEffectiveLocale() {
        let custom = cfg_locale ? cfg_locale.trim() : "";
        custom = custom.replace(/-/g, "_");
        return custom.length > 0 ? Qt.locale(custom) : Qt.locale();
    }

    function previewFormatDate(format) {
        try {
            let fmt = format && format.trim().length > 0 ? format.trim() : "dd MMM yyyy";
            return new Date().toLocaleDateString(previewEffectiveLocale(), fmt);
        } catch (e) {
            console.warn("Modern reClock: preview date format failed for", format, "-", e.message);
            return Qt.formatDate(new Date(), "dd MMM yyyy");
        }
    }

    function previewFormatTime() {
        let format = cfg_time_format ? cfg_time_format.trim() : "";
        if (format.length === 0) {
            format = cfg_use_24_hour_format ? "hh:mm" : "hh:mm AP";
        }
        try {
            let result = new Date().toLocaleTimeString(previewEffectiveLocale(), format);
            if (result && result.trim() !== "")
                return result;
        } catch (e) {
            console.warn("Modern reClock: preview time format failed for", format, "-", e.message);
        }
        let fallback = cfg_use_24_hour_format ? "hh:mm" : "hh:mm AP";
        try {
            return new Date().toLocaleTimeString(previewEffectiveLocale(), fallback);
        } catch (e) {
            console.warn("Modern reClock: preview fallback time format failed -", e.message);
            return Qt.formatTime(new Date(), fallback);
        }
    }



    function updatePreview() {
        let dayFmt = cfg_day_format && cfg_day_format.trim().length > 0 ? cfg_day_format.trim() : "dddd";
        let day = previewFormatDate(dayFmt);
        previewDayText = cfg_uppercase_day ? day.toUpperCase() : day;

        let date = previewFormatDate(cfg_date_format);
        previewDateText = cfg_uppercase_date ? date.toUpperCase() : date;

        let time = previewFormatTime();
        let deco = cfg_time_character || "";
        previewTimeText = deco.trim().length > 0 ? deco + " " + time + " " + deco : time;

        // Custom text preview
        var customTxt = cfg_custom_text || "";
        if (customTxt.length > 0 && cfg_custom_format) {
            try {
                var formatted = Qt.formatDateTime(new Date(), customTxt);
                previewCustomText = formatted && formatted.length > 0 ? formatted : customTxt;
            } catch (e) {
                previewCustomText = customTxt;
            }
        } else {
            previewCustomText = customTxt;
        }

        // Timezone preview — format derived from main time format (no seconds)
        var tzId = appearancePage.cfg_timezone_id || "";
        var tzLabel = cfg_timezone_label || "";
        if (tzId.length > 0) {
            try {
                // Derive format from main time format, strip seconds
                var mainFmt = cfg_time_format ? cfg_time_format.trim() : "";
                if (mainFmt.length === 0) {
                    mainFmt = cfg_use_24_hour_format ? "hh:mm" : "hh:mm AP";
                }
                var tzFmt = mainFmt.replace(/s{1,3}/g, '').replace(/z{1,3}/g, '').replace(/[:\s.]+$/, '');
                if (!tzFmt || tzFmt.trim().length === 0) tzFmt = "HH:mm";

                var formatted = ModernRecClock.TimeZone.formatDateTimeInZone(new Date(), tzFmt, tzId);
                if (formatted && formatted.length > 0) {
                    previewTimezoneText = tzLabel.length > 0 ? tzLabel + " " + formatted : formatted;
                } else {
                    previewTimezoneText = tzLabel.length > 0 ? tzLabel + " ??" : "??";
                }
            } catch (e) {
                previewTimezoneText = tzLabel.length > 0 ? tzLabel + " ??" : "??";
            }
        } else {
            previewTimezoneText = "";
        }

        // Preview scale based on width relative to reference 400px
        _previewScale = (previewFrame && previewFrame.width > 0) ? previewFrame.width / 400 : 1.0;
        if (cfg_auto_scale && previewFrame && previewFrame.width > 0) {
            var pw = previewFrame.width;
            var previewH = pw * 9 / 16;
            var margin = Kirigami.Units.largeSpacing * 2;
            var availableH = Math.max(1, previewH - margin);
            var totalH = 0;
            var eCount = 0;
            for (var i = 0; i < previewOrderArray.length; i++) {
                var el = previewOrderArray[i];
                var show = false;
                if (el === "day") show = showDay.checked;
                else if (el === "date") show = showDate.checked;
                else if (el === "time") show = showTime.checked;
                else if (el === "custom") show = showCustom.checked && previewCustomText.length > 0;
                else if (el === "timezone") show = showTimezone.checked && previewTimezoneText.length > 0;
                if (!show) continue;
                eCount++;
                var size = (el === "day") ? 28 : 16;
                totalH += size * _previewScale;
            }
            if (eCount > 0) totalH += (eCount - 1) * widgetSpacing.value * _previewScale;
            if (totalH > 0) {
                var fitScale = availableH / totalH;
                _previewScale = Math.max(0.3, Math.min(_previewScale, fitScale));
            }
        }
    }

    Timer {
        id: previewTimer
        interval: 1000
        repeat: true
        running: true
        // Note: mirrors main.qml timer but always runs at 1s for preview responsiveness
        onTriggered: appearancePage.updatePreview()
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
            _timezoneIdStorage.text = d.id || "";
            _timezoneDisplayStorage.text = "";
            // Select matching preset in ComboBox or set custom text
            var tzVal = d.id || "";
            var found = false;
            for (var j = 0; j < timezoneIdField.model.count; j++) {
                if (timezoneIdField.model.get(j).value === tzVal) {
                    timezoneIdField.currentIndex = j;
                    timezoneIdField.editText = timezoneIdField.model.get(j).text;
                    _timezoneDisplayStorage.text = timezoneIdField.model.get(j).text;
                    found = true;
                    break;
                }
            }
            if (!found && tzVal.length > 0) {
                timezoneIdField.editText = tzVal;
                _timezoneDisplayStorage.text = tzVal;
            } else if (!found) {
                timezoneIdField.currentIndex = 0;
            }
            timezoneLabel.text = d.label || "";
            timezoneFmt.text = "";
            timezoneFontBold.checked = d.bold;
            timezoneFontColor.color = d.color;
        }
        updatePreview();
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
        updatePreview();
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
        updatePreview();
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



    Kirigami.FormLayout {
        // anchors.fill: parent removed to avoid layout loops in SimpleKCM

        // ================= SECTION: LIVE PREVIEW =================
        Kirigami.Heading {
            text: i18n("Preview")
            level: 2
            Layout.fillWidth: true
            Kirigami.FormData.isSection: true
        }

        Rectangle {
            id: previewFrame
            Layout.fillWidth: true
            implicitHeight: Math.max(width * 9 / 16, previewContent.implicitHeight + Kirigami.Units.largeSpacing * 2)
            Layout.topMargin: Kirigami.Units.largeSpacing
            color: Qt.rgba(0, 0, 0, 0.6)
            radius: Kirigami.Units.cornerRadius
            clip: true
            onWidthChanged: updatePreview()

            Image {
                id: previewWallpaperImage
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                source: ""
                onStatusChanged: {
                    if (status === Image.Ready)
                        log.info("wallpaper", "Preview wallpaper loaded");
                    else if (status === Image.Error)
                        log.warn("wallpaper", "Preview wallpaper error: " + errorString);
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.3)
            }

            Column {
                id: previewContent
                anchors.top: parent.top
                anchors.topMargin: Kirigami.Units.largeSpacing
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: widgetSpacing.value * appearancePage._previewScale

                Repeater {
                    model: appearancePage.previewOrderArray
                    Text {
                        visible: {
                            if (modelData === "day") return showDay.checked;
                            if (modelData === "date") return showDate.checked;
                            if (modelData === "time") return showTime.checked;
                            if (modelData === "custom") return showCustom.checked && appearancePage.previewCustomText.length > 0;
                            if (modelData === "timezone") return showTimezone.checked && appearancePage.previewTimezoneText.length > 0;
                            return false;
                        }
                        text: {
                            if (modelData === "day") return appearancePage.previewDayText;
                            if (modelData === "date") return appearancePage.previewDateText;
                            if (modelData === "time") return appearancePage.previewTimeText;
                            if (modelData === "custom") return appearancePage.previewCustomText;
                            if (modelData === "timezone") return appearancePage.previewTimezoneText;
                            return "";
                        }
                        font.family: {
                            if (modelData === "day") return appearancePage.cfg_fontFamilyDay;
                            if (modelData === "date") return appearancePage.cfg_fontFamilyDate;
                            if (modelData === "time") return appearancePage.cfg_fontFamilyTime;
                            if (modelData === "custom") return appearancePage.cfg_fontFamilyCustom;
                            if (modelData === "timezone") return appearancePage.cfg_fontFamilyTimezone;
                            return "";
                        }
                        font.pixelSize: {
                            var ps = appearancePage._previewScale;
                            if (modelData === "day") return Math.round(28 * ps);
                            if (modelData === "date") return Math.round(16 * ps);
                            if (modelData === "time") return Math.round(16 * ps);
                            if (modelData === "custom") return Math.round(16 * ps);
                            if (modelData === "timezone") return Math.round(16 * ps);
                            return 1;
                        }
                        font.letterSpacing: {
                            var s = appearancePage._previewScale;
                            if (modelData === "day") return dayLetterSpacing.value * s;
                            if (modelData === "date") return dateLetterSpacing.value * s;
                            if (modelData === "time") return timeLetterSpacing.value * s;
                            if (modelData === "custom") return customLetterSpacing.value * s;
                            if (modelData === "timezone") return timezoneLetterSpacing.value * s;
                            return 0;
                        }
                        font.bold: {
                            if (modelData === "day") return dayFontBold.checked;
                            if (modelData === "date") return dateFontBold.checked;
                            if (modelData === "time") return timeFontBold.checked;
                            if (modelData === "custom") return customFontBold.checked;
                            if (modelData === "timezone") return timezoneFontBold.checked;
                            return false;
                        }
                        color: {
                            if (modelData === "day") return appearancePage._previewResolvedColor(dayFontColor.color);
                            if (modelData === "date") return appearancePage._previewResolvedColor(dateFontColor.color);
                            if (modelData === "time") return appearancePage._previewResolvedColor(timeFontColor.color);
                            if (modelData === "custom") return appearancePage._previewResolvedColor(customFontColor.color);
                            if (modelData === "timezone") return appearancePage._previewResolvedColor(timezoneFontColor.color);
                            return "#FFFFFF";
                        }
                        anchors.horizontalCenter: parent.horizontalCenter
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }

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
                appearancePage.updatePreview();
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

        QQC2.ComboBox {
            id: languageCombo
            Kirigami.FormData.label: i18n("Language Preset:")
            Layout.fillWidth: true
            model: [
                {
                    "text": i18n("System Default"),
                    "locale": "",
                    "day": "dddd",
                    "date": "dd MMM yyyy",
                    "time": "",
                    "h24": true
                },
                {
                    "text": i18n("French"),
                    "locale": "fr_FR",
                    "day": "dddd",
                    "date": "d MMMM yyyy",
                    "time": "HH'h'mm",
                    "h24": true
                },
                {
                    "text": i18n("English (US)"),
                    "locale": "en_US",
                    "day": "dddd",
                    "date": "MMMM d, yyyy",
                    "time": "h:mm AP",
                    "h24": false
                },
                {
                    "text": i18n("English (UK)"),
                    "locale": "en_GB",
                    "day": "dddd",
                    "date": "d MMMM yyyy",
                    "time": "HH:mm",
                    "h24": true
                },
                {
                    "text": i18n("German"),
                    "locale": "de_DE",
                    "day": "dddd",
                    "date": "d. MMMM yyyy",
                    "time": "HH:mm",
                    "h24": true
                },
                {
                    "text": i18n("Spanish"),
                    "locale": "es_ES",
                    "day": "dddd",
                    "date": "d 'de' MMMM 'de' yyyy",
                    "time": "HH:mm",
                    "h24": true
                },
                {
                    "text": i18n("Italian"),
                    "locale": "it_IT",
                    "day": "dddd",
                    "date": "d MMMM yyyy",
                    "time": "HH:mm",
                    "h24": true
                },
                {
                    "text": i18n("Dutch"),
                    "locale": "nl_NL",
                    "day": "dddd",
                    "date": "d MMMM yyyy",
                    "time": "HH:mm",
                    "h24": true
                },
                {
                    "text": i18n("Polish"),
                    "locale": "pl_PL",
                    "day": "dddd",
                    "date": "d MMMM yyyy",
                    "time": "HH:mm",
                    "h24": true
                },
                {
                    "text": i18n("Portuguese"),
                    "locale": "pt_PT",
                    "day": "dddd",
                    "date": "d MMMM yyyy",
                    "time": "HH:mm",
                    "h24": true
                },
                {
                    "text": i18n("Russian"),
                    "locale": "ru_RU",
                    "day": "dddd",
                    "date": "d MMMM yyyy",
                    "time": "HH:mm",
                    "h24": true
                },
                {
                    "text": i18n("Japanese"),
                    "locale": "ja_JP",
                    "day": "dddd",
                    "date": "yyyy年M月d日",
                    "time": "H:mm",
                    "h24": true
                },
                {
                    "text": i18n("Custom"),
                    "locale": "custom"
                }
            ]
            textRole: "text"

            Component.onCompleted: {
                if (!appearancePage)
                    return;
                let currentLocale = appearancePage.cfg_locale;
                let found = false;
                for (let i = 0; i < model.length; i++) {
                    if (model[i].locale === currentLocale) {
                        currentIndex = i;
                        found = true;
                        break;
                    }
                }
                if (!found && currentLocale !== "") {
                    currentIndex = model.length - 1; // Custom
                } else if (!found) {
                    currentIndex = 0; // Default
                }
            }

            onActivated: {
                let item = model[currentIndex];
                if (item.locale !== "custom") {
                    appearancePage.cfg_locale = item.locale;

                    // Predefine formats based on language
                    if (item.day !== undefined)
                        appearancePage.cfg_day_format = item.day;
                    if (item.date !== undefined)
                        appearancePage.cfg_date_format = item.date;
                    if (item.time !== undefined)
                        appearancePage.cfg_time_format = item.time;
                    if (item.h24 !== undefined)
                        appearancePage.cfg_use_24_hour_format = item.h24;
                }
            }
        }

        QQC2.TextField {
            id: localeField
            Kirigami.FormData.label: i18n("Custom Locale:")
            Layout.fillWidth: true
            visible: languageCombo.model && languageCombo.model.length > 0 && (languageCombo.model[languageCombo.currentIndex].locale === "custom")
            placeholderText: i18n("e.g. fr_BE, en_GB, nl_BE")
            QQC2.ToolTip.text: i18n("Locale used for weekday and month names. Leave empty to use the system locale.")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 800
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

        // Hidden field for timezone_id KCM alias (ComboBox writes here)
        QQC2.TextField {
            id: _timezoneIdStorage
            visible: false
            text: ""
        }

        // Hidden field for timezone display text (saved ComboBox display string)
        QQC2.TextField {
            id: _timezoneDisplayStorage
            visible: false
            text: ""
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
                _timezoneIdStorage.text = v;
                // Save display text so it restores on next open
                _timezoneDisplayStorage.text = (currentIndex >= 0 && currentIndex < model.count)
                    ? model.get(currentIndex).text : "";
            }
            onEditTextChanged: {
                // User typed a custom IANA ID not in the presets
                if (editText !== undefined && editText.length > 0) {
                    var found = false;
                    for (var i = 0; i < model.count; i++) {
                        if (model.get(i).value === editText) {
                            found = true;
                            break;
                        }
                    }
                    if (!found) {
                        _timezoneIdStorage.text = editText;
                    }
                }
            }
            Component.onCompleted: {
                // Restore saved display text directly from config
                var savedDisplay = appearancePage.cfg_timezone_display_text || "";
                if (savedDisplay.length > 0) {
                    editText = savedDisplay;
                } else {
                    // Fallback: match IANA ID against model
                    var currentVal = appearancePage.cfg_timezone_id || "";
                    for (var i = 0; i < model.count; i++) {
                        if (model.get(i).value === currentVal) {
                            currentIndex = i;
                            return;
                        }
                    }
                    if (currentVal.length > 0) {
                        editText = currentVal;
                    }
                }
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

    // ===== Theme Sheets (extracted to ThemeSheets.qml) =====
    ThemeSheets {
        id: themeSheets
        getFullConfig: appearancePage.getFullConfig
        applyConfig: appearancePage.applyConfig
        updatePreview: appearancePage.updatePreview
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
