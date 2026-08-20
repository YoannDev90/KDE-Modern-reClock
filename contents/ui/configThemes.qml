import QtQml
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Dialogs as Dialogs

import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.modernreclock as ModernRecClock

KCM.SimpleKCM {
    id: themesPage

    readonly property var log: ModernRecClock.Log ?? ({
        debug: function(cat, msg) {},
        info: function(cat, msg) {},
        warn: function(cat, msg) {},
        error: function(cat, msg) {}
    })
    readonly property var themeManager: ModernRecClock.ThemeManager ?? null

    // ===== Config keys — plain properties (no hidden controls needed) =====
    property bool cfg_show_day: true
    property bool cfg_show_date: true
    property bool cfg_show_time: true
    property bool cfg_show_custom: false
    property bool cfg_show_timezone: false

    property int cfg_day_font_size: 72
    property int cfg_date_font_size: 19
    property int cfg_time_font_size: 19
    property int cfg_custom_font_size: 19
    property int cfg_timezone_font_size: 19

    property int cfg_day_letter_spacing: 17
    property int cfg_date_letter_spacing: 3
    property int cfg_time_letter_spacing: 3
    property int cfg_custom_letter_spacing: 3
    property int cfg_timezone_letter_spacing: 3

    property string cfg_day_font_color: "#FFFFFF"
    property string cfg_date_font_color: "#FFFFFF"
    property string cfg_time_font_color: "#FFFFFF"
    property string cfg_custom_font_color: "#FFFFFF"
    property string cfg_timezone_font_color: "#FFFFFF"

    property bool cfg_day_font_bold: false
    property bool cfg_date_font_bold: false
    property bool cfg_time_font_bold: false
    property bool cfg_custom_font_bold: false
    property bool cfg_timezone_font_bold: false

    property string cfg_day_format: "dddd"
    property string cfg_date_format: "dd MMM yyyy"
    property string cfg_time_format: ""
    property string cfg_timezone_format: "HH:mm"
    property string cfg_time_character: "-"
    property bool cfg_use_24_hour_format: false
    property bool cfg_uppercase_day: true
    property bool cfg_uppercase_date: true
    property bool cfg_custom_format: false
    property string cfg_custom_text: ""

    property string cfg_fontFamilyDay: "Anurati"
    property string cfg_fontFamilyDate: "Poppins"
    property string cfg_fontFamilyTime: "Poppins"
    property string cfg_fontFamilyCustom: "Poppins"
    property string cfg_fontFamilyTimezone: "Poppins"

    property int cfg_widget_spacing: 5
    property string cfg_element_order: "day,date,time,custom,timezone"
    property bool cfg_auto_scale: false
    property string cfg_color_mode: "custom"
    property string cfg_locale: ""

    property string cfg_saved_themes: ""
    property string cfg_timezone_id: ""
    property string cfg_timezone_label: ""
    property string cfg_timezone_display_text: ""

    // ===== Config key list (shared from C++ ThemeManager) =====
    readonly property var configKeys: themeManager ? themeManager.configKeys : []

    // Keys excluded from theme export (location-specific or user-specific)
    readonly property var exportExclude: [
        "timezone_id", "timezone_label", "timezone_display_text",
        "custom_text", "locale", "saved_themes"
    ]

    function getExportConfig() {
        let cfg = {};
        configKeys.forEach(function(k) {
            if (exportExclude.indexOf(k) === -1)
                cfg[k] = themesPage["cfg_" + k];
        });
        return JSON.stringify(cfg, null, 4);
    }

    function applyConfig(jsonString) {
        try {
            let cfg = JSON.parse(jsonString);
            var count = 0;
            for (let k in cfg) {
                if (configKeys.indexOf(k) !== -1) {
                    themesPage["cfg_" + k] = cfg[k];
                    count++;
                }
            }
            log.info("themes", "applyConfig: applied " + count + " keys from JSON");
            return true;
        } catch (e) {
            log.error("themes", "applyConfig failed: " + e.message);
            return false;
        }
    }

    // ===== Community gallery state =====
    property var communityThemes: []
    property bool indexLoaded: false
    property string indexError: ""
    property var embedFontPaths: []

    // Preview dialog state
    property var previewThemeData: ({})

    // Export dialog state
    property string exportThemeName: ""
    property string exportThemeDesc: ""
    property string exportThemeAuthor: ""

    // Feedback
    property string importError: ""
    property string exportError: ""
    property bool previewGenerating: false

    // Font families from config (auto-detected for export)
    property var themeFontKeys: ["fontFamilyDay", "fontFamilyDate", "fontFamilyTime", "fontFamilyCustom", "fontFamilyTimezone"]
    // Bundled fonts shipped with the widget
    property var bundledFonts: [
        Qt.resolvedUrl("../fonts/Anurati.otf").toString().replace("file://", ""),
        Qt.resolvedUrl("../fonts/Poppins.ttf").toString().replace("file://", "")
    ]

    function detectFontFamilies() {
        var families = [];
        var seen = {};
        for (var i = 0; i < themesPage.themeFontKeys.length; i++) {
            var key = themesPage.themeFontKeys[i];
            var family = themesPage["cfg_" + key];
            if (!family || family.trim() === "") continue;
            var f = family.trim();
            if (!seen[f]) {
                seen[f] = true;
                families.push(f);
            }
        }
        return families;
    }

    function resolveFontPathsFromConfig() {
        var families = themesPage.detectFontFamilies();
        var paths = [];
        var seen = {};
        for (var i = 0; i < families.length; i++) {
            var p = themeManager.resolveFontPath(families[i]);
            if (p && !seen[p]) { seen[p] = true; paths.push(p); }
            log.debug("themes", "resolveFont '" + families[i] + "' → " + (p || "NOT FOUND"));
        }
        for (var i = 0; i < themesPage.bundledFonts.length; i++) {
            var f = themesPage.bundledFonts[i];
            if (f && !seen[f]) { seen[f] = true; paths.push(f); log.debug("themes", "bundled font: " + f); }
        }
        return paths;
    }

    Component.onCompleted: {
        log.info("themes", "Themes page opened");
        themeManager.restorePersistedFonts();
        themeManager.fetchIndex();
    }

    // ===== Network callbacks =====
    Connections {
        target: themeManager
        function onIndexFetchComplete(success, jsonData) {
            if (success && jsonData) {
                try {
                    themesPage.communityThemes = JSON.parse(jsonData);
                    themesPage.indexLoaded = true;
                    themesPage.indexError = "";
                    log.info("themes", "Loaded " + themesPage.communityThemes.length + " community themes");
                } catch (e) {
                    themesPage.indexError = e.message;
                }
            } else {
                themesPage.indexError = i18n("Failed to fetch theme index");
                log.error("gallery", "Index fetch failed");
            }
        }

        function onThemeDownloaded(themeId, success) {
            if (success) {
                var themePath = themeManager.cachedThemePath(themeId);
                var jsonStr = themeManager.parseTheme(themePath);
                if (jsonStr) {
                    themesPage.applyConfig(jsonStr);
                    log.info("themes", "Applied community theme: " + themeId);
                }
            } else {
                themesPage.indexError = i18n("Failed to download theme. Check your connection.");
                log.error("themes", "Theme download failed: " + themeId);
            }
        }

        function onErrorOccurred(message) {
            themesPage.indexError = message;
            log.error("themes", "ThemeManager error: " + message);
        }
    }

    // ===== Deferred heavy content — loaded async to speed up page creation =====
    Loader {
        anchors.fill: parent
        active: true
        asynchronous: true
        sourceComponent: Component {
            Item {
                anchors.fill: parent

    // ===== File dialogs =====
    Dialogs.FileDialog {
        id: importFileDialog
        title: i18n("Import Theme")
        fileMode: Dialogs.FileDialog.OpenFile
        nameFilters: [i18n("Modern reClock Theme (*.zip *.mrt)")]
        onAccepted: {
            var filePath = importFileDialog.selectedFile.toString().replace("file://", "");
            var jsonStr = themeManager.parseTheme(filePath);
            if (jsonStr) {
                themesPage.applyConfig(jsonStr);
                log.info("themes", "Theme imported from: " + filePath);
            } else {
                themesPage.importError = i18n("Failed to parse theme file. It may be corrupted.");
                log.error("themes", "Failed to parse theme file");
            }
        }
    }

    Dialogs.FileDialog {
        id: fontFileDialog
        title: i18n("Select Font File")
        fileMode: Dialogs.FileDialog.OpenFile
        nameFilters: [i18n("Font files (*.ttf *.otf)")]
        onAccepted: {
            var path = fontFileDialog.selectedFile.toString().replace("file://", "");
            log.debug("themes", "Font added: " + path);
            var paths = themesPage.embedFontPaths.slice();
            paths.push(path);
            themesPage.embedFontPaths = paths;
        }
    }

    // ===== Preview Dialog =====
    QQC2.Dialog {
        id: previewDialog
        title: themesPage.previewThemeData.name || i18n("Theme Preview")
        modal: true
        anchors.centerIn: parent
        standardButtons: QQC2.Dialog.Cancel | QQC2.Dialog.Apply
        implicitWidth: Kirigami.Units.gridUnit * 28

        onAccepted: {
            var d = themesPage.previewThemeData;
            if (d.mrt_url) {
                log.info("gallery", "Download theme: " + d.id + " from " + d.mrt_url);
                themeManager.downloadTheme(d.id, d.mrt_url);
            }
            previewDialog.close();
        }

        contentItem: ColumnLayout {
            spacing: Kirigami.Units.largeSpacing

            Image {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 12
                fillMode: Image.PreserveAspectFit
                source: themesPage.previewThemeData.preview_url || ""
                asynchronous: true
                clip: true

                QQC2.BusyIndicator {
                    anchors.centerIn: parent
                    running: parent.status === Image.Loading
                }
            }

            Kirigami.Heading {
                text: themesPage.previewThemeData.name || ""
                level: 3
                Layout.fillWidth: true
            }

            QQC2.Label {
                text: (themesPage.previewThemeData.author || "") +
                      (themesPage.previewThemeData.version ? " v" + themesPage.previewThemeData.version : "")
                opacity: 0.6
                Layout.fillWidth: true
            }

            QQC2.Label {
                text: themesPage.previewThemeData.description || ""
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            // Fonts info
            Repeater {
                model: {
                    var d = themesPage.previewThemeData;
                    if (!d.fonts_required || d.fonts_required.length === 0) return [];
                    var result = [];
                    for (var i = 0; i < d.fonts_required.length; i++) {
                        var family = d.fonts_required[i];
                        var families = Qt.fontFamilies();
                        var available = families.indexOf(family) !== -1;
                        result.push({family: family, available: available});
                    }
                    return result;
                }
                RowLayout {
                    spacing: Kirigami.Units.smallSpacing
                    QQC2.Label {
                        text: modelData.available ? "✓" : "⚠"
                        color: modelData.available ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                        font.bold: true
                    }
                    QQC2.Label {
                        text: modelData.family
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                    }
                    QQC2.Label {
                        text: modelData.available ? i18n("installed") : i18n("not found")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.5
                    }
                }
            }
        }
    }

    // ===== Export Dialog =====
    QQC2.Dialog {
        id: exportDialog
        title: i18n("Export Theme")
        modal: true
        anchors.centerIn: parent
        standardButtons: QQC2.Dialog.Cancel | QQC2.Dialog.Save
        implicitWidth: Kirigami.Units.gridUnit * 28

        onOpened: {
            themesPage.exportThemeName = "";
            themesPage.exportThemeDesc = "";
            themesPage.exportThemeAuthor = "";
            log.info("export", "Export dialog opened, generating preview");
            var cfgJson = themesPage.getExportConfig();
            var wpPath = ModernRecClock.Wallpaper ? (ModernRecClock.Wallpaper.wallpaperPath() || "") : "";
            // Try to get widget geometry from plasmoid context
            var aid = -1;
            try {
                if (typeof plasmoid !== 'undefined' && plasmoid) {
                    // Check containment for applet geometry
                    if (plasmoid.containment) {
                        var ckeys = [];
                        for (var k in plasmoid.containment) ckeys.push(k);
                        log.info("export", "containment props: " + ckeys.join(", "));
                    }
                    // Try pluginName for identification
                    if (plasmoid.pluginName) log.info("export", "pluginName: " + plasmoid.pluginName);
                    // Try id property
                    log.info("export", "plasmoid.id type=" + typeof plasmoid.id + " val=" + plasmoid.id);
                }
            } catch(e) { log.error("export", "plasmoid error: " + e.message); }
            log.info("export", "AppletId: " + aid);
            var fonts = themesPage.resolveFontPathsFromConfig();
            log.info("export", "Fonts: " + JSON.stringify(fonts));
            themesPage.exportError = "";
            themesPage.previewGenerating = true;
            var result = themeManager.generatePreview(cfgJson, wpPath, aid, fonts);
            themesPage.previewGenerating = false;
            if (!result || result.length === 0) {
                themesPage.exportError = i18n("Preview generation failed. The .zip will still be created.");
            }
            log.info("export", "Preview: " + (result || "(failed)"));
        }

        onAccepted: {
            var configJson = themesPage.getExportConfig();
            var reqFonts = themesPage.detectFontFamilies();
            // Wrap config in theme.json format
            var themeJson = JSON.stringify({
                mrt_version: 1,
                name: themesPage.exportThemeName || "My Theme",
                author: themesPage.exportThemeAuthor || "",
                version: "1.0",
                description: themesPage.exportThemeDesc || "",
                config: JSON.parse(configJson),
                fonts_required: reqFonts
            }, null, 4);

            // Open save file dialog
            exportSaveFileDialog._themeJson = themeJson;
            exportSaveFileDialog.open();
        }

        contentItem: ColumnLayout {
            spacing: Kirigami.Units.largeSpacing

            QQC2.Label {
                text: i18n("Give your theme a name and description before exporting.")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            QQC2.BusyIndicator {
                visible: themesPage.previewGenerating
                running: visible
                Layout.alignment: Qt.AlignHCenter
            }

            QQC2.Label {
                text: themesPage.exportError
                visible: themesPage.exportError.length > 0
                color: Kirigami.Theme.negativeTextColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            QQC2.TextField {
                id: exportNameField
                Kirigami.FormData.label: i18n("Name:")
                Layout.fillWidth: true
                placeholderText: i18n("My Theme")
                onTextChanged: themesPage.exportThemeName = text
            }

            QQC2.TextField {
                id: exportDescField
                Kirigami.FormData.label: i18n("Description:")
                Layout.fillWidth: true
                placeholderText: i18n("Optional description")
                onTextChanged: themesPage.exportThemeDesc = text
            }

            QQC2.TextField {
                id: exportAuthorField
                Kirigami.FormData.label: i18n("Author:")
                Layout.fillWidth: true
                placeholderText: i18n("Your name")
                onTextChanged: themesPage.exportThemeAuthor = text
            }

            // Embedded fonts
            Kirigami.Separator {
                Layout.fillWidth: true
                Kirigami.FormData.label: i18n("Embedded Fonts")
            }

            Repeater {
                model: themesPage.embedFontPaths
                RowLayout {
                    Layout.fillWidth: true
                    QQC2.Label {
                        text: modelData.split("/").pop()
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    QQC2.ToolButton {
                        icon.name: "list-remove"
                        onClicked: {
                            var paths = themesPage.embedFontPaths.slice();
                            paths.splice(index, 1);
                            themesPage.embedFontPaths = paths;
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                QQC2.Button {
                    text: i18n("Add Font...")
                    icon.name: "list-add"
                    onClicked: fontFileDialog.open()
                }
            }

            QQC2.Label {
                text: i18n("Fonts will be resolved from your system via fontconfig.")
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.5
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }

    // Save file dialog (opened from export dialog accept)
    Dialogs.FileDialog {
        id: exportSaveFileDialog
        title: i18n("Save Theme As")
        fileMode: Dialogs.FileDialog.SaveFile
        nameFilters: [i18n("Modern reClock Theme (*.zip)")]
        defaultSuffix: "zip"
        property string _themeJson: ""
        onAccepted: {
            var filePath = exportSaveFileDialog.selectedFile.toString().replace("file://", "");
            log.info("export", "Save dialog accepted, path: " + filePath);

            // Auto-resolve font paths from config font families
            var resolvedFonts = themesPage.resolveFontPathsFromConfig();
            log.info("export", "Auto-detected fonts: " + JSON.stringify(resolvedFonts));

            // Also include manually added fonts
            for (var i = 0; i < themesPage.embedFontPaths.length; i++) {
                var path = themeManager.resolveFontPath(themesPage.embedFontPaths[i].split("/").pop().replace(/\.(ttf|otf)$/i, ""));
                if (path && resolvedFonts.indexOf(path) === -1) {
                    resolvedFonts.push(path);
                    log.info("export", "Added manual font: " + path);
                }
            }

            var wpPath = ModernRecClock.Wallpaper ? (ModernRecClock.Wallpaper.wallpaperPath() || "") : "";
            log.info("export", "Wallpaper path: " + wpPath);
            log.info("export", "Theme JSON length: " + exportSaveFileDialog._themeJson.length);

            var result = themeManager.exportTheme(filePath, exportSaveFileDialog._themeJson, resolvedFonts, wpPath);
            if (result)
                log.info("themes", "Theme exported to: " + result);
            else
                log.error("themes", "Theme export failed");
        }
    }

    // ===== UI =====
    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

        // ==================== FILE OPERATIONS ====================
        Kirigami.Heading {
            text: i18n("Theme Files")
            level: 2
            Layout.fillWidth: true
        }

        RowLayout {
            spacing: Kirigami.Units.smallSpacing
            QQC2.Button {
                text: i18n("Export .zip...")
                icon.name: "document-save"
                onClicked: exportDialog.open()
            }
            QQC2.Button {
                text: i18n("Import .zip...")
                icon.name: "document-import"
                onClicked: { themesPage.importError = ""; importFileDialog.open(); }
            }
            QQC2.Button {
                text: i18n("Add Font...")
                icon.name: "list-add"
                onClicked: fontFileDialog.open()
            }
        }

        QQC2.Label {
            text: themesPage.importError
            visible: themesPage.importError.length > 0
            color: Kirigami.Theme.negativeTextColor
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Repeater {
            model: themesPage.embedFontPaths
            RowLayout {
                spacing: Kirigami.Units.smallSpacing
                QQC2.Label {
                    text: modelData.split("/").pop()
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                QQC2.ToolButton {
                    icon.name: "list-remove"
                    onClicked: {
                        var paths = themesPage.embedFontPaths.slice();
                        paths.splice(index, 1);
                        themesPage.embedFontPaths = paths;
                    }
                }
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        // ==================== COMMUNITY THEMES ====================
        Kirigami.Heading {
            text: i18n("Community Themes")
            level: 2
            Layout.fillWidth: true
        }

        RowLayout {
            spacing: Kirigami.Units.smallSpacing
            QQC2.Button {
                text: themesPage.indexLoaded ? i18n("Refresh") : i18n("Load Themes")
                icon.name: themesPage.indexLoaded ? "view-refresh" : "download"
                onClicked: themeManager.fetchIndex()
            }
            QQC2.BusyIndicator {
                visible: !themesPage.indexLoaded && !themesPage.indexError
                running: visible
            }
        }

        QQC2.Label {
            text: themesPage.indexError
            visible: themesPage.indexError.length > 0
            color: Kirigami.Theme.negativeTextColor
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        QQC2.ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 18
            visible: themesPage.communityThemes.length > 0
            clip: true

            GridView {
                id: communityGrid
                cellWidth: Math.floor(width / 4)
                cellHeight: Math.floor(cellWidth * 9 / 16 + Kirigami.Units.gridUnit * 4)
                model: themesPage.communityThemes

                delegate: Item {
                    width: communityGrid.cellWidth
                    height: communityGrid.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.smallSpacing
                        radius: Kirigami.Units.cornerRadius
                        color: Kirigami.Theme.backgroundColor
                        border.color: Kirigami.Theme.separatorColor
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 0

                            Image {
                                Layout.fillWidth: true
                                Layout.preferredHeight: communityGrid.cellWidth * 9 / 16
                                fillMode: Image.PreserveAspectFit
                                source: modelData.preview_url || ""
                                asynchronous: true
                                clip: true

                                QQC2.BusyIndicator {
                                    anchors.centerIn: parent
                                    running: parent.status === Image.Loading
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.margins: Kirigami.Units.smallSpacing
                                Layout.alignment: Qt.AlignBottom

                                QQC2.Label {
                                    text: modelData.name || i18n("Untitled")
                                    font.bold: true
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                QQC2.Label {
                                    text: (modelData.author || "") + (modelData.version ? " v" + modelData.version : "")
                                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                                    opacity: 0.6
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                themesPage.previewThemeData = modelData;
                                previewDialog.open();
                            }
                        }
                    }
                }
            }
        }

        QQC2.Label {
            text: themesPage.indexLoaded ? i18n("No themes available yet") : ""
            visible: themesPage.indexLoaded && themesPage.communityThemes.length === 0
            Kirigami.Theme.colorSet: Kirigami.Theme.View
            color: Kirigami.Theme.disabledTextColor
            Layout.fillWidth: true
        }

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        // ==================== LOCAL THEMES ====================
        Kirigami.Heading {
            text: i18n("Local Themes")
            level: 2
            Layout.fillWidth: true
        }

        QQC2.Label {
            text: i18n("Your saved themes are in the Appearance tab. Export them as .zip to share with others.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Kirigami.Theme.colorSet: Kirigami.Theme.View
            color: Kirigami.Theme.disabledTextColor
        }

        Item {
            Layout.fillHeight: true
        }
    }
            } // Item (Loader root)
        } // Component
    } // Loader
}
