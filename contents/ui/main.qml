import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.0 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.private.modernreclock 1.0 as ModernRecClock

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.ShadowBackground | PlasmaCore.Types.ConfigurableBackground
    preferredRepresentation: fullRepresentation

    // Bundled fonts
    FontLoader { source: Qt.resolvedUrl("../fonts/Anurati.otf") }
    FontLoader { source: Qt.resolvedUrl("../fonts/Poppins.ttf") }

    // All clock logic lives here (timer, formatting, order, colors)
    ModernRecClock.ClockModel { id: clock }

    // Theme-derived colors (inverse of the system text color)
    readonly property color themeText: Kirigami.Theme.textColor
    readonly property color themeBg: Qt.rgba(1 - themeText.r, 1 - themeText.g, 1 - themeText.b, 1.0)

    // ---- Push configuration into the engine ----
    function syncConfig() {
        clock.setThemeColors(themeText, themeBg);
        if (ModernRecClock.Wallpaper) {
            var path = ModernRecClock.Wallpaper.wallpaperPath();
            if (path && path.length > 0) {
                clock.setWallpaperColor(ModernRecClock.Wallpaper.wallpaperBrightness(path) === "light" ? "#000000" : "#FFFFFF");
            }
        }
        var c = plasmoid.configuration;
        clock.setConfig({
            showDay: c.show_day, showDate: c.show_date,
            showTime: c.show_time, showTimezone: c.show_timezone,
            fontDay: c.fontFamilyDay, fontDate: c.fontFamilyDate,
            fontTime: c.fontFamilyTime, fontTimezone: c.fontFamilyTimezone,
            sizeDay: c.day_font_size, sizeDate: c.date_font_size,
            sizeTime: c.time_font_size, sizeTimezone: c.timezone_font_size,
            spacingDay: c.day_letter_spacing, spacingDate: c.date_letter_spacing,
            spacingTime: c.time_letter_spacing, spacingTimezone: c.timezone_letter_spacing,
            boldDay: c.day_font_bold, boldDate: c.date_font_bold,
            boldTime: c.time_font_bold, boldTimezone: c.timezone_font_bold,
            colorDay: c.day_font_color, colorDate: c.date_font_color,
            colorTime: c.time_font_color, colorTimezone: c.timezone_font_color,
            dayFormat: c.day_format, dateFormat: c.date_format, timeFormat: c.time_format,
            use24HourFormat: c.use_24_hour_format, timeCharacter: c.time_character,
            uppercaseDay: c.uppercase_day, uppercaseDate: c.uppercase_date,
            locale: c.locale, elementOrder: c.element_order,
            colorMode: c.color_mode, adaptToTheme: c.adapt_to_theme,
            timezoneId: c.timezone_id, timezoneLabel: c.timezone_label,
            customDate: c.custom_preview_date
        });
    }

    // A single handler catches every config key change
    Connections {
        target: plasmoid.configuration
        function onValueChanged() { root.syncConfig(); }
    }

    // Wallpaper changed (watcher notification in C++)
    Connections {
        target: ModernRecClock.Wallpaper ?? null
        function onWallpaperChanged() { root.syncConfig(); }
    }

    // Theme colors changed
    Connections {
        target: Kirigami.Theme
        function onChanged() { clock.setThemeColors(themeText, themeBg); }
    }

    // ---- Optional widget alignment on screen (needs the containment) ----
    readonly property string alignMode: plasmoid.configuration.alignMode || "none"

    function applyAlignment() {
        if (alignMode === "none") return;
        var containment = plasmoid.containment;
        if (!containment) return;
        var g = containment.screenGeometry;
        var m = plasmoid.geometry;
        if (!g || !m || g.width <= 0 || m.width <= 0) return;
        var x = m.x, y = m.y;
        if (alignMode === "center") {
            x = Math.round((g.width - m.width) / 2);
            y = Math.round((g.height - m.height) / 2);
        } else if (alignMode === "centerH") {
            x = Math.round((g.width - m.width) / 2);
        } else if (alignMode === "centerV") {
            y = Math.round((g.height - m.height) / 2);
        }
        if (x !== m.x || y !== m.y)
            plasmoid.geometry = Qt.rect(x, y, m.width, m.height);
    }

    Component.onCompleted: {
        syncConfig();
        applyAlignment();
        try { plasmoid.containment.screenGeometryChanged.connect(applyAlignment); } catch (e) {}
    }

    // ---- Render: purely declarative, styles come from the model ----
    fullRepresentation: Item {
        id: container
        anchors.fill: parent

        readonly property bool isAutoScale: plasmoid.configuration.auto_scale

        // Hidden measurement column for auto-scale
        Column {
            id: metricsColumn
            visible: false
            spacing: plasmoid.configuration.widget_spacing
            Repeater {
                model: clock
                delegate: Text {
                    text: model.text
                    visible: model.visible
                    font.family: model.font
                    font.pixelSize: model.size
                    font.letterSpacing: model.spacing
                    font.bold: model.bold
                }
            }
        }

        readonly property real fontScale: isAutoScale ? Math.min((width - 16) / Math.max(1, metricsColumn.width),
                                                                 (height - 16) / Math.max(1, metricsColumn.height)) : 1.0

        Layout.minimumWidth: isAutoScale ? 50 : metricsColumn.width
        Layout.minimumHeight: isAutoScale ? 20 : metricsColumn.height
        Layout.preferredWidth: Layout.minimumWidth
        Layout.preferredHeight: Layout.minimumHeight

        Column {
            anchors.centerIn: parent
            spacing: plasmoid.configuration.widget_spacing * container.fontScale

            Repeater {
                model: clock
                delegate: Text {
                    visible: model.visible
                    text: model.text
                    font.family: model.font
                    font.pixelSize: Math.max(1, Math.round(model.size * container.fontScale))
                    font.letterSpacing: model.spacing * container.fontScale
                    font.bold: model.bold
                    color: model.color
                    anchors.horizontalCenter: parent.horizontalCenter
                    horizontalAlignment: Text.AlignHCenter
                    renderType: Text.CurveRendering
                }
            }
        }
    }
}
