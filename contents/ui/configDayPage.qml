import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15

import org.kde.kirigami 2.0 as Kirigami
import org.kde.kquickcontrols 2.0 as KQControls

ColumnLayout {
    id: dayPage
    property var ctx: null

    spacing: Kirigami.Units.largeSpacing

    Kirigami.FormLayout {
        Layout.fillWidth: true

        Kirigami.Heading {
            text: i18n("Day")
            level: 2
            Layout.fillWidth: true
            Kirigami.FormData.isSection: true
        }

        QQC2.CheckBox {
            id: showDay
            text: i18n("Show day")
            checked: ctx.cfg_show_day
            onToggled: ctx.cfg_show_day = checked
        }

        QQC2.ComboBox {
            id: dayFontCombo
            Kirigami.FormData.label: i18n("Font:")
            Layout.fillWidth: true
            model: ctx.fontArray
            currentIndex: ctx.fontIndexCache[ctx.cfg_fontFamilyDay] !== undefined ? ctx.fontIndexCache[ctx.cfg_fontFamilyDay] : 0
            editable: true
            onActivated: ctx.cfg_fontFamilyDay = ctx.fontArray[currentIndex]
            onEditTextChanged: {
                if (editText !== undefined && ctx.fontIndexCache[editText] !== undefined) {
                    ctx.cfg_fontFamilyDay = editText;
                }
            }
        }

        QQC2.SpinBox {
            id: dayFontSize
            Kirigami.FormData.label: i18n("Font size:")
            from: 1
            to: 999
            value: ctx.cfg_day_font_size
            onValueModified: ctx.cfg_day_font_size = value
        }

        QQC2.SpinBox {
            id: dayLetterSpacing
            Kirigami.FormData.label: i18n("Letter spacing:")
            from: 0
            to: 999
            value: ctx.cfg_day_letter_spacing
            onValueModified: ctx.cfg_day_letter_spacing = value
        }

        QQC2.TextField {
            id: dayFormat
            Kirigami.FormData.label: i18n("Format:")
            Layout.fillWidth: true
            placeholderText: "dddd"
            text: ctx.cfg_day_format
            onEditingFinished: ctx.cfg_day_format = text
            QQC2.ToolTip.text: i18n("Use Qt date formats. For example: dddd = full weekday name, ddd = short weekday name.")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 800
        }

        QQC2.CheckBox {
            id: uppercaseDay
            text: i18n("Uppercase")
            checked: ctx.cfg_uppercase_day
            onToggled: ctx.cfg_uppercase_day = checked
        }

        QQC2.CheckBox {
            id: dayFontBold
            text: i18n("Bold")
            checked: ctx.cfg_day_font_bold
            onToggled: ctx.cfg_day_font_bold = checked
        }

        KQControls.ColorButton {
            id: dayFontColor
            Kirigami.FormData.label: i18n("Font color:")
            showAlphaChannel: false
            color: ctx.cfg_day_font_color
            onColorChanged: {
                var s = color.toString();
                if (ctx.cfg_day_font_color !== s) ctx.cfg_day_font_color = s;
            }
        }

        QQC2.Button {
            text: i18n("Reset Day Settings")
            icon.name: "edit-undo"
            Layout.alignment: Qt.AlignRight
            onClicked: ctx.resetSection("day")
            QQC2.ToolTip.text: i18n("Restore day settings to defaults")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 800
        }
    }
}