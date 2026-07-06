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

    readonly property var log: ModernRecClock.Log
    readonly property var themeManager: ModernRecClock.ThemeManager
    readonly property bool _hasTheme: typeof PlasmaCore.Theme !== 'undefined' && PlasmaCore.Theme !== null
    readonly property color _themeText: _hasTheme && PlasmaCore.Theme.textColor ? PlasmaCore.Theme.textColor : "#FFFFFF"

    // Filter
    property string filterCategory: ""
    property string filterLevel: ""

    // Config keys for preview generation (shared from C++ ThemeManager)
    readonly property var configKeys: themeManager ? themeManager.configKeys : []

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

    function initDebugInfo() {
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

    Component.onCompleted: initDebugInfo()

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
                onClicked: { log.clear(); debugPage.initDebugInfo(); }
            }
            Item { Layout.fillWidth: true }
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
