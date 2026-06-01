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

    readonly property var configKeys: ["day_font_size", "day_letter_spacing", "show_day", "date_font_size", "date_letter_spacing", "locale", "date_format", "show_date", "time_font_size", "time_letter_spacing", "time_format", "time_font_color", "show_time", "date_font_color", "day_font_color", "use_24_hour_format", "time_character", "widget_spacing", "day_format", "uppercase_day", "uppercase_date", "day_font_bold", "date_font_bold", "time_font_bold", "auto_scale", "fontFamilyDay", "fontFamilyDate", "fontFamilyTime"]

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

    Kirigami.FormLayout {
        anchors.fill: parent

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
            model: ["Anurati", "Poppins", "Arial", "Times New Roman", "Monospace", "Sans Serif"]
            currentIndex: Math.max(0, model.indexOf(appearancePage.cfg_fontFamilyDay))
            onActivated: appearancePage.cfg_fontFamilyDay = model[currentIndex]
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
            model: ["Anurati", "Poppins", "Arial", "Times New Roman", "Monospace", "Sans Serif"]
            currentIndex: Math.max(0, model.indexOf(appearancePage.cfg_fontFamilyDate))
            onActivated: appearancePage.cfg_fontFamilyDate = model[currentIndex]
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
            model: ["Anurati", "Poppins", "Arial", "Times New Roman", "Monospace", "Sans Serif"]
            currentIndex: Math.max(0, model.indexOf(appearancePage.cfg_fontFamilyTime))
            onActivated: appearancePage.cfg_fontFamilyTime = model[currentIndex]
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

        // ================= SECTION: DOTFILE / BACKUP =================
        Kirigami.Heading {
            text: i18n("Dotfile / Backup")
            level: 2
            Layout.fillWidth: true
            Kirigami.FormData.isSection: true
        }

        QQC2.Button {
            text: i18n("Import/Export Config JSON")
            icon.name: "document-export"
            onClicked: backupSheet.open()
        }
    }

    Kirigami.OverlaySheet {
        id: backupSheet
        header: Kirigami.Heading {
            text: i18n("Widget Configuration (JSON)")
            level: 3
        }

        ColumnLayout {
            spacing: Kirigami.Units.largeSpacing
            width: Kirigami.Units.gridUnit * 25

            QQC2.Label {
                text: i18n("Copy this JSON to save your config as a dotfile, or paste a previously saved JSON to restore it.")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            QQC2.ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 15
                QQC2.TextArea {
                    id: backupArea
                    text: appearancePage.getFullConfig()
                    wrapMode: Text.NoWrap
                    font.family: "Monospace"
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                QQC2.Button {
                    text: i18n("Apply Pasted Config")
                    icon.name: "document-import"
                    onClicked: {
                        if (appearancePage.applyConfig(backupArea.text)) {
                            backupSheet.close();
                        } else {
                            // Simple error feedback
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
