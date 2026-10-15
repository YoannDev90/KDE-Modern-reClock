import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15

import org.kde.kirigami 2.0 as Kirigami

ColumnLayout {
    id: globalPage
    property var ctx: null

    // Wallpaper-derived color needs the desktop wallpaper — dropped in the taskbar variant
    readonly property var colorModeModel: (ctx && ctx.taskbar) ? [
        { text: i18n("Custom"), value: "custom" },
        { text: i18n("Follow system theme"), value: "theme" },
        { text: i18n("Inverse system theme"), value: "theme_inverse" }
    ] : [
        { text: i18n("Custom"), value: "custom" },
        { text: i18n("Follow system theme"), value: "theme" },
        { text: i18n("Inverse system theme"), value: "theme_inverse" },
        { text: i18n("Wallpaper-derived"), value: "wallpaper" }
    ]

    spacing: Kirigami.Units.largeSpacing

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
            checked: ctx.cfg_auto_scale
            onToggled: ctx.cfg_auto_scale = checked
        }

        // Alignment mode (screen containment — meaningless in a panel)
        RowLayout {
            visible: !ctx.taskbar
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
                    checked: ctx.cfg_alignMode === modelData.value
                    onToggled: if (checked) ctx.cfg_alignMode = modelData.value
                }
            }
        }

        QQC2.ComboBox {
            id: colorModeCombo
            Kirigami.FormData.label: i18n("Color mode:")
            Layout.fillWidth: true
            model: globalPage.colorModeModel
            textRole: "text"
            valueRole: "value"
            currentIndex: {
                var mode = ctx.cfg_color_mode || "custom";
                for (var i = 0; i < model.length; i++) {
                    if (model[i].value === mode) return i;
                }
                return 0;
            }
            onActivated: {
                var v = model[currentIndex].value;
                ctx.cfg_color_mode = v;
                ctx.refreshPreview();
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
            value: ctx.cfg_widget_spacing
            onValueModified: ctx.cfg_widget_spacing = value
        }

        QQC2.ComboBox {
            id: clockTimezoneCombo
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
            onActivated: ctx.cfg_clock_timezone = model.get(currentIndex).value;
            onEditTextChanged: {
                if (editText === undefined) return;
                if (editText.length === 0 || editText === "—") {
                    ctx.cfg_clock_timezone = "";
                    return;
                }
                var matched = false;
                for (var i = 0; i < model.count; i++) {
                    if (model.get(i).text === editText || model.get(i).value === editText) {
                        ctx.cfg_clock_timezone = model.get(i).value;
                        matched = true;
                        break;
                    }
                }
                if (!matched)
                    ctx.cfg_clock_timezone = editText;
            }
            Component.onCompleted: {
                if (!ctx) return;
                Qt.callLater(function() {
                    var id = ctx.cfg_clock_timezone || "";
                    if (id.length === 0) {
                        clockTimezoneCombo.currentIndex = 0;
                        return;
                    }
                    for (var i = 0; i < clockTimezoneCombo.model.count; i++) {
                        if (clockTimezoneCombo.model.get(i).value === id) {
                            clockTimezoneCombo.currentIndex = i;
                            return;
                        }
                    }
                    clockTimezoneCombo.editText = id;
                });
            }
            QQC2.ToolTip.text: i18n("Timezone for the main clock. Leave empty to follow the system timezone.")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 800
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
                if (!ctx) return;
                let loc = ctx.cfg_locale;
                currentIndex = 0;
                for (let i = 0; i < model.length; i++) { if (model[i].locale === loc) { currentIndex = i; break; } }
                if (currentIndex === 0 && loc !== "") currentIndex = model.length - 1;
            }
            onActivated: {
                let item = model[currentIndex];
                if (item.locale !== "custom") {
                    ctx.cfg_locale = item.locale;
                    if (item.day !== undefined) ctx.cfg_day_format = item.day;
                    if (item.date !== undefined) ctx.cfg_date_format = item.date;
                    if (item.time !== undefined) ctx.cfg_time_format = item.time;
                    if (item.h24 !== undefined) ctx.cfg_use_24_hour_format = item.h24;
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
                if (!ctx) return;
                let loc = ctx.cfg_locale;
                currentIndex = 0;
                for (let i = 0; i < model.length; i++) { if (model[i].locale === loc) { currentIndex = i; break; } }
            }
            onActivated: {
                ctx.cfg_locale = model[currentIndex].locale;
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
                if (!ctx) return;
                let d = ctx.cfg_date_format;
                let t = ctx.cfg_time_format;
                currentIndex = 0;
                for (let i = 0; i < model.length; i++) {
                    if (model[i].date === d && model[i].time === t) { currentIndex = i; break; }
                }
                if (currentIndex === 0 && (d !== model[0].date || t !== model[0].time)) currentIndex = model.length - 1;
            }
            onActivated: {
                let item = model[currentIndex];
                if (item.date !== "custom") {
                    ctx.cfg_date_format = item.date;
                    ctx.cfg_time_format = item.time;
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
            text: ctx.cfg_locale
            onTextChanged: ctx.cfg_locale = text
        }

        QQC2.TextField {
            visible: dateFormatCombo.currentIndex === dateFormatCombo.model.length - 1
            Kirigami.FormData.label: i18n("Date Format:")
            Layout.fillWidth: true
            placeholderText: i18n("dd MMMM yyyy")
            text: ctx.cfg_date_format
            onTextChanged: ctx.cfg_date_format = text
        }

        QQC2.TextField {
            visible: dateFormatCombo.currentIndex === dateFormatCombo.model.length - 1
            Kirigami.FormData.label: i18n("Time Format:")
            Layout.fillWidth: true
            placeholderText: i18n("HH:mm:ss")
            text: ctx.cfg_time_format
            onTextChanged: ctx.cfg_time_format = text
        }

        QQC2.Button {
            text: i18n("Reset Global Settings")
            icon.name: "edit-undo"
            Layout.alignment: Qt.AlignRight
            onClicked: globalPage.resetGlobal()
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

        OrderSection {
            id: orderSection
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: Kirigami.Units.gridUnit * 30
            Layout.minimumHeight: 180
            elementOrder: ctx.cfg_element_order
            onOrderChanged: function(newOrder) {
                ctx.cfg_element_order = newOrder;
            }
        }
    }

    // ===== GLOBAL RESET (owns the OrderSection here) =====
    function resetGlobal() {
        ctx.cfg_auto_scale = false;
        ctx.cfg_color_mode = "custom";
        ctx.cfg_widget_spacing = ctx.taskbar ? 2 : 5;
        ctx.cfg_locale = "";
        ctx.cfg_clock_timezone = "";
        orderSection.resetRequested();
        ctx.refreshPreview();
    }
}