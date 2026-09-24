import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15

import org.kde.kirigami 2.0 as Kirigami
import org.kde.kquickcontrols 2.0 as KQControls

ColumnLayout {
    id: datePage
    property var ctx: null

    spacing: Kirigami.Units.largeSpacing

    Kirigami.FormLayout {
        Layout.fillWidth: true

        Kirigami.Heading {
            text: i18n("Date")
            level: 2
            Layout.fillWidth: true
            Kirigami.FormData.isSection: true
        }

        QQC2.CheckBox {
            id: showDate
            text: i18n("Show date")
            checked: ctx.cfg_show_date
            onToggled: ctx.cfg_show_date = checked
        }

        FontComboBox {
            id: dateFontCombo
            ctx: datePage.ctx
            fontKey: "cfg_fontFamilyDate"
            configValue: ctx.cfg_fontFamilyDate
        }

        QQC2.SpinBox {
            id: dateFontSize
            Kirigami.FormData.label: i18n("Font size:")
            from: 1
            to: 999
            value: ctx.cfg_date_font_size
            onValueModified: ctx.cfg_date_font_size = value
        }

        QQC2.SpinBox {
            id: dateLetterSpacing
            Kirigami.FormData.label: i18n("Letter spacing:")
            from: 0
            to: 999
            value: ctx.cfg_date_letter_spacing
            onValueModified: ctx.cfg_date_letter_spacing = value
        }

        QQC2.TextField {
            id: dateFormat
            Kirigami.FormData.label: i18n("Format:")
            Layout.fillWidth: true
            placeholderText: "dd MMM yyyy"
            text: ctx.cfg_date_format
            onEditingFinished: ctx.cfg_date_format = text
            QQC2.ToolTip.text: i18n("Use Qt date formats like dd MMM yyyy, MM/dd/yyyy, or dddd d MMMM yyyy.")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 800
        }

        QQC2.CheckBox {
            id: uppercaseDate
            text: i18n("Uppercase")
            checked: ctx.cfg_uppercase_date
            onToggled: ctx.cfg_uppercase_date = checked
        }

        QQC2.CheckBox {
            id: dateFontBold
            text: i18n("Bold")
            checked: ctx.cfg_date_font_bold
            onToggled: ctx.cfg_date_font_bold = checked
        }

        KQControls.ColorButton {
            id: dateFontColor
            Kirigami.FormData.label: i18n("Font color:")
            showAlphaChannel: false
            color: ctx.cfg_date_font_color
            onColorChanged: {
                var s = color.toString();
                if (ctx.cfg_date_font_color !== s) ctx.cfg_date_font_color = s;
            }
        }

        QQC2.Button {
            text: i18n("Reset Date Settings")
            icon.name: "edit-undo"
            Layout.alignment: Qt.AlignRight
            onClicked: ctx.resetSection("date")
            QQC2.ToolTip.text: i18n("Restore date settings to defaults")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 800
        }
    }
}