import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Window

import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.modernreclock as ModernRecClock

KCM.SimpleKCM {
    id: debugPage

    property string cfg_timezone_id: ""
    property string cfg_timezone_label: ""
    property string cfg_fontFamilyDay: "Anurati"
    property string cfg_fontFamilyDate: "Poppins"
    property string cfg_fontFamilyTime: "Poppins"
    property string cfg_color_mode: "custom"
    property color  cfg_day_font_color: "#FFFFFF"
    property color  cfg_date_font_color: "#FFFFFF"
    property color  cfg_time_font_color: "#FFFFFF"

    readonly property var log: ModernRecClock.Log
    readonly property var themeManager: ModernRecClock.ThemeManager
    readonly property bool _hasTheme: typeof PlasmaCore.Theme !== 'undefined' && PlasmaCore.Theme !== null
    readonly property color _themeText: _hasTheme && PlasmaCore.Theme.textColor ? PlasmaCore.Theme.textColor : "#FFFFFF"

    // Filter
    property string filterCategory: ""
    property string filterLevel: ""

    // Config keys for preview generation
    readonly property var configKeys: [
        "show_day", "show_date", "show_time", "show_custom", "show_timezone",
        "day_font_size", "date_font_size", "time_font_size", "custom_font_size", "timezone_font_size",
        "day_letter_spacing", "date_letter_spacing", "time_letter_spacing", "custom_letter_spacing", "timezone_letter_spacing",
        "day_font_color", "date_font_color", "time_font_color", "custom_font_color", "timezone_font_color",
        "day_font_bold", "date_font_bold", "time_font_bold", "custom_font_bold", "timezone_font_bold",
        "day_format", "date_format", "time_format", "timezone_format", "time_character",
        "use_24_hour_format", "uppercase_day", "uppercase_date", "custom_format", "custom_text",
        "fontFamilyDay", "fontFamilyDate", "fontFamilyTime", "fontFamilyCustom", "fontFamilyTimezone",
        "widget_spacing", "element_order", "auto_scale", "color_mode", "locale",
        "timezone_id", "timezone_label", "timezone_display_text"
    ]

    function getExportConfig() {
        let cfg = {};
        // Read from plasmoid.configuration directly (available in KCM context)
        var plasCfg = (typeof plasmoid !== 'undefined' && plasmoid) ? plasmoid.configuration : null;
        configKeys.forEach(function(k) {
            // Try plasmoid.configuration first, then debugPage cfg_ properties
            var val = plasCfg ? plasCfg[k] : undefined;
            if (val === undefined || val === null) val = debugPage["cfg_" + k];
            if (val !== undefined && val !== null) cfg[k] = val;
        });
        return JSON.stringify(cfg, null, 4);
    }

    function generateDebugDump() {
        var nl = "\n";
        var sep = "────────────────────────────────────────";
        var lines = [];

        lines.push("═══ Modern reClock — Debug Dump ═══");
        lines.push("Generated: " + Qt.formatDateTime(new Date(), "yyyy-MM-dd hh:mm:ss"));
        lines.push("");

        lines.push(sep + nl + "SYSTEM" + nl + sep);
        lines.push("Qt: " + (typeof Qt.version !== 'undefined' ? Qt.version : "N/A") + "  Platform: " + (Qt.platform && Qt.platform.os ? Qt.platform.os : "N/A"));
        lines.push("Locale: " + Qt.locale().name + "  Screen: " + Screen.width + "x" + Screen.height + " @ " + Screen.devicePixelRatio + "x");
        lines.push("");

        lines.push(sep + nl + "PLUGINS" + nl + sep);
        lines.push("TimeZone: " + (ModernRecClock.TimeZone !== undefined ? "loaded" : "NOT LOADED"));
        lines.push("Wallpaper: " + (ModernRecClock.Wallpaper !== undefined ? "loaded" : "NOT LOADED"));
        lines.push("");

        if (_hasTheme) {
            lines.push(sep + nl + "THEME" + nl + sep);
            lines.push("Text: " + _themeText.toString());
            lines.push("Background: " + (PlasmaCore.Theme.backgroundColor ? PlasmaCore.Theme.backgroundColor.toString() : "N/A"));
            lines.push("");
        }

        if (ModernRecClock.Wallpaper !== undefined) {
            var wpPath = "";
            try { wpPath = ModernRecClock.Wallpaper.wallpaperPath(); } catch (e) {}
            lines.push(sep + nl + "WALLPAPER" + nl + sep);
            lines.push("Path: " + (wpPath || "(not found)"));
            if (wpPath) {
                try { lines.push("Brightness: " + ModernRecClock.Wallpaper.wallpaperBrightness(wpPath)); } catch (e) {}
            }
            lines.push("");
        }

        lines.push(sep + nl + "LOG HISTORY (" + (debugPage.log ? debugPage.log.count : 0) + " entries)" + nl + sep);
        if (debugPage.log) lines.push(debugPage.log.exportText());

        lines.push("");
        lines.push("═══ End of Debug Dump ═══");
        return lines.join(nl);
    }

    Component.onCompleted: {
        log.info("system", "═══ Debug panel opened ═══");
        log.info("system", "Qt " + (typeof Qt.version !== 'undefined' ? Qt.version : "N/A") + " • " + (Qt.platform && Qt.platform.os ? Qt.platform.os : "N/A"));
        log.info("system", "Locale: " + Qt.locale().name + "  Screen: " + Screen.width + "x" + Screen.height + " @ " + Screen.devicePixelRatio + "x DPR");
        log.info("system", "Font families: " + Qt.fontFamilies().length + " available");

        var tz = ModernRecClock.TimeZone !== undefined;
        var wp = ModernRecClock.Wallpaper !== undefined;
        log.info("system", "TimeZone: " + (tz ? "loaded" : "NOT loaded") + "  Wallpaper: " + (wp ? "loaded" : "NOT loaded"));

        if (wp) try {
            var wpPath = ModernRecClock.Wallpaper.wallpaperPath();
            log.info("wallpaper", "Path: " + (wpPath || "(not found)"));
            if (wpPath) log.info("wallpaper", "Brightness: " + ModernRecClock.Wallpaper.wallpaperBrightness(wpPath));
        } catch (e) { log.error("wallpaper", "Failed: " + e.message); }

        if (tz) try {
            log.info("timezone", "Available IDs: " + ModernRecClock.TimeZone.availableTimeZoneIds().length);
        } catch (e) { log.error("timezone", "List failed: " + e.message); }

        log.info("system", "═══ Debug ready ═══");
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        QQC2.TextArea { id: _copyHelper; visible: false; selectByMouse: true }

        // Toolbar
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.Button {
                text: i18n("Copy Debug Info")
                icon.name: "edit-copy"
                onClicked: {
                    _copyHelper.text = debugPage.generateDebugDump();
                    _copyHelper.selectAll();
                    _copyHelper.copy();
                }
            }
            QQC2.Button {
                text: i18n("Copy Log Only")
                icon.name: "edit-copy"
                onClicked: {
                    _copyHelper.text = debugPage.log.exportText();
                    _copyHelper.selectAll();
                    _copyHelper.copy();
                }
            }
            QQC2.Button {
                text: i18n("Refresh")
                icon.name: "view-refresh"
                onClicked: { log.clear(); debugPage.Component.onCompleted(); }
            }
            Item { Layout.fillWidth: true }
        }

        // ================= SECTION: PREVIEW GENERATOR =================
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.Label { text: i18n("Day:"); font.bold: true }
            QQC2.ComboBox {
                id: dayCombo
                model: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
                currentIndex: 2 // Wednesday
            }
            QQC2.Label { text: i18n("Month:"); font.bold: true }
            QQC2.ComboBox {
                id: monthCombo
                model: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
                currentIndex: 6 // July
            }
            QQC2.SpinBox {
                id: yearSpin
                from: 2024; to: 2030; value: 2026
            }
            Item { Layout.fillWidth: true }
            QQC2.Button {
                text: i18n("Generate Preview")
                icon.name: "image-generate"
                onClicked: {
                    log.info("theme", "Manual preview generation started");
                    var cfgJson = debugPage.getExportConfig();
                    var wpPath = ModernRecClock.Wallpaper ? (ModernRecClock.Wallpaper.wallpaperPath() || "") : "";
                    // Build custom date ISO string: 2026-07-06
                    var month = (monthCombo.currentIndex + 1).toString().padStart(2, '0');
                    var customDate = yearSpin.value + "-" + month + "-01";
                    log.info("theme", "Preview date: " + customDate + " (" + dayCombo.currentText + ")");
                    var result = themeManager.generatePreview(cfgJson, wpPath, -1, [], customDate);
                    if (result) {
                        previewImage.source = "file://" + result + "?t=" + Date.now();
                        log.info("theme", "Preview generated: " + result);
                    } else {
                        log.error("theme", "Preview generation failed");
                    }
                }
            }
            QQC2.Label {
                text: i18n("Preview will appear below")
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.5
            }
            Item { Layout.fillWidth: true }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 300
            Layout.minimumHeight: 150
            color: Qt.rgba(0, 0, 0, 0.4)
            radius: Kirigami.Units.cornerRadius
            clip: true

            Image {
                id: previewImage
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing
                fillMode: Image.PreserveAspectFit
                asynchronous: true

                QQC2.BusyIndicator {
                    anchors.centerIn: parent
                    running: previewImage.status === Image.Loading
                }

                QQC2.Label {
                    anchors.centerIn: parent
                    text: i18n("Click 'Generate Preview' to render the clock on wallpaper")
                    color: Kirigami.Theme.disabledTextColor
                    visible: previewImage.status !== Image.Ready
                }
            }
        }

        // Log toolbar: filter + count + clear + export
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.ComboBox {
                id: categoryFilter
                Layout.preferredWidth: 120
                model: ["All", "system", "clock", "timezone", "wallpaper", "config", "theme", "export"]
                onCurrentTextChanged: debugPage.filterCategory = currentText === "All" ? "" : currentText
            }
            QQC2.ComboBox {
                id: levelFilter
                Layout.preferredWidth: 100
                model: ["All", "debug", "info", "warn", "error"]
                onCurrentTextChanged: debugPage.filterLevel = currentText === "All" ? "" : currentText
            }
            QQC2.Label {
                text: i18n("%1 entries", debugPage.log ? debugPage.log.count : 0)
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.6
            }
            Item { Layout.fillWidth: true }
            QQC2.Button {
                icon.name: "edit-clear"
                QQC2.ToolTip.text: i18n("Clear log")
                QQC2.ToolTip.visible: hovered
                onClicked: debugPage.log.clear()
            }
            QQC2.Button {
                icon.name: "document-save"
                QQC2.ToolTip.text: i18n("Export logs to file")
                QQC2.ToolTip.visible: hovered
                onClicked: {
                    var p = "/tmp/modernreclock_log_export.txt";
                    if (debugPage.log.exportLogsToFile(p))
                        log.info("system", "Logs exported to: " + p);
                    else
                        log.error("system", "Failed to export logs");
                }
            }
        }

        // Live log (takes remaining space)
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Qt.rgba(0, 0, 0, 0.4)
            radius: Kirigami.Units.cornerRadius

            ListView {
                id: logView
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing
                model: debugPage.log ? debugPage.log.model : null
                clip: true
                spacing: 1
                onCountChanged: positionViewAtEnd()

                delegate: QQC2.Label {
                    width: logView.width
                    visible: {
                        if (debugPage.filterCategory !== "" && model.category !== debugPage.filterCategory) return false;
                        if (debugPage.filterLevel !== "" && model.level !== debugPage.filterLevel) return false;
                        return true;
                    }
                    height: visible ? implicitHeight : 0
                    text: Qt.formatDateTime(model.timestamp, "hh:mm:ss") + " [" + model.category.toUpperCase() + "/" + model.level.toUpperCase() + "] " + model.message
                    font.family: "Monospace"
                    font.pixelSize: 11
                    color: model.level === "error" ? Kirigami.Theme.negativeTextColor
                         : model.level === "warn" ? "#FFD700"
                         : Kirigami.Theme.textColor
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                }

                QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                    parent: logView.parent
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                }
            }
        }

        // Plasma Shell Logs
        Kirigami.Heading {
            text: i18n("Plasma Shell Logs")
            level: 2
            Layout.fillWidth: true
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.Button {
                text: i18n("Fetch Logs")
                icon.name: "view-refresh"
                onClicked: {
                    plasmaLogText.text = i18n("Loading...");
                    ModernRecClock.Log.fetchPlasmaLogsAsync(300);
                }
            }
            Connections {
                target: ModernRecClock.Log
                function onPlasmaLogsFetched(result) { plasmaLogText.text = result || "(empty)"; }
            }
            QQC2.Button {
                text: i18n("Copy")
                icon.name: "edit-copy"
                onClicked: { _copyHelper.text = plasmaLogText.text; _copyHelper.selectAll(); _copyHelper.copy(); }
            }
            Item { Layout.fillWidth: true }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 180
            Layout.minimumHeight: 80
            color: Qt.rgba(0, 0, 0, 0.4)
            radius: Kirigami.Units.cornerRadius

            QQC2.ScrollView {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing
                QQC2.TextArea {
                    id: plasmaLogText
                    readOnly: true
                    wrapMode: TextEdit.Wrap
                    font.family: "Monospace"
                    font.pixelSize: 11
                    color: Kirigami.Theme.textColor
                    background: null
                    text: i18n("Click 'Fetch Logs' to load Plasma Shell journal logs.")
                }
            }
        }
    }
}
