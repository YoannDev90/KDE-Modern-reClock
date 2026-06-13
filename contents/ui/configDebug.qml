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

    // ===== cfg_* needed by diagnostic grid (read-only, not bound to controls) =====
    property string cfg_timezone_id: ""
    property string cfg_timezone_label: ""
    property string cfg_fontFamilyDay: "Anurati"
    property string cfg_fontFamilyDate: "Poppins"
    property string cfg_fontFamilyTime: "Poppins"
    property string cfg_color_mode: "custom"
    property color  cfg_day_font_color: "#FFFFFF"
    property color  cfg_date_font_color: "#FFFFFF"
    property color  cfg_time_font_color: "#FFFFFF"

    // Shorthand
    readonly property var log: ModernRecClock.Log
    // Theme color helpers (guarded for KCM context)
    readonly property bool _hasTheme: typeof PlasmaCore.Theme !== 'undefined' && PlasmaCore.Theme !== null
    readonly property color _themeText: _hasTheme && PlasmaCore.Theme.textColor ? PlasmaCore.Theme.textColor : "#FFFFFF"
    readonly property color _themeHighlight: _hasTheme && PlasmaCore.Theme.highlightColor ? PlasmaCore.Theme.highlightColor : "#3daee9"

    // ===== Filter =====
    property string filterCategory: ""
    property string filterLevel: ""

    // ===== Comprehensive Debug Dump =====
    // NOTE: No plasmoid.configuration here — KCM context. Config is in the log.
    function generateDebugDump() {
        var nl = "\n";
        var sep = "────────────────────────────────────────";
        var lines = [];

        // ── Header ──
        lines.push("═══ Modern reClock — Debug Dump ═══");
        lines.push("Generated: " + Qt.formatDateTime(new Date(), "yyyy-MM-dd hh:mm:ss"));
        lines.push("");

        // ── System ──
        lines.push(sep);
        lines.push("SYSTEM");
        lines.push(sep);
        lines.push("Qt version:     " + (typeof Qt.version !== 'undefined' ? Qt.version : "N/A"));
        lines.push("Platform:       " + (Qt.platform && Qt.platform.os ? Qt.platform.os : "N/A"));
        lines.push("Locale:         " + Qt.locale().name);
        lines.push("Screen:         " + Screen.width + "x" + Screen.height);
        lines.push("DPR:            " + Screen.devicePixelRatio);
        lines.push("Font families:  " + Qt.fontFamilies().length + " available");
        lines.push("");

        // ── Plugins ──
        lines.push(sep);
        lines.push("PLUGINS");
        lines.push(sep);
        lines.push("TimeZone:       " + (ModernRecClock.TimeZone !== undefined ? "loaded" : "NOT LOADED"));
        lines.push("Wallpaper:      " + (ModernRecClock.Wallpaper !== undefined ? "loaded" : "NOT LOADED"));
        lines.push("");

        // ── Theme colors ──
        lines.push(sep);
        lines.push("THEME COLORS");
        lines.push(sep);
        if (_hasTheme) {
            lines.push("Text color:     " + _themeText.toString());
            lines.push("Highlight:      " + _themeHighlight.toString());
            lines.push("Background:     " + (PlasmaCore.Theme.backgroundColor ? PlasmaCore.Theme.backgroundColor.toString() : "N/A"));
            lines.push("ButtonBg:       " + (PlasmaCore.Theme.buttonBackgroundColor ? PlasmaCore.Theme.buttonBackgroundColor.toString() : "N/A"));
            lines.push("ViewBg:         " + (PlasmaCore.Theme.viewBackgroundColor ? PlasmaCore.Theme.viewBackgroundColor.toString() : "N/A"));
        } else {
            lines.push("(Theme not available in KCM context)");
        }
        lines.push("");

        // ── Wallpaper ──
        lines.push(sep);
        lines.push("WALLPAPER");
        lines.push(sep);
        if (ModernRecClock.Wallpaper !== undefined) {
            try {
                var isDark = ModernRecClock.Wallpaper.isDarkColorScheme();
                lines.push("Color scheme:   " + (isDark ? "dark" : "light"));
                var wpPath = ModernRecClock.Wallpaper.wallpaperPath();
                lines.push("Path:           " + (wpPath || "(not found)"));
                if (wpPath && wpPath.length > 0) {
                    var b = ModernRecClock.Wallpaper.wallpaperBrightness(wpPath);
                    lines.push("Brightness:     " + b);
                } else {
                    lines.push("Brightness:     N/A (no path)");
                }
            } catch (e) {
                lines.push("Error:          " + e.message);
            }
        } else {
            lines.push("(WallpaperHelper not available)");
        }
        lines.push("");

        // ── System fonts (first 30) ──
        lines.push(sep);
        lines.push("SYSTEM FONTS (first 30)");
        lines.push(sep);
        var fonts = Qt.fontFamilies();
        var fontLimit = Math.min(fonts.length, 30);
        for (var fi = 0; fi < fontLimit; fi++) {
            lines.push("  " + fonts[fi]);
        }
        if (fonts.length > 30) {
            lines.push("  ... and " + (fonts.length - 30) + " more");
        }
        lines.push("");

        // ── Log history (contains all config + computed values from main.qml startup) ──
        lines.push(sep);
        lines.push("LOG HISTORY (" + (debugPage.log ? debugPage.log.count : 0) + " entries)");
        lines.push(sep);
        lines.push("(Config, computed values, and element details are in the log below)");
        lines.push("");
        if (debugPage.log) {
            lines.push(debugPage.log.exportText());
        }
        lines.push("");

        lines.push("═══ End of Debug Dump ═══");
        return lines.join(nl);
    }

    // ===== Collect System Info on Open =====
    Component.onCompleted: {
        log.info("system", "═══ Debug panel opened ═══");
        log.info("system", "Qt " + (typeof Qt.version !== 'undefined' ? Qt.version : "N/A") + " • " + (Qt.platform && Qt.platform.os ? Qt.platform.os : "N/A"));
        log.info("system", "Locale: " + Qt.locale().name);
        log.info("system", "Screen: " + Screen.width + "x" + Screen.height + " @ " + Screen.devicePixelRatio + "x DPR");
        log.info("system", "Font families: " + Qt.fontFamilies().length + " available");
        log.info("system", "Theme text: " + (_hasTheme ? _themeText.toString() : "N/A"));
        log.info("system", "Theme highlight: " + (_hasTheme ? _themeHighlight.toString() : "N/A"));

        // Plugin status
        var tzLoaded = ModernRecClock.TimeZone !== undefined;
        var wpLoaded = ModernRecClock.Wallpaper !== undefined;
        log.info("system", "TimeZone: " + (tzLoaded ? "loaded" : "NOT loaded"));
        log.info("system", "Wallpaper: " + (wpLoaded ? "loaded" : "NOT loaded"));

        // Wallpaper info
        if (wpLoaded) {
            try {
                var isDark = ModernRecClock.Wallpaper.isDarkColorScheme();
                log.info("wallpaper", "Color scheme: " + (isDark ? "dark" : "light"));
                var wpPath = ModernRecClock.Wallpaper.wallpaperPath();
                log.info("wallpaper", "Path: " + (wpPath || "(not found)"));
                if (wpPath && wpPath.length > 0) {
                    var b = ModernRecClock.Wallpaper.wallpaperBrightness(wpPath);
                    log.info("wallpaper", "Brightness: " + b);
                }
            } catch (e) {
                log.error("wallpaper", "Failed: " + e.message);
            }
        }

        // Timezone live test
        if (tzLoaded) {
            try {
                var ids = ModernRecClock.TimeZone.availableTimeZoneIds();
                log.info("timezone", "Available IDs: " + ids.length);
            } catch (e) {
                log.error("timezone", "List failed: " + e.message);
            }
        }

        log.info("system", "═══ Debug ready — use 'Copy Debug Info' ═══");
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

        // Hidden TextArea for clipboard copy (Qt.application.clipboard unavailable in KCM)
        QQC2.TextArea {
            id: _copyHelper
            visible: false
            selectByMouse: true
        }

        // ================= SECTION: QUICK COPY =================
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.Button {
                text: i18n("Copy Debug Info")
                icon.name: "edit-copy"
                Layout.fillWidth: true
                onClicked: {
                    try {
                        var dump = debugPage.generateDebugDump();
                        _copyHelper.text = dump;
                        _copyHelper.selectAll();
                        _copyHelper.copy();
                        log.info("system", "Debug dump copied (" + dump.length + " chars)");
                    } catch (e) {
                        log.error("system", "Copy failed: " + e.message);
                    }
                }
            }
            QQC2.Button {
                text: i18n("Copy Log Only")
                icon.name: "edit-copy"
                onClicked: {
                    try {
                        var txt = debugPage.log.exportText();
                        _copyHelper.text = txt;
                        _copyHelper.selectAll();
                        _copyHelper.copy();
                        log.info("system", "Log copied (" + txt.length + " chars)");
                    } catch (e) {
                        log.error("system", "Copy failed: " + e.message);
                    }
                }
            }
            QQC2.Button {
                text: i18n("Refresh")
                icon.name: "view-refresh"
                onClicked: {
                    log.clear();
                    debugPage.Component.onCompleted();
                }
            }
        }

        // ================= SECTION: DIAGNOSTIC =================
        Kirigami.Heading {
            text: i18n("Diagnostic")
            level: 2
            Layout.fillWidth: true
            Kirigami.FormData.isSection: true
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: Kirigami.Units.largeSpacing
            rowSpacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: "info"
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
            }
            QQC2.Label {
                text: "<b>Qt:</b> " + Qt.version + "  •  <b>Platform:</b> " + Qt.platform.os
                textFormat: Text.RichText
            }

            Kirigami.Icon {
                source: ModernRecClock.TimeZone !== undefined && ModernRecClock.Wallpaper !== undefined ? "dialog-ok" : "dialog-error"
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
            }
            QQC2.Label {
                text: {
                    var tz = ModernRecClock.TimeZone !== undefined ? "✓" : "✗";
                    var wp = ModernRecClock.Wallpaper !== undefined ? "✓" : "✗";
                    return "<b>Plugins:</b> TimeZone: " + tz + "  •  Wallpaper: " + wp;
                }
                textFormat: Text.RichText
            }

            Kirigami.Icon {
                source: "color-black"
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
            }
            QQC2.Label {
                text: "<b>Theme:</b> text=" + (_hasTheme ? _themeText.toString() : "N/A") + "  •  highlight=" + (_hasTheme ? _themeHighlight.toString() : "N/A")
                textFormat: Text.RichText
            }

            Kirigami.Icon {
                source: "folder-pictures"
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
            }
            QQC2.Label {
                text: {
                    var path = "";
                    try { path = ModernRecClock.Wallpaper.wallpaperPath(); } catch (e) {}
                    return "<b>Wallpaper:</b> " + (path || "(not found)");
                }
                textFormat: Text.RichText
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Kirigami.Icon {
                source: "clock"
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
            }
            QQC2.Label {
                text: {
                    var tzId = cfg_timezone_id || "";
                    var tzLabel = cfg_timezone_label || "";
                    var result = "<b>Timezone:</b> ";
                    if (tzId.length === 0) return result + "(not configured)";
                    result += tzId;
                    if (tzLabel.length > 0) result += " (" + tzLabel + ")";
                    return result;
                }
                textFormat: Text.RichText
            }

            Kirigami.Icon {
                source: "font"
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
            }
            QQC2.Label {
                text: "<b>Fonts:</b> Day=" + (cfg_fontFamilyDay || "Anurati") + "  Date=" + (cfg_fontFamilyDate || "Poppins") + "  Time=" + (cfg_fontFamilyTime || "Poppins")
                textFormat: Text.RichText
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Kirigami.Icon {
                source: "draw-text"
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
            }
            QQC2.Label {
                text: "<b>Colors:</b> mode=" + (cfg_color_mode || "custom") + "  day=" + (cfg_day_font_color || "#FFF") + "  date=" + (cfg_date_font_color || "#FFF") + "  time=" + (cfg_time_font_color || "#FFF")
                textFormat: Text.RichText
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        // ================= SECTION: LOG =================
        Kirigami.Heading {
            text: i18n("Live Log")
            level: 2
            Layout.fillWidth: true
            Kirigami.FormData.isSection: true
        }

        // Filter bar
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.ComboBox {
                id: categoryFilter
                Layout.preferredWidth: 140
                model: ["All", "system", "clock", "timezone", "wallpaper", "config", "theme"]
                onCurrentTextChanged: debugPage.filterCategory = currentText === "All" ? "" : currentText
            }
            QQC2.ComboBox {
                id: levelFilter
                Layout.preferredWidth: 120
                model: ["All", "debug", "info", "warn", "error"]
                onCurrentTextChanged: debugPage.filterLevel = currentText === "All" ? "" : currentText
            }
            Item { Layout.fillWidth: true }
            QQC2.Label {
                text: i18n("%1 entries", debugPage.log ? debugPage.log.count : 0)
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.6
            }
            QQC2.Button {
                icon.name: "edit-clear"
                onClicked: debugPage.log.clear()
                QQC2.ToolTip.text: i18n("Clear log")
                QQC2.ToolTip.visible: hovered
            }
            QQC2.Button {
                icon.name: "document-save"
                onClicked: {
                    var path = "/tmp/modernreclock_log_export.txt";
                    if (debugPage.log.exportLogsToFile(path)) {
                        log.info("system", "Logs exported to: " + path);
                        _logExportLabel.text = i18n("Exported to %1", path);
                    } else {
                        log.error("system", "Failed to export logs");
                        _logExportLabel.text = i18n("Export failed!");
                    }
                }
                QQC2.ToolTip.text: i18n("Export logs to file")
                QQC2.ToolTip.visible: hovered
            }
            QQC2.Label {
                id: _logExportLabel
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.6
                visible: text.length > 0
            }
        }

        // Log list
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
                        return true
                    }
                    height: visible ? implicitHeight : 0
                    text: {
                        var ts = Qt.formatDateTime(model.timestamp, "hh:mm:ss");
                        return ts + " [" + model.category.toUpperCase() + "/" + model.level.toUpperCase() + "] " + model.message;
                    }
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

        // ================= SECTION: PLASMA SHELL LOGS =================
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
                    log.info("system", "Fetching Plasma Shell logs asynchronously...");
                    ModernRecClock.Log.fetchPlasmaLogsAsync(300);
                }
            }

            Connections {
                target: ModernRecClock.Log
                function onPlasmaLogsFetched(result) {
                    plasmaLogText.text = result || "(empty)";
                    log.info("system", "Async logs fetched (" + (result ? result.length : 0) + " chars)");
                }
            }
            QQC2.Button {
                text: i18n("Copy")
                icon.name: "edit-copy"
                onClicked: {
                    _copyHelper.text = plasmaLogText.text;
                    _copyHelper.selectAll();
                    _copyHelper.copy();
                    log.info("system", "Plasma Shell logs copied");
                }
            }
            Item { Layout.fillWidth: true }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 250
            Layout.minimumHeight: 100
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
