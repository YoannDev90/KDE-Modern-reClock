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
    property bool adaptToTheme: plasmoid.configuration.adapt_to_theme

    // ===== ELEMENT ORDER =====
    readonly property var validElements: ["day", "date", "time", "custom", "timezone"]
    property string elementOrderConfig: plasmoid.configuration.element_order
    property var elementOrderArray: {
        if (!elementOrderConfig) return validElements.slice();
        var arr = elementOrderConfig.split(",").map(function(x) { return x.trim(); }).filter(function(x) {
            return validElements.indexOf(x) !== -1;
        });
        return arr.length > 0 ? arr : validElements.slice();
    }

    // ===== FONT FAMILIES =====
    property string fontFamilyDay: plasmoid.configuration.fontFamilyDay
    property string fontFamilyDate: plasmoid.configuration.fontFamilyDate
    property string fontFamilyTime: plasmoid.configuration.fontFamilyTime
    property string fontFamilyCustom: plasmoid.configuration.fontFamilyCustom
    property string fontFamilyTimezone: plasmoid.configuration.fontFamilyTimezone

    // ===== SYSTEM THEME COLOR =====
    readonly property color systemTextColor: PlasmaCore.Theme ? PlasmaCore.Theme.textColor : "#FFFFFF"

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
            console.warn("Modern reClock: date format failed for", fmt, "-", e.message);
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
        } catch (e) {
            console.warn("Modern reClock: time format failed for", format, "-", e.message);
        }

        const fallbackFormat = use24HourFormat ? default24HourFormat : default12HourFormat;
        try {
            return date.toLocaleTimeString(effectiveLocale(), fallbackFormat);
        } catch (e) {
            console.warn("Modern reClock: fallback time format failed -", e.message);
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

    function customText() {
        var text = plasmoid.configuration.custom_text || "";
        if (text.length === 0) return "";
        if (!plasmoid.configuration.custom_format) return text;
        try {
            var result = Qt.formatDateTime(currentDateTime, text);
            return result && result.length > 0 ? result : text;
        } catch (e) {
            console.warn("Modern reClock: custom format failed for", text, "-", e.message);
            return text;
        }
    }

    function timezoneText() {
        var tzId = plasmoid.configuration.timezone_id || "";
        if (tzId.length === 0) return "";
        var label = plasmoid.configuration.timezone_label || "";
        var format = plasmoid.configuration.timezone_format || "HH:mm";

        try {
            var now = new Date();
            var formatter = new Intl.DateTimeFormat(Qt.locale().name, {
                timeZone: tzId,
                hour: "2-digit",
                minute: "2-digit",
                hour12: false
            });
            var timeStr = formatter.format(now);

            // Apply simple format replacements (HH, H, mm, m)
            var h24 = timeStr.split(":")[0] || "00";
            var min = timeStr.split(":")[1] || "00";
            var result = format;
            result = result.replace("HH", h24);
            result = result.replace("H", parseInt(h24).toString());
            result = result.replace("mm", min);
            result = result.replace("m", parseInt(min).toString());

            return label.length > 0 ? label + " " + result : result;
        } catch (e) {
            console.warn("Modern reClock: timezone error for", tzId, "-", e.message);
            return label.length > 0 ? label + " ??" : "??";
        }
    }

    // ===== ELEMENT PROPERTY HELPERS (data-driven) =====
    function _elementProps(type) {
        var cfg = plasmoid.configuration;
        var tc = root.adaptToTheme ? root.systemTextColor : undefined;

        if (type === "day") return { show: cfg.show_day, text: dayText(), font: fontFamilyDay, size: cfg.day_font_size, spacing: cfg.day_letter_spacing, bold: cfg.day_font_bold, color: tc !== undefined ? tc : cfg.day_font_color };
        if (type === "date") return { show: cfg.show_date, text: dateText(), font: fontFamilyDate, size: cfg.date_font_size, spacing: cfg.date_letter_spacing, bold: cfg.date_font_bold, color: tc !== undefined ? tc : cfg.date_font_color };
        if (type === "time") return { show: cfg.show_time, text: timeText(), font: fontFamilyTime, size: cfg.time_font_size, spacing: cfg.time_letter_spacing, bold: cfg.time_font_bold, color: tc !== undefined ? tc : cfg.time_font_color };
        if (type === "custom") return { show: cfg.show_custom, text: customText(), font: fontFamilyCustom, size: cfg.custom_font_size, spacing: cfg.custom_letter_spacing, bold: cfg.custom_font_bold, color: tc !== undefined ? tc : cfg.custom_font_color };
        if (type === "timezone") return { show: cfg.show_timezone, text: timezoneText(), font: fontFamilyTimezone, size: cfg.timezone_font_size, spacing: cfg.timezone_letter_spacing, bold: cfg.timezone_font_bold, color: tc !== undefined ? tc : cfg.timezone_font_color };
        return null;
    }

    function elementVisible(type) { var p = _elementProps(type); return p ? p.show : false; }
    function elementText(type) { var p = _elementProps(type); return p ? p.text : ""; }
    function elementFont(type) { var p = _elementProps(type); return p ? p.font : ""; }
    function elementFontSize(type) { var p = _elementProps(type); return p ? p.size : 1; }
    function elementLetterSpacing(type) { var p = _elementProps(type); return p ? p.spacing : 0; }
    function elementFontBold(type) { var p = _elementProps(type); return p ? p.bold : false; }
    function elementFontColor(type) { var p = _elementProps(type); return p ? p.color : "#FFFFFF"; }

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
