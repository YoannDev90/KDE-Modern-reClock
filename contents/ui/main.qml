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
        id: anuratiFontLoader
        source: Qt.resolvedUrl("../fonts/Anurati.otf")
    }
    FontLoader {
        id: poppinsFontLoader
        source: Qt.resolvedUrl("../fonts/Poppins.ttf")
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
    property bool autoScale: plasmoid.configuration.auto_scale

    // ===== ELEMENT ORDER =====
    property string elementOrderConfig: plasmoid.configuration.element_order
    property var elementOrderArray: elementOrderConfig ? elementOrderConfig.split(",") : ["day", "date", "time"]

    // ===== FONT FAMILIES =====
    property string fontFamilyDay: plasmoid.configuration.fontFamilyDay
    property string fontFamilyDate: plasmoid.configuration.fontFamilyDate
    property string fontFamilyTime: plasmoid.configuration.fontFamilyTime

    onLocaleNameChanged: updateClock()
    onDateFormatChanged: updateClock()
    onTimeFormatChanged: updateClock()
    onDayFormatChanged: updateClock()
    onUse24HourFormatChanged: updateClock()
    onTimeCharacterChanged: updateClock()
    onUppercaseDayChanged: updateClock()
    onUppercaseDateChanged: updateClock()

    readonly property string default24HourFormat: "hh:mm"
    readonly property string default12HourFormat: "hh:mm AP"

    readonly property string resolvedTimeFormat: currentTimeFormat()
    readonly property bool resolvedTimeFormatUsesSeconds: usesSeconds(resolvedTimeFormat)

    function effectiveLocale() {
        let custom = localeName ? localeName.trim() : "";
        custom = custom.replace(/-/g, "_"); // Replace hyphens with underscores for Qt locale compatibility
        return custom.length > 0 ? Qt.locale(custom) : Qt.locale();
    }

    function currentTimeFormat() {
        const custom = timeFormat ? timeFormat.trim() : "";

        if (custom.length > 0)
            return custom;

        return use24HourFormat ? default24HourFormat : default12HourFormat;
    }

    function usesSeconds(format) {
        return /s{1,2}/.test(format);
    }

    function updateClock() {
        currentDateTime = new Date();
        scheduleNextClockTick();
    }

    function scheduleNextClockTick() {
        const now = new Date();
        let delay;

        if (resolvedTimeFormatUsesSeconds) {
            delay = 1000 - now.getMilliseconds();
        } else {
            delay = 60000 - (now.getSeconds() * 1000) - now.getMilliseconds();
        }

        clockTimer.interval = Math.max(50, delay);
        clockTimer.restart();
    }

    function formatDateLocaleAware(date, format, fallbackFormat = "dd MMM yyyy") {
        const fmt = format && format.trim().length > 0 ? format.trim() : fallbackFormat;

        try {
            return date.toLocaleDateString(effectiveLocale(), fmt);
        } catch (e) {
            return Qt.formatDate(date, fallbackFormat);
        }
    }

    function formatTimeLocaleAware(date) {
        const format = currentTimeFormat();

        try {
            var formatted = date.toLocaleTimeString(effectiveLocale(), format);
            if (formatted && formatted.trim() !== "") {
                return formatted;
            }
        } catch (e) {}

        const fallbackFormat = use24HourFormat ? default24HourFormat : default12HourFormat;
        try {
            return date.toLocaleTimeString(effectiveLocale(), fallbackFormat);
        } catch (e) {
            return Qt.formatTime(date, fallbackFormat);
        }
    }

    function dayText() {
        const format = dayFormat && dayFormat.trim().length > 0 ? dayFormat : "dddd";

        const text = formatDateLocaleAware(currentDateTime, format);
        return uppercaseDay ? text.toUpperCase() : text;
    }

    function dateText() {
        const text = formatDateLocaleAware(currentDateTime, dateFormat);
        return uppercaseDate ? text.toUpperCase() : text;
    }

    function timeText() {
        const formattedTime = formatTimeLocaleAware(currentDateTime);
        const decoration = timeCharacter || "";

        if (decoration.trim().length === 0)
            return formattedTime;

        return decoration + " " + formattedTime + " " + decoration;
    }

    // ===== ELEMENT PROPERTY HELPERS =====
    function elementVisible(type) {
        if (type === "day") return plasmoid.configuration.show_day;
        if (type === "date") return plasmoid.configuration.show_date;
        if (type === "time") return plasmoid.configuration.show_time;
        return false;
    }

    function elementText(type) {
        if (type === "day") return dayText();
        if (type === "date") return dateText();
        if (type === "time") return timeText();
        return "";
    }

    function elementFont(type) {
        if (type === "day") return fontFamilyDay;
        if (type === "date") return fontFamilyDate;
        if (type === "time") return fontFamilyTime;
        return "";
    }

    function elementFontSize(type) {
        if (type === "day") return plasmoid.configuration.day_font_size;
        if (type === "date") return plasmoid.configuration.date_font_size;
        if (type === "time") return plasmoid.configuration.time_font_size;
        return 1;
    }

    function elementLetterSpacing(type) {
        if (type === "day") return plasmoid.configuration.day_letter_spacing;
        if (type === "date") return plasmoid.configuration.date_letter_spacing;
        if (type === "time") return plasmoid.configuration.time_letter_spacing;
        return 0;
    }

    function elementFontBold(type) {
        if (type === "day") return plasmoid.configuration.day_font_bold;
        if (type === "date") return plasmoid.configuration.date_font_bold;
        if (type === "time") return plasmoid.configuration.time_font_bold;
        return false;
    }

    function elementFontColor(type) {
        if (type === "day") return plasmoid.configuration.day_font_color;
        if (type === "date") return plasmoid.configuration.date_font_color;
        if (type === "time") return plasmoid.configuration.time_font_color;
        return "#FFFFFF";
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
        id: containerWrapper

        // Ensure we fill the available space
        anchors.fill: parent

        readonly property bool isAutoScale: root.autoScale

        // Hidden metrics labels to calculate natural size
        // We use plain Text to avoid any Plasma styling interference during measurement
        Item {
            id: metricsProvider
            visible: false
            width: metricsColumn.implicitWidth
            height: metricsColumn.implicitHeight
            Column {
                id: metricsColumn
                spacing: plasmoid.configuration.widget_spacing
                Repeater {
                    model: root.elementOrderArray
                    Text {
                        text: root.elementText(modelData)
                        visible: root.elementVisible(modelData)
                        font.pixelSize: root.elementFontSize(modelData)
                        font.letterSpacing: root.elementLetterSpacing(modelData)
                        font.family: root.elementFont(modelData)
                        font.bold: root.elementFontBold(modelData)
                    }
                }
            }
        }

        readonly property real fontScale: isAutoScale ? Math.min((width - 16) / Math.max(1, metricsProvider.width), (height - 16) / Math.max(1, metricsProvider.height)) : 1.0

        // Preferred size for the applet
        Layout.minimumWidth: isAutoScale ? 50 : metricsProvider.width
        Layout.minimumHeight: isAutoScale ? 20 : metricsProvider.height
        Layout.preferredWidth: Layout.minimumWidth
        Layout.preferredHeight: Layout.minimumHeight

        // Main Content
        Column {
            id: innerColumn
            anchors.centerIn: parent
            spacing: plasmoid.configuration.widget_spacing * containerWrapper.fontScale

            Repeater {
                model: root.elementOrderArray

                // Each delegate is a Text element styled per element type
                Text {
                    visible: root.elementVisible(modelData)
                    text: root.elementText(modelData)
                    font.family: root.elementFont(modelData)
                    font.pixelSize: Math.max(1, Math.round(root.elementFontSize(modelData) * containerWrapper.fontScale))
                    font.letterSpacing: root.elementLetterSpacing(modelData) * containerWrapper.fontScale
                    font.bold: root.elementFontBold(modelData)
                    color: root.elementFontColor(modelData)
                    anchors.horizontalCenter: parent.horizontalCenter
                    horizontalAlignment: Text.AlignHCenter
                    renderType: Text.CurveRendering
                }
            }
        }
    }
}
