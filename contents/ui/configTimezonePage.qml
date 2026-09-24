import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15

import org.kde.kirigami 2.0 as Kirigami
import org.kde.kquickcontrols 2.0 as KQControls

ColumnLayout {
    id: timezonePage
    property var ctx: null

    spacing: Kirigami.Units.largeSpacing

    Kirigami.FormLayout {
        Layout.fillWidth: true

        Kirigami.Heading {
            text: i18n("Secondary Timezone")
            level: 2
            Layout.fillWidth: true
            Kirigami.FormData.isSection: true
        }

        QQC2.CheckBox {
            id: showTimezone
            text: i18n("Show secondary timezone")
            checked: ctx.cfg_show_timezone
            onToggled: ctx.cfg_show_timezone = checked
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
                ctx.cfg_timezone_id = v;
                ctx.cfg_timezone_display_text = (currentIndex >= 0 && currentIndex < model.count)
                    ? model.get(currentIndex).text : "";
            }
            onEditTextChanged: {
                if (editText !== undefined && editText.length > 0 && editText !== "—") {
                    var matched = false;
                    for (var i = 0; i < model.count; i++) {
                        if (model.get(i).text === editText) {
                            ctx.cfg_timezone_id = model.get(i).value;
                            ctx.cfg_timezone_display_text = editText;
                            matched = true;
                            break;
                        }
                    }
                    if (!matched) {
                        for (var i = 0; i < model.count; i++) {
                            if (model.get(i).value === editText) {
                                ctx.cfg_timezone_id = editText;
                                matched = true;
                                break;
                            }
                        }
                    }
                    if (!matched) {
                        ctx.cfg_timezone_id = editText;
                    }
                }
            }
            Component.onCompleted: {
                if (!ctx) return;
                Qt.callLater(function() {
                    var d = ctx.cfg_timezone_display_text || "";
                    if (d.length > 0) {
                        for (var i = 0; i < timezoneIdField.model.count; i++) {
                            if (timezoneIdField.model.get(i).text === d) {
                                timezoneIdField.currentIndex = i;
                                return;
                            }
                        }
                    }
                    var id = ctx.cfg_timezone_id || "";
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
            text: ctx.cfg_timezone_label
            onEditingFinished: ctx.cfg_timezone_label = text
            QQC2.ToolTip.text: i18n("Short label displayed before the timezone time. Leave empty for no label.")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 800
        }

        FontComboBox {
            id: timezoneFontCombo
            ctx: timezonePage.ctx
            fontKey: "cfg_fontFamilyTimezone"
            configValue: ctx.cfg_fontFamilyTimezone
        }

        QQC2.SpinBox {
            id: timezoneFontSize
            Kirigami.FormData.label: i18n("Font size:")
            from: 1
            to: 999
            value: ctx.cfg_timezone_font_size
            onValueModified: ctx.cfg_timezone_font_size = value
        }

        QQC2.SpinBox {
            id: timezoneLetterSpacing
            Kirigami.FormData.label: i18n("Letter spacing:")
            from: 0
            to: 999
            value: ctx.cfg_timezone_letter_spacing
            onValueModified: ctx.cfg_timezone_letter_spacing = value
        }

        QQC2.CheckBox {
            id: timezoneFontBold
            text: i18n("Bold")
            checked: ctx.cfg_timezone_font_bold
            onToggled: ctx.cfg_timezone_font_bold = checked
        }

        KQControls.ColorButton {
            id: timezoneFontColor
            Kirigami.FormData.label: i18n("Font color:")
            showAlphaChannel: false
            color: ctx.cfg_timezone_font_color
            onColorChanged: {
                var s = color.toString();
                if (ctx.cfg_timezone_font_color !== s) ctx.cfg_timezone_font_color = s;
            }
        }

        QQC2.Button {
            text: i18n("Reset Timezone Settings")
            icon.name: "edit-undo"
            Layout.alignment: Qt.AlignRight
            onClicked: ctx.resetSection("timezone")
            QQC2.ToolTip.text: i18n("Restore timezone settings to defaults")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 800
        }
    }
}