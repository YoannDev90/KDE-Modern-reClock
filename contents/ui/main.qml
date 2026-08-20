import QtQml 2.0
import QtQuick 2.0
import QtQuick.Layouts 1.0
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.private.modernreclock 1.0 as ModernRecClock

PlasmoidItem {
    id: root

    // Logger shorthand — fallback to no-op if C++ plugin not loaded
    readonly property var log: ModernRecClock.Log ?? ({
        debug: function(cat, msg) {},
        info: function(cat, msg) {},
        warn: function(cat, msg) {},
        error: function(cat, msg) {}
    })

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

    property date currentDateTime: {
        var custom = plasmoid.configuration.custom_preview_date;
        if (custom && custom.length > 0) {
            var d = new Date(custom);
            if (!isNaN(d.getTime())) {
                log.debug("clock", "Using custom preview date: " + custom);
                return d;
            }
        }
        return new Date();
    }

    property bool use24HourFormat: plasmoid.configuration.use_24_hour_format
    property string timeCharacter: plasmoid.configuration.time_character
    property string localeName: plasmoid.configuration.locale
    property string dateFormat: plasmoid.configuration.date_format
    property string timeFormat: plasmoid.configuration.time_format
    property string dayFormat: plasmoid.configuration.day_format
    property bool uppercaseDay: plasmoid.configuration.uppercase_day
    property bool uppercaseDate: plasmoid.configuration.uppercase_date
    property bool autoScale: plasmoid.configuration.auto_scale
    property string colorMode: {
        // Migration: convert old adapt_to_theme bool to new color_mode string
        if (plasmoid.configuration.adapt_to_theme && (!plasmoid.configuration.color_mode || plasmoid.configuration.color_mode === "custom"))
            return "theme";
        return plasmoid.configuration.color_mode || "custom";
    }

    // ===== ELEMENT ORDER =====
    readonly property var validElements: ["day", "date", "time", "custom", "timezone"]
    property string elementOrderConfig: plasmoid.configuration.element_order
    property var elementOrderArray: {
        var base;
        if (!elementOrderConfig) {
            base = validElements.slice();
        } else {
            base = elementOrderConfig.split(",").map(function(x) { return x.trim(); }).filter(function(x) {
                return validElements.indexOf(x) !== -1;
            });
        }
        // Auto-append enabled elements not yet in the order (handles migration from older configs)
        var cfg = plasmoid.configuration;
        if (cfg.show_custom && base.indexOf("custom") === -1) base.push("custom");
        if (cfg.show_timezone && base.indexOf("timezone") === -1) base.push("timezone");
        return base.length > 0 ? base : validElements.slice();
    }

    // ===== ALIGNMENT =====
    readonly property string alignMode: plasmoid.configuration.alignMode || "none"

    function applyAlignment() {
        if (alignMode === "none") return;
        var containment = plasmoid.containment;
        if (!containment) return;
        var screenGeom = containment.screenGeometry;
        if (!screenGeom || screenGeom.width <= 0) return;
        var geom = plasmoid.geometry;
        if (!geom || geom.width <= 0) return;
        var newX = geom.x;
        var newY = geom.y;
        if (alignMode === "center") {
            newX = Math.round((screenGeom.width - geom.width) / 2);
            newY = Math.round((screenGeom.height - geom.height) / 2);
        } else if (alignMode === "centerH") {
            newX = Math.round((screenGeom.width - geom.width) / 2);
        } else if (alignMode === "centerV") {
            newY = Math.round((screenGeom.height - geom.height) / 2);
        }
        if (newX !== geom.x || newY !== geom.y) {
            plasmoid.geometry = Qt.rect(newX, newY, geom.width, geom.height);
            log.info("config", "Aligned widget to " + alignMode + " → (" + newX + "," + newY + ")");
        }
    }

    // ===== FONT FAMILIES =====
    property string fontFamilyDay: plasmoid.configuration.fontFamilyDay
    property string fontFamilyDate: plasmoid.configuration.fontFamilyDate
    property string fontFamilyTime: plasmoid.configuration.fontFamilyTime
    property string fontFamilyCustom: plasmoid.configuration.fontFamilyCustom
    property string fontFamilyTimezone: plasmoid.configuration.fontFamilyTimezone

    // ===== SYSTEM THEME COLORS =====
    readonly property color systemTextColor: PlasmaCore.Theme ? PlasmaCore.Theme.textColor : "#FFFFFF"
    readonly property color systemBgColor: {
        var r = 1.0 - systemTextColor.r;
        var g = 1.0 - systemTextColor.g;
        var b = 1.0 - systemTextColor.b;
        return Qt.rgba(r, g, b, 1.0);
    }

    // ===== WALLPAPER COLOR EXTRACTION =====
    property color _wallpaperColor: systemTextColor

    function _loadWallpaper() {
        if (!ModernRecClock.Wallpaper) return;
        var path = ModernRecClock.Wallpaper.wallpaperPath();
        log.debug("wallpaper", "wallpaperPath() returned: " + (path || "(empty)"));
        if (path && path.length > 0) {
            var brightness = ModernRecClock.Wallpaper.wallpaperBrightness(path);
            log.info("wallpaper", "Wallpaper loaded: " + path + " → brightness=" + brightness);
            _wallpaperColor = (brightness === "light") ? "#000000" : "#FFFFFF";
            log.debug("wallpaper", "Resolved wallpaper color: " + _wallpaperColor.toString());
        } else {
            log.warn("wallpaper", "No wallpaper path found, using theme color");
        }
    }

    // React to wallpaper changes via QFileSystemWatcher (C++ signal)
    Connections {
        target: ModernRecClock.Wallpaper ?? null
        function onWallpaperChanged() {
            log.info("wallpaper", "Wallpaper changed (watcher notification) — reloading");
            if (root.colorMode === "wallpaper") {
                _loadWallpaper();
            }
        }
    }

    onColorModeChanged: {
        log.info("config", "colorMode changed → " + colorMode);
        if (colorMode === "wallpaper") _loadWallpaper();
    }

    onLocaleNameChanged: { log.debug("clock", "localeName → " + localeName); updateClock(); }
    onDateFormatChanged: { log.debug("clock", "dateFormat → " + dateFormat); updateClock(); }
    onTimeFormatChanged: { log.debug("clock", "timeFormat → " + timeFormat); updateClock(); }
    onDayFormatChanged: { log.debug("clock", "dayFormat → " + dayFormat); updateClock(); }
    onUse24HourFormatChanged: { log.debug("clock", "use24HourFormat → " + use24HourFormat); updateClock(); }
    onTimeCharacterChanged: { log.debug("clock", "timeCharacter → " + timeCharacter); updateClock(); }
    onUppercaseDayChanged: { log.debug("clock", "uppercaseDay → " + uppercaseDay); updateClock(); }
    onUppercaseDateChanged: { log.debug("clock", "uppercaseDate → " + uppercaseDate); updateClock(); }

    readonly property string default24HourFormat: "HH:mm"
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
        _invalidatePropsCache();
        currentDateTime = new Date();
        log.debug("clock", "updateClock → " + timeText());
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
        log.debug("clock", "next tick in " + clockTimer.interval + "ms");
    }

    function formatDateLocaleAware(date, format, fallbackFormat = "dd MMM yyyy") {
        const fmt = format && format.trim().length > 0 ? format.trim() : fallbackFormat;

        try {
            return date.toLocaleDateString(effectiveLocale(), fmt);
        } catch (e) {
            log.warn("clock", "date format failed for '" + fmt + "': " + e.message);
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
            log.warn("clock", "time format failed for '" + format + "': " + e.message);
        }

        const fallbackFormat = use24HourFormat ? default24HourFormat : default12HourFormat;
        try {
            return date.toLocaleTimeString(effectiveLocale(), fallbackFormat);
        } catch (e) {
            log.error("clock", "fallback time format also failed: " + e.message);
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
        var isFormat = plasmoid.configuration.custom_format;
        log.debug("clock", "customText: text='" + text + "' format=" + isFormat);
        if (!isFormat) return text;
        try {
            var result = Qt.formatDateTime(currentDateTime, text);
            log.debug("clock", "customText formatted: '" + result + "'");
            return result && result.length > 0 ? result : text;
        } catch (e) {
            log.warn("clock", "custom format failed for '" + text + "': " + e.message);
            return text;
        }
    }

    // Derive timezone format from main time format, stripping seconds
    function timezoneFormat() {
        var base = currentTimeFormat();
        base = base.replace(/s{1,3}/g, '');
        base = base.replace(/z{1,3}/g, '');
        base = base.replace(/[:\s.]+$/, '');
        if (!base || base.trim().length === 0) {
            base = use24HourFormat ? "HH:mm" : "hh:mm";
        }
        log.debug("timezone", "timezoneFormat: " + base);
        return base;
    }

    function timezoneText() {
        var tzId = plasmoid.configuration.timezone_id || "";
        if (tzId.length === 0) return "";
        var label = plasmoid.configuration.timezone_label || "";
        var format = timezoneFormat();

        if (!ModernRecClock.TimeZone) {
            log.warn("timezone", "TimeZone plugin not loaded, cannot format timezone");
            return label.length > 0 ? label + " ??" : "??";
        }

        try {
            var formatted = ModernRecClock.TimeZone.formatDateTimeInZone(new Date(), format, tzId);
            if (formatted && formatted.length > 0) {
                log.debug("timezone", "Timezone " + tzId + " → " + formatted);
                return label.length > 0 ? label + " " + formatted : formatted;
            }
            // Fallback: try abbreviation
            var tzObj = ModernRecClock.TimeZone.timeZoneObject(tzId);
            if (tzObj && tzObj.abbreviation) {
                log.debug("timezone", "Timezone " + tzId + " abbreviation: " + tzObj.abbreviation);
                return label.length > 0 ? label + " " + tzObj.abbreviation : tzObj.abbreviation;
            }
        } catch (e) {
            log.error("timezone", "Timezone error for " + tzId + ": " + e.message);
        }
        return label.length > 0 ? label + " ??" : "??";
    }

    // ===== ELEMENT PROPERTY HELPERS (data-driven) =====
    function _resolvedColor(cfgColor) {
        var mode = root.colorMode;
        if (mode === "theme") return root.systemTextColor;
        if (mode === "theme_inverse") return root.systemBgColor;
        if (mode === "wallpaper") return root._wallpaperColor;
        return cfgColor; // "custom" mode
    }

    function _elementProps(type) {
        var cfg = plasmoid.configuration;
        var p = null;
        if (type === "day") p = { show: cfg.show_day, text: dayText(), font: fontFamilyDay, size: cfg.day_font_size, spacing: cfg.day_letter_spacing, bold: cfg.day_font_bold, color: _resolvedColor(cfg.day_font_color) };
        else if (type === "date") p = { show: cfg.show_date, text: dateText(), font: fontFamilyDate, size: cfg.date_font_size, spacing: cfg.date_letter_spacing, bold: cfg.date_font_bold, color: _resolvedColor(cfg.date_font_color) };
        else if (type === "time") p = { show: cfg.show_time, text: timeText(), font: fontFamilyTime, size: cfg.time_font_size, spacing: cfg.time_letter_spacing, bold: cfg.time_font_bold, color: _resolvedColor(cfg.time_font_color) };
        else if (type === "custom") p = { show: cfg.show_custom, text: customText(), font: fontFamilyCustom, size: cfg.custom_font_size, spacing: cfg.custom_letter_spacing, bold: cfg.custom_font_bold, color: _resolvedColor(cfg.custom_font_color) };
        else if (type === "timezone") p = { show: cfg.show_timezone, text: timezoneText(), font: fontFamilyTimezone, size: cfg.timezone_font_size, spacing: cfg.timezone_letter_spacing, bold: cfg.timezone_font_bold, color: _resolvedColor(cfg.timezone_font_color) };
        if (p) log.debug("clock", "elementProps " + type + ": show=" + p.show + " font=" + p.font + " size=" + p.size + " color=" + p.color);
        return p;
    }

    // Cache element props to avoid 7 redundant _elementProps() calls per element per tick
    property var _cachedProps: ({}); function _getProps(type) { if (!_cachedProps[type]) _cachedProps[type] = _elementProps(type); return _cachedProps[type]; }
    function elementVisible(type) { var p = _getProps(type); return p ? p.show : false; }
    function elementText(type) { var p = _getProps(type); return p ? p.text : ""; }
    function elementFont(type) { var p = _getProps(type); return p ? p.font : ""; }
    function elementFontSize(type) { var p = _getProps(type); return p ? p.size : 1; }
    function elementLetterSpacing(type) { var p = _getProps(type); return p ? p.spacing : 0; }
    function elementFontBold(type) { var p = _getProps(type); return p ? p.bold : false; }
    function elementFontColor(type) { var p = _getProps(type); return p ? p.color : "#FFFFFF"; }
    function _invalidatePropsCache() { _cachedProps = ({}); }

    Timer {
        id: clockTimer
        repeat: false
        running: false

        onTriggered: root.updateClock()
    }

    onResolvedTimeFormatChanged: { log.debug("clock", "resolvedTimeFormat → " + resolvedTimeFormat); updateClock(); }

    Component.onCompleted: {
        log.info("clock", "═══ Modern reClock started ═══");
        var cfg = plasmoid.configuration;
        log.info("clock", "Time format: " + resolvedTimeFormat + " (24h=" + use24HourFormat + ")");
        log.info("clock", "Locale: " + effectiveLocale().name + (localeName ? " (custom='" + localeName + "')" : " (system)"));
        log.info("clock", "Color mode: " + colorMode);
        log.info("clock", "Element order: " + elementOrderArray.join(","));
        log.info("clock", "Day format: '" + (dayFormat || "dddd") + "' uppercase=" + uppercaseDay);
        log.info("clock", "Date format: '" + (dateFormat || "dd MMM yyyy") + "' uppercase=" + uppercaseDate);
        log.info("clock", "Time character: '" + (timeCharacter || "(none)") + "'");
        log.info("clock", "Auto scale: " + autoScale + " spacing: " + plasmoid.configuration.widget_spacing);
        log.info("clock", "Show: day=" + cfg.show_day + " date=" + cfg.show_date + " time=" + cfg.show_time + " custom=" + cfg.show_custom + " tz=" + cfg.show_timezone);

        // Element fonts and colors
        log.debug("clock", "Day: font=" + (fontFamilyDay || "Anurati") + " size=" + cfg.day_font_size + " color=" + _resolvedColor(cfg.day_font_color).toString());
        log.debug("clock", "Date: font=" + (fontFamilyDate || "Poppins") + " size=" + cfg.date_font_size + " color=" + _resolvedColor(cfg.date_font_color).toString());
        log.debug("clock", "Time: font=" + (fontFamilyTime || "Poppins") + " size=" + cfg.time_font_size + " color=" + _resolvedColor(cfg.time_font_color).toString());
        log.debug("clock", "Custom: font=" + (fontFamilyCustom || "Poppins") + " size=" + cfg.custom_font_size + " text='" + (cfg.custom_text || "") + "' fmt=" + cfg.custom_format);
        log.debug("clock", "Tz: id=" + (cfg.timezone_id || "(none)") + " label='" + (cfg.timezone_label || "") + "' font=" + (fontFamilyTimezone || "Poppins") + " size=" + cfg.timezone_font_size);

        // Resolved values
        log.debug("clock", "Day text: '" + dayText() + "'");
        log.debug("clock", "Date text: '" + dateText() + "'");
        log.debug("clock", "Time text: '" + timeText() + "'");
        var tzResult = timezoneText();
        log.debug("clock", "Timezone text: '" + tzResult + "'");

        updateClock();
        if (colorMode === "wallpaper") _loadWallpaper();

        // Alignment: apply on load and connect to screen geometry changes
        applyAlignment();
        try {
            var cont = plasmoid.containment;
            if (cont) {
                cont.screenGeometryChanged.connect(applyAlignment);
                log.info("config", "Alignment mode: " + alignMode + " (connected to screenGeometryChanged)");
            }
        } catch (e) {
            log.warn("config", "Could not connect screenGeometryChanged: " + e.message);
        }
    }

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
