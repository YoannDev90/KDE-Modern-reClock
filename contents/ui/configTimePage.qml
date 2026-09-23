import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15

import org.kde.kirigami 2.0 as Kirigami
import org.kde.kquickcontrols 2.0 as KQControls

ColumnLayout {
    id: timePage
    property var ctx: null

    spacing: Kirigami.Units.largeSpacing

    Kirigami.FormLayout {
        Layout.fillWidth: true

        Kirigami.Heading {
            text: i18n("Time")
            level: 2
            Layout.fillWidth: true
            Kirigami.FormData.isSection: true
        }

        QQC2.CheckBox {
            id: showTime
            text: i18n("Show time")
            checked: ctx.cfg_show_time
            onToggled: ctx.cfg_show_time = checked
        }

        QQC2.ComboBox {
            id: timeFontCombo
            Kirigami.FormData.label: i18n("Font:")
            Layout.fillWidth: true
            model: ctx.fontArray
            currentIndex: ctx.fontIndexCache[ctx.cfg_fontFamilyTime] !== undefined ? ctx.fontIndexCache[ctx.cfg_fontFamilyTime] : 0
            editable: true
            onActivated: ctx.cfg_fontFamilyTime = ctx.fontArray[currentIndex]
            onEditTextChanged: {
                if (editText !== undefined && ctx.fontIndexCache[editText] !== undefined) {
                    ctx.cfg_fontFamilyTime = editText;
                }
            }
        }

        QQC2.SpinBox {
            id: timeFontSize
            Kirigami.FormData.label: i18n("Font size:")
            from: 1
            to: 999
            value: ctx.cfg_time_font_size
            onValueModified: ctx.cfg_time_font_size = value
        }

        QQC2.SpinBox {
            id: timeLetterSpacing
            Kirigami.FormData.label: i18n("Letter spacing:")
            from: 0
            to: 999
            value: ctx.cfg_time_letter_spacing
            onValueModified: ctx.cfg_time_letter_spacing = value
        }

        QQC2.TextField {
            id: timeFormat
            Kirigami.FormData.label: i18n("Format:")
            Layout.fillWidth: true
            placeholderText: i18n("hh:mm")
            text: ctx.cfg_time_format
            onEditingFinished: ctx.cfg_time_format = text
            QQC2.ToolTip.text: i18n("Use Qt time formats like hh:mm, hh:mm:ss, or hh:mm AP. Leave empty to use the 12/24-hour setting.")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 800
        }

        QQC2.CheckBox {
            id: use24HourFormat
            text: i18n("Use 24-hour format")
            checked: ctx.cfg_use_24_hour_format
            onToggled: ctx.cfg_use_24_hour_format = checked
        }

        QQC2.CheckBox {
            id: timeFontBold
            text: i18n("Bold")
            checked: ctx.cfg_time_font_bold
            onToggled: ctx.cfg_time_font_bold = checked
        }

        KQControls.ColorButton {
            id: timeFontColor
            Kirigami.FormData.label: i18n("Font color:")
            showAlphaChannel: false
            color: ctx.cfg_time_font_color
            onColorChanged: {
                var s = color.toString();
                if (ctx.cfg_time_font_color !== s) ctx.cfg_time_font_color = s;
            }
        }

        QQC2.TextField {
            id: timeCharacter
            Kirigami.FormData.label: i18n("Decoration character:")
            Layout.fillWidth: true
            placeholderText: "-"
            text: ctx.cfg_time_character
            onEditingFinished: ctx.cfg_time_character = text
            QQC2.ToolTip.text: i18n("A character displayed on both sides of the time. Leave empty to show no decoration.")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 800
        }

        QQC2.Button {
            text: i18n("Reset Time Settings")
            icon.name: "edit-undo"
            Layout.alignment: Qt.AlignRight
            onClicked: ctx.resetSection("time")
            QQC2.ToolTip.text: i18n("Restore time settings to defaults")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 800
        }
    }
}