import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQControls

KCM.SimpleKCM {
    id: appearancePage

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

    property string cfg_fontFamilyDay
    property string cfg_fontFamilyDate
    property string cfg_fontFamilyTime

    property alias cfg_widget_spacing: widgetSpacing.value

    property alias cfg_locale: localeField.text
    property alias cfg_auto_scale: autoScale.checked

    property alias cfg_element_order: elementOrderField.text

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
    property string savedThemesJson: plasmoid.configuration.saved_themes || "[]"
    property var savedThemes: {
        try { return JSON.parse(savedThemesJson); }
        catch (e) { return []; }
    }

    // ===== Live preview =====
    property string previewDayText: ""
    property string previewDateText: ""
    property string previewTimeText: ""
    property var previewOrderArray: cfg_element_order ? cfg_element_order.split(",") : ["day", "date", "time"]

    readonly property var configKeys: ["day_font_size", "day_letter_spacing", "show_day", "date_font_size", "date_letter_spacing", "locale", "date_format", "show_date", "time_font_size", "time_letter_spacing", "time_format", "time_font_color", "show_time", "date_font_color", "day_font_color", "use_24_hour_format", "time_character", "widget_spacing", "day_format", "uppercase_day", "uppercase_date", "day_font_bold", "date_font_bold", "time_font_bold", "auto_scale", "fontFamilyDay", "fontFamilyDate", "fontFamilyTime", "element_order", "saved_themes"]

    function getFullConfig() {
        if (typeof (plasmoid) === "undefined" || !plasmoid || !plasmoid.configuration)
            return "{}";
        let cfg = {};
        configKeys.forEach(k => cfg[k] = plasmoid.configuration[k]);
        return JSON.stringify(cfg, null, 4);
    }

    function applyConfig(jsonString) {
        if (typeof (plasmoid) === "undefined" || !plasmoid || !plasmoid.configuration)
            return false;
        try {
            let cfg = JSON.parse(jsonString);
            for (let k in cfg) {
                if (configKeys.indexOf(k) !== -1) {
                    plasmoid.configuration[k] = cfg[k];
                }
            }
            return true;
        } catch (e) {
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
        } catch (e) {}
        let fallback = cfg_use_24_hour_format ? "hh:mm" : "hh:mm AP";
        try {
            return new Date().toLocaleTimeString(previewEffectiveLocale(), fallback);
        } catch (e) {
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

        previewOrderArray = cfg_element_order ? cfg_element_order.split(",") : ["day", "date", "time"];
    }

    Timer {
        id: previewTimer
        interval: 1000
        repeat: true
        running: true
        onTriggered: appearancePage.updatePreview()
    }

    // ===== RESET FUNCTIONS =====
    function resetGlobal() {
        autoScale.checked = false;
        widgetSpacing.value = 5;
        localeField.text = "";
        elementOrderField.text = "day,date,time";
        orderListModel.clear();
        orderListModel.append({ "key": "day", "label": i18n("Day") });
        orderListModel.append({ "key": "date", "label": i18n("Date") });
        orderListModel.append({ "key": "time", "label": i18n("Time") });
        languageCombo.currentIndex = 0;
        updatePreview();
    }

    function resetDay() {
        showDay.checked = true;
        cfg_fontFamilyDay = "Anurati";
        dayFontCombo.currentIndex = Math.max(0, dayFontCombo.model.indexOf("Anurati"));
        dayFontSize.value = 72;
        dayLetterSpacing.value = 17;
        dayFormat.text = "dddd";
        uppercaseDay.checked = true;
        dayFontBold.checked = false;
        dayFontColor.color = "#FFFFFF";
        updatePreview();
    }

    function resetDate() {
        showDate.checked = true;
        cfg_fontFamilyDate = "Poppins";
        dateFontCombo.currentIndex = Math.max(0, dateFontCombo.model.indexOf("Poppins"));
        dateFontSize.value = 19;
        dateLetterSpacing.value = 3;
        dateFormat.text = "dd MMM yyyy";
        uppercaseDate.checked = true;
        dateFontBold.checked = false;
        dateFontColor.color = "#FFFFFF";
        updatePreview();
    }

    function resetTime() {
        showTime.checked = true;
        cfg_fontFamilyTime = "Poppins";
        timeFontCombo.currentIndex = Math.max(0, timeFontCombo.model.indexOf("Poppins"));
        timeFontSize.value = 19;
        timeLetterSpacing.value = 3;
        timeFormat.text = "";
        use24HourFormat.checked = false;
        timeCharacter.text = "-";
        timeFontBold.checked = false;
        timeFontColor.color = "#FFFFFF";
        updatePreview();
    }

    // ===== THEME FUNCTIONS =====
    function saveCurrentTheme(name, description) {
        let cfg = {};
        configKeys.forEach(k => cfg[k] = plasmoid.configuration[k]);
        let themes = savedThemes.slice();
        themes.push({ "name": name, "description": description, "config": cfg });
        savedThemesJson = JSON.stringify(themes);
        plasmoid.configuration.saved_themes = savedThemesJson;
    }

    function loadThemeConfig(index) {
        if (index < 0 || index >= savedThemes.length)
            return;
        let theme = savedThemes[index];
        applyConfig(JSON.stringify(theme.config));
        updatePreview();
    }

    function deleteTheme(index) {
        if (index < 0 || index >= savedThemes.length)
            return;
        let themes = savedThemes.slice();
        themes.splice(index, 1);
        savedThemesJson = JSON.stringify(themes);
        plasmoid.configuration.saved_themes = savedThemesJson;
    }

    function themeToJSON(index) {
        if (index < 0 || index >= savedThemes.length)
            return "";
        return JSON.stringify(savedThemes[index], null, 4);
    }

    Component.onCompleted: updatePreview()

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
            Layout.fillWidth: true
            Layout.preferredHeight: previewContent.implicitHeight + Kirigami.Units.largeSpacing * 2
            Layout.minimumHeight: 60
            Layout.topMargin: Kirigami.Units.largeSpacing
            color: Qt.rgba(0, 0, 0, 0.6)
            radius: Kirigami.Units.cornerRadius
            clip: false

            Column {
                id: previewContent
                anchors.top: parent.top
                anchors.topMargin: Kirigami.Units.largeSpacing
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: widgetSpacing.value

                Repeater {
                    model: appearancePage.previewOrderArray
                    Text {
                        visible: {
                            if (modelData === "day") return showDay.checked;
                            if (modelData === "date") return showDate.checked;
                            if (modelData === "time") return showTime.checked;
                            return false;
                        }
                        text: {
                            if (modelData === "day") return appearancePage.previewDayText;
                            if (modelData === "date") return appearancePage.previewDateText;
                            if (modelData === "time") return appearancePage.previewTimeText;
                            return "";
                        }
                        font.family: {
                            if (modelData === "day") return appearancePage.cfg_fontFamilyDay;
                            if (modelData === "date") return appearancePage.cfg_fontFamilyDate;
                            if (modelData === "time") return appearancePage.cfg_fontFamilyTime;
                            return "";
                        }
                        font.pixelSize: {
                            if (modelData === "day") return Math.min(dayFontSize.value, 36);
                            if (modelData === "date") return Math.min(dateFontSize.value, 20);
                            if (modelData === "time") return Math.min(timeFontSize.value, 20);
                            return 1;
                        }
                        font.letterSpacing: {
                            if (modelData === "day") return dayLetterSpacing.value;
                            if (modelData === "date") return dateLetterSpacing.value;
                            if (modelData === "time") return timeLetterSpacing.value;
                            return 0;
                        }
                        font.bold: {
                            if (modelData === "day") return dayFontBold.checked;
                            if (modelData === "date") return dateFontBold.checked;
                            if (modelData === "time") return timeFontBold.checked;
                            return false;
                        }
                        color: {
                            if (modelData === "day") return dayFontColor.color;
                            if (modelData === "date") return dateFontColor.color;
                            if (modelData === "time") return timeFontColor.color;
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
                    "text": "Français",
                    "locale": "fr_FR",
                    "day": "dddd",
                    "date": "d MMMM yyyy",
                    "time": "HH'h'mm",
                    "h24": true
                },
                {
                    "text": "English (US)",
                    "locale": "en_US",
                    "day": "dddd",
                    "date": "MMMM d, yyyy",
                    "time": "h:mm AP",
                    "h24": false
                },
                {
                    "text": "English (UK)",
                    "locale": "en_GB",
                    "day": "dddd",
                    "date": "d MMMM yyyy",
                    "time": "HH:mm",
                    "h24": true
                },
                {
                    "text": "Deutsch",
                    "locale": "de_DE",
                    "day": "dddd",
                    "date": "d. MMMM yyyy",
                    "time": "HH:mm",
                    "h24": true
                },
                {
                    "text": "Español",
                    "locale": "es_ES",
                    "day": "dddd",
                    "date": "d 'de' MMMM 'de' yyyy",
                    "time": "HH:mm",
                    "h24": true
                },
                {
                    "text": "Italiano",
                    "locale": "it_IT",
                    "day": "dddd",
                    "date": "d MMMM yyyy",
                    "time": "HH:mm",
                    "h24": true
                },
                {
                    "text": "Nederlands",
                    "locale": "nl_NL",
                    "day": "dddd",
                    "date": "d MMMM yyyy",
                    "time": "HH:mm",
                    "h24": true
                },
                {
                    "text": "Polski",
                    "locale": "pl_PL",
                    "day": "dddd",
                    "date": "d MMMM yyyy",
                    "time": "HH:mm",
                    "h24": true
                },
                {
                    "text": "Português",
                    "locale": "pt_PT",
                    "day": "dddd",
                    "date": "d MMMM yyyy",
                    "time": "HH:mm",
                    "h24": true
                },
                {
                    "text": "Русский",
                    "locale": "ru_RU",
                    "day": "dddd",
                    "date": "d MMMM yyyy",
                    "time": "HH:mm",
                    "h24": true
                },
                {
                    "text": "日本語",
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
                if (typeof (plasmoid) === "undefined" || !plasmoid || !plasmoid.configuration)
                    return;
                let currentLocale = plasmoid.configuration.locale;
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

        ListModel {
            id: orderListModel
        }

        Component.onCompleted: {
            // Initialize the order list model from config
            let order = appearancePage.cfg_element_order
                ? appearancePage.cfg_element_order.split(",")
                : ["day", "date", "time"];
            for (let i = 0; i < order.length; i++) {
                let label = order[i] === "day" ? i18n("Day")
                    : order[i] === "date" ? i18n("Date")
                    : order[i] === "time" ? i18n("Time")
                    : order[i];
                orderListModel.append({ "key": order[i], "label": label });
            }
        }

        function moveOrderItem(from, to) {
            let item = orderListModel.get(from);
            orderListModel.remove(from);
            orderListModel.insert(to, item);
            syncOrderToConfig();
        }

        function syncOrderToConfig() {
            let parts = [];
            for (let i = 0; i < orderListModel.count; i++) {
                parts.push(orderListModel.get(i).key);
            }
            appearancePage.cfg_element_order = parts.join(",");
        }

        Repeater {
            model: orderListModel
            delegate: RowLayout {
                Layout.fillWidth: true

                QQC2.Label {
                    text: model.label
                    Layout.fillWidth: true
                }

                QQC2.Button {
                    icon.name: "arrow-up"
                    enabled: index > 0
                    onClicked: appearancePage.moveOrderItem(index, index - 1)
                    QQC2.ToolTip.text: i18n("Move up")
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: 800
                }

                QQC2.Button {
                    icon.name: "arrow-down"
                    enabled: index < orderListModel.count - 1
                    onClicked: appearancePage.moveOrderItem(index, index + 1)
                    QQC2.ToolTip.text: i18n("Move down")
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: 800
                }
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
            onClicked: saveThemeSheet.open()
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
                    onClicked: {
                        exportThemeArea.text = appearancePage.themeToJSON(index);
                        exportThemeSheet.open();
                    }
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
                onClicked: importThemeSheet.open()
            }

            QQC2.Button {
                text: i18n("Advanced: Raw JSON")
                icon.name: "text-x-generic"
                onClicked: rawJsonSheet.open()
            }
        }
    }

    // ===== Save Theme Sheet =====
    Kirigami.OverlaySheet {
        id: saveThemeSheet
        header: Kirigami.Heading {
            text: i18n("Save Theme")
            level: 3
        }

        ColumnLayout {
            spacing: Kirigami.Units.largeSpacing
            implicitWidth: Kirigami.Units.gridUnit * 25

            QQC2.TextField {
                id: themeNameField
                Kirigami.FormData.label: i18n("Name:")
                Layout.fillWidth: true
                placeholderText: i18n("My Theme")
            }

            QQC2.TextField {
                id: themeDescField
                Kirigami.FormData.label: i18n("Description:")
                Layout.fillWidth: true
                placeholderText: i18n("Optional description")
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                QQC2.Button {
                    text: i18n("Save")
                    icon.name: "document-save"
                    onClicked: {
                        appearancePage.saveCurrentTheme(themeNameField.text, themeDescField.text);
                        themeNameField.text = "";
                        themeDescField.text = "";
                        saveThemeSheet.close();
                    }
                }
                QQC2.Button {
                    text: i18n("Cancel")
                    onClicked: saveThemeSheet.close()
                }
            }
        }
    }

    // ===== Export Theme Sheet =====
    Kirigami.OverlaySheet {
        id: exportThemeSheet
        header: Kirigami.Heading {
            text: i18n("Export Theme")
            level: 3
        }

        ColumnLayout {
            spacing: Kirigami.Units.largeSpacing
            implicitWidth: Kirigami.Units.gridUnit * 25

            QQC2.Label {
                text: i18n("Copy this JSON to share or back up your theme.")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            QQC2.ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 12
                contentWidth: -1
                QQC2.TextArea {
                    id: exportThemeArea
                    readOnly: true
                    wrapMode: Text.NoWrap
                    font.family: "Monospace"
                    width: parent.width
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                QQC2.Button {
                    text: i18n("Close")
                    onClicked: exportThemeSheet.close()
                }
            }
        }
    }

    // ===== Import Theme Sheet =====
    Kirigami.OverlaySheet {
        id: importThemeSheet
        header: Kirigami.Heading {
            text: i18n("Import Theme")
            level: 3
        }

        ColumnLayout {
            spacing: Kirigami.Units.largeSpacing
            implicitWidth: Kirigami.Units.gridUnit * 25

            QQC2.Label {
                text: i18n("Paste a theme JSON below. It will be added to your saved themes.")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            QQC2.ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 12
                contentWidth: -1
                QQC2.TextArea {
                    id: importThemeArea
                    wrapMode: Text.NoWrap
                    font.family: "Monospace"
                    placeholderText: i18n("Paste theme JSON here...")
                    width: parent.width
                }
            }

            QQC2.Label {
                id: importErrorLabel
                text: ""
                color: Kirigami.Theme.negativeTextColor
                visible: text.length > 0
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                QQC2.Button {
                    text: i18n("Import")
                    icon.name: "document-import"
                    onClicked: {
                        try {
                            let data = JSON.parse(importThemeArea.text);
                            if (data.config && data.name) {
                                // It's a full theme object — save it
                                let themes = appearancePage.savedThemes.slice();
                                themes.push(data);
                                appearancePage.savedThemesJson = JSON.stringify(themes);
                                plasmoid.configuration.saved_themes = appearancePage.savedThemesJson;
                                importThemeSheet.close();
                            } else {
                                // It's raw config — import directly
                                appearancePage.applyConfig(importThemeArea.text);
                                appearancePage.updatePreview();
                                importThemeSheet.close();
                            }
                        } catch (e) {
                            importErrorLabel.text = i18n("Invalid JSON: %1", e.message);
                        }
                    }
                }
                QQC2.Button {
                    text: i18n("Cancel")
                    onClicked: importThemeSheet.close()
                }
            }
        }
    }

    // ===== Advanced: Raw JSON Sheet =====
    Kirigami.OverlaySheet {
        id: rawJsonSheet
        header: Kirigami.Heading {
            text: i18n("Widget Configuration (Raw JSON)")
            level: 3
        }

        ColumnLayout {
            spacing: Kirigami.Units.largeSpacing
            implicitWidth: Kirigami.Units.gridUnit * 25

            QQC2.Label {
                text: i18n("Copy this JSON to save your full config, or paste a previously saved JSON to restore it.")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            QQC2.ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 15
                contentWidth: -1
                QQC2.TextArea {
                    id: backupArea
                    text: appearancePage.getFullConfig()
                    wrapMode: Text.NoWrap
                    font.family: "Monospace"
                    width: parent.width
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                QQC2.Button {
                    text: i18n("Apply Pasted Config")
                    icon.name: "document-import"
                    onClicked: {
                        if (appearancePage.applyConfig(backupArea.text)) {
                            appearancePage.updatePreview();
                            rawJsonSheet.close();
                        } else {
                            backupArea.text = "INVALID JSON!";
                        }
                    }
                }
                QQC2.Button {
                    text: i18n("Reset to current")
                    onClicked: backupArea.text = appearancePage.getFullConfig()
                }
            }
        }
    }
}
