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

    property alias cfg_widget_spacing: widgetSpacing.value

    property alias cfg_locale: localeField.text

    Kirigami.FormLayout {
        anchors.fill: parent

        Kirigami.Heading {
            text: i18n("General")
            level: 2
            Layout.fillWidth: true
            Kirigami.FormData.isSection: true
        }

        QQC2.SpinBox {
            id: widgetSpacing

            Kirigami.FormData.label: i18n("Element spacing:")
            from: 0
            to: 999
        }

        QQC2.TextField {
            id: localeField

            Kirigami.FormData.label: i18n("Locale:")
            Layout.fillWidth: true

            placeholderText: i18n("e.g. fr_BE, en_GB, nl_BE")

            QQC2.ToolTip.text: i18n("Locale used for weekday and month names. Leave empty to use the system locale.")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 800
        }

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

            Kirigami.FormData.label: i18n("Day format:")
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

            Kirigami.FormData.label: i18n("Date format:")
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

        QQC2.CheckBox {
            id: use24HourFormat
            text: i18n("Use 24-hour format")
        }

        QQC2.TextField {
            id: timeFormat

            Kirigami.FormData.label: i18n("Time format:")
            Layout.fillWidth: true

            placeholderText: "hh:mm:ss | hh:mm AP"

            QQC2.ToolTip.text: i18n("Use Qt time formats like hh:mm, hh:mm:ss, or hh:mm AP. Leave empty to use the 12/24-hour setting.")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 800
        }

        QQC2.TextField {
            id: timeCharacter

            Kirigami.FormData.label: i18n("Decoration character:")
            Layout.fillWidth: true

            maximumLength: 1
            placeholderText: "-"

            QQC2.ToolTip.text: i18n("A character displayed on both sides of the time. Leave empty to show no decoration.")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 800
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
    }
}
