import QtQml
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    // Setting background as transparent with a drop shadow
    Plasmoid.backgroundHints: PlasmaCore.Types.ShadowBackground | PlasmaCore.Types.ConfigurableBackground

    // Setting preferred size
    preferredRepresentation: fullRepresentation

    // loading fonts
    FontLoader {
        id: font_anurati
        source: "../fonts/Anurati.otf"
    }
    FontLoader {
        id: font_poppins
        source: "../fonts/Poppins.ttf"
    }

    property date currentDateTime: new Date()

    property bool use24HourFormat: plasmoid.configuration.use_24_hour_format
    property string timeCharacter: plasmoid.configuration.time_character
    property string localeName: plasmoid.configuration.locale
    property string dateFormat: plasmoid.configuration.date_format
    property string timeFormat: plasmoid.configuration.time_format
    property string dayFormat: plasmoid.configuration.day_format
    property bool uppercaseDay: plasmoid.configuration.uppercase_day
    property bool uppercaseDate: plasmoid.configuration.uppercase_date
    readonly property string default24HourFormat: "hh:mm"
    readonly property string default12HourFormat: "hh:mm AP"

    readonly property string resolvedTimeFormat: currentTimeFormat()
    readonly property bool resolvedTimeFormatUsesSeconds: usesSeconds(resolvedTimeFormat)

    function effectiveLocale() {
        let custom = localeName ? localeName.trim() : ""
        custom = custom.replace(/-/g, "_") // Replace hyphens with underscores for Qt locale compatibility
        return custom.length > 0 ? Qt.locale(custom) : Qt.locale()
    }

    function currentTimeFormat() {
        const custom = timeFormat ? timeFormat.trim() : ""

        if (custom.length > 0)
            return custom

        return use24HourFormat ? default24HourFormat : default12HourFormat
    }

    function usesSeconds(format) {
        return /s{1,2}/.test(format)
    }

    function updateClock() {
        currentDateTime = new Date()
        scheduleNextClockTick()
    }

    function scheduleNextClockTick() {
        const now = new Date()
        let delay

        if (resolvedTimeFormatUsesSeconds) {
            delay = 1000 - now.getMilliseconds()
        } else {
            delay = 60000 - (now.getSeconds() * 1000) - now.getMilliseconds()
        }

        clockTimer.interval = Math.max(50, delay)
        clockTimer.restart()
    }

    function formatDateLocaleAware(date, format, fallbackFormat = "dd MMM yyyy") {
        const fmt = format && format.trim().length > 0 ? format.trim() : fallbackFormat

        try {
            return date.toLocaleDateString(effectiveLocale(), fmt)
        } catch (e) {
            return Qt.formatDate(date, fallbackFormat)
        }
    }

    function formatTimeLocaleAware(date) {
        const format = currentTimeFormat()

        try {
            var formatted = date.toLocaleTimeString(effectiveLocale(), format)
            if (formatted && formatted.trim() !== "") {
                return formatted
            }
        } catch (e) {
        }

        const fallbackFormat = use24HourFormat ? default24HourFormat : default12HourFormat
        try {
            return date.toLocaleTimeString(effectiveLocale(), fallbackFormat)
        } catch (e) {
            return Qt.formatTime(date, fallbackFormat)
        }
    }

    function dayText() {
        const format = dayFormat && dayFormat.trim().length > 0 ? dayFormat : "dddd"

        const text = formatDateLocaleAware(currentDateTime, format)
        return uppercaseDay ? text.toUpperCase() : text
    }

    function dateText() {
        const text = formatDateLocaleAware(currentDateTime, dateFormat)
        return uppercaseDate ? text.toUpperCase() : text
    }

    function timeText() {
        const formattedTime = formatTimeLocaleAware(currentDateTime)
        const decoration = timeCharacter || ""

        if (decoration.trim().length === 0)
            return formattedTime

        return decoration + " " + formattedTime + " " + decoration
    }

    Timer {
        id: clockTimer
        repeat: false
        running: false

        onTriggered: root.updateClock()
    }

    onResolvedTimeFormatChanged: updateClock()

    Component.onCompleted: updateClock()

    fullRepresentation: Item {
        // applet default size
        Layout.minimumWidth: container.implicitWidth
        Layout.minimumHeight: container.implicitHeight
        Layout.preferredWidth: Layout.minimumWidth
        Layout.preferredHeight: Layout.minimumHeight

        // Main Content
        Column {
            id: container

            // Column settings
            anchors.centerIn: parent
            spacing: plasmoid.configuration.widget_spacing

            // Day
            PlasmaComponents.Label {
                id: display_day

                visible: plasmoid.configuration.show_day
                text: root.dayText()

                // font settings
                font.pixelSize: plasmoid.configuration.day_font_size
                font.letterSpacing: plasmoid.configuration.day_letter_spacing
                font.family: font_anurati.name
                font.bold: plasmoid.configuration.day_font_bold

                color: plasmoid.configuration.day_font_color

                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
            }

            // Date
            PlasmaComponents.Label {
                id: display_date

                visible: plasmoid.configuration.show_date
                text: root.dateText()

                // font settings
                font.pixelSize: plasmoid.configuration.date_font_size
                font.letterSpacing: plasmoid.configuration.date_letter_spacing
                font.family: font_poppins.name
                font.bold: plasmoid.configuration.date_font_bold

                color: plasmoid.configuration.date_font_color

                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
            }

            // Time
            PlasmaComponents.Label {
                id: display_time

                visible: plasmoid.configuration.show_time
                text: root.timeText()

                // font settings
                font.pixelSize: plasmoid.configuration.time_font_size
                font.letterSpacing: plasmoid.configuration.time_letter_spacing
                font.family: font_poppins.name
                font.bold: plasmoid.configuration.time_font_bold

                color: plasmoid.configuration.time_font_color

                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
