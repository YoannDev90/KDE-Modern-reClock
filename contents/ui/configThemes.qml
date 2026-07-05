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

    readonly property var log: ModernRecClock.Log
    readonly property var themeManager: ModernRecClock.ThemeManager

    // ===== Config keys synced with Appearance page via KConfig =====
    // Each cfg_* property is automatically synced by the KCM framework
    property alias cfg_show_day: _showDay.checked
    property alias cfg_show_date: _showDate.checked
    property alias cfg_show_time: _showTime.checked
    property alias cfg_show_custom: _showCustom.checked
    property alias cfg_show_timezone: _showTimezone.checked

    property alias cfg_day_font_size: _dayFontSize.value
    property alias cfg_date_font_size: _dateFontSize.value
    property alias cfg_time_font_size: _timeFontSize.value
    property alias cfg_custom_font_size: _customFontSize.value
    property alias cfg_timezone_font_size: _timezoneFontSize.value

    property alias cfg_day_letter_spacing: _dayLetterSpacing.value
    property alias cfg_date_letter_spacing: _dateLetterSpacing.value
    property alias cfg_time_letter_spacing: _timeLetterSpacing.value
    property alias cfg_custom_letter_spacing: _customLetterSpacing.value
    property alias cfg_timezone_letter_spacing: _timezoneLetterSpacing.value

    property alias cfg_day_font_color: _dayFontColor.color
    property alias cfg_date_font_color: _dateFontColor.color
    property alias cfg_time_font_color: _timeFontColor.color
    property alias cfg_custom_font_color: _customFontColor.color
    property alias cfg_timezone_font_color: _timezoneFontColor.color

    property alias cfg_day_font_bold: _dayFontBold.checked
    property alias cfg_date_font_bold: _dateFontBold.checked
    property alias cfg_time_font_bold: _timeFontBold.checked
    property alias cfg_custom_font_bold: _customFontBold.checked
    property alias cfg_timezone_font_bold: _timezoneFontBold.checked

    property alias cfg_day_format: _dayFormat.text
    property alias cfg_date_format: _dateFormat.text
    property alias cfg_time_format: _timeFormat.text
    property alias cfg_timezone_format: _timezoneFormat.text
    property alias cfg_time_character: _timeCharacter.text
    property alias cfg_use_24_hour_format: _use24HourFormat.checked
    property alias cfg_uppercase_day: _uppercaseDay.checked
    property alias cfg_uppercase_date: _uppercaseDate.checked
    property alias cfg_custom_format: _customFormat.checked
    property alias cfg_custom_text: _customText.text

    property alias cfg_fontFamilyDay: _fontFamilyDay.text
    property alias cfg_fontFamilyDate: _fontFamilyDate.text
    property alias cfg_fontFamilyTime: _fontFamilyTime.text
    property alias cfg_fontFamilyCustom: _fontFamilyCustom.text
    property alias cfg_fontFamilyTimezone: _fontFamilyTimezone.text

    property alias cfg_widget_spacing: _widgetSpacing.value
    property alias cfg_element_order: _elementOrder.text
    property alias cfg_auto_scale: _autoScale.checked
    property alias cfg_color_mode: _colorMode.text
    property alias cfg_locale: _locale.text

    property alias cfg_saved_themes: _savedThemes.text
    property alias cfg_timezone_id: _timezoneId.text
    property alias cfg_timezone_label: _timezoneLabel.text
    property alias cfg_timezone_display_text: _timezoneDisplayText.text

    // ===== Hidden controls for KCM binding =====
    QQC2.CheckBox { id: _showDay; visible: false }
    QQC2.CheckBox { id: _showDate; visible: false }
    QQC2.CheckBox { id: _showTime; visible: false }
    QQC2.CheckBox { id: _showCustom; visible: false }
    QQC2.CheckBox { id: _showTimezone; visible: false }

    QQC2.SpinBox { id: _dayFontSize; visible: false; from: 1; to: 999 }
    QQC2.SpinBox { id: _dateFontSize; visible: false; from: 1; to: 999 }
    QQC2.SpinBox { id: _timeFontSize; visible: false; from: 1; to: 999 }
    QQC2.SpinBox { id: _customFontSize; visible: false; from: 1; to: 999 }
    QQC2.SpinBox { id: _timezoneFontSize; visible: false; from: 1; to: 999 }

    QQC2.SpinBox { id: _dayLetterSpacing; visible: false; from: 0; to: 999 }
    QQC2.SpinBox { id: _dateLetterSpacing; visible: false; from: 0; to: 999 }
    QQC2.SpinBox { id: _timeLetterSpacing; visible: false; from: 0; to: 999 }
    QQC2.SpinBox { id: _customLetterSpacing; visible: false; from: 0; to: 999 }
    QQC2.SpinBox { id: _timezoneLetterSpacing; visible: false; from: 0; to: 999 }

    // Colors stored as strings, not ColorButtons (no ColorButton needed here)
    QtObject { id: _dayFontColor; property string color: "#FFFFFF" }
    QtObject { id: _dateFontColor; property string color: "#FFFFFF" }
    QtObject { id: _timeFontColor; property string color: "#FFFFFF" }
    QtObject { id: _customFontColor; property string color: "#FFFFFF" }
    QtObject { id: _timezoneFontColor; property string color: "#FFFFFF" }

    QQC2.CheckBox { id: _dayFontBold; visible: false }
    QQC2.CheckBox { id: _dateFontBold; visible: false }
    QQC2.CheckBox { id: _timeFontBold; visible: false }
    QQC2.CheckBox { id: _customFontBold; visible: false }
    QQC2.CheckBox { id: _timezoneFontBold; visible: false }

    QQC2.TextField { id: _dayFormat; visible: false }
    QQC2.TextField { id: _dateFormat; visible: false }
    QQC2.TextField { id: _timeFormat; visible: false }
    QQC2.TextField { id: _timezoneFormat; visible: false }
    QQC2.TextField { id: _timeCharacter; visible: false }
    QQC2.CheckBox { id: _use24HourFormat; visible: false }
    QQC2.CheckBox { id: _uppercaseDay; visible: false }
    QQC2.CheckBox { id: _uppercaseDate; visible: false }
    QQC2.CheckBox { id: _customFormat; visible: false }
    QQC2.TextField { id: _customText; visible: false }

    QQC2.TextField { id: _fontFamilyDay; visible: false }
    QQC2.TextField { id: _fontFamilyDate; visible: false }
    QQC2.TextField { id: _fontFamilyTime; visible: false }
    QQC2.TextField { id: _fontFamilyCustom; visible: false }
    QQC2.TextField { id: _fontFamilyTimezone; visible: false }

    QQC2.SpinBox { id: _widgetSpacing; visible: false; from: 0; to: 999 }
    QQC2.TextField { id: _elementOrder; visible: false }
    QQC2.CheckBox { id: _autoScale; visible: false }
    QQC2.TextField { id: _colorMode; visible: false }
    QQC2.TextField { id: _locale; visible: false }

    QQC2.TextField { id: _savedThemes; visible: false }
    QQC2.TextField { id: _timezoneId; visible: false }
    QQC2.TextField { id: _timezoneLabel; visible: false }
    QQC2.TextField { id: _timezoneDisplayText; visible: false }

    // ===== Config key list =====
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

    function getFullConfig() {
        let cfg = {};
        configKeys.forEach(k => cfg[k] = themesPage["cfg_" + k]);
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

    Component.onCompleted: {
        log.info("themes", "Themes page opened");
        themeManager.restorePersistedFonts();
    }

    // ===== Network callbacks =====
    Connections {
        target: themeManager
        function onIndexFetchComplete(success) {
            if (success) {
                var indexFile = themeManager.cacheDir + "/index.json";
                var xhr = new XMLHttpRequest();
                xhr.open("GET", "file://" + indexFile);
                xhr.onload = function() {
                    try {
                        themesPage.communityThemes = JSON.parse(xhr.responseText);
                        themesPage.indexLoaded = true;
                        themesPage.indexError = "";
                        log.info("themes", "Loaded " + themesPage.communityThemes.length + " community themes");
                    } catch (e) {
                        themesPage.indexError = e.message;
                    }
                };
                xhr.send();
            } else {
                themesPage.indexError = i18n("Failed to fetch theme index");
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
            }
        }

        function onErrorOccurred(message) {
            log.error("themes", "ThemeManager error: " + message);
        }
    }

    // ===== File dialogs =====
    Dialogs.FileDialog {
        id: importFileDialog
        title: i18n("Import Theme")
        fileMode: Dialogs.FileDialog.OpenFile
        nameFilters: [i18n("Modern reClock Theme (*.mrt)")]
        onAccepted: {
            var filePath = importFileDialog.selectedFile.toString().replace("file://", "");
            var jsonStr = themeManager.parseTheme(filePath);
            if (jsonStr) {
                themesPage.applyConfig(jsonStr);
                log.info("themes", "Theme imported from: " + filePath);
            } else {
                log.error("themes", "Failed to parse .mrt file");
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
            var paths = themesPage.embedFontPaths.slice();
            paths.push(path);
            themesPage.embedFontPaths = paths;
        }
    }

    // ===== Preview Dialog =====
    Dialog {
        id: previewDialog
        title: themesPage.previewThemeData.name || i18n("Theme Preview")
        modal: true
        parent: Overlay.overlay
        anchors.centerIn: parent
        standardButtons: Dialog.Cancel | Dialog.Apply
        implicitWidth: Kirigami.Units.gridUnit * 28

        onApplyClicked: {
            var d = themesPage.previewThemeData;
            if (d.mrt_url) {
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
    Dialog {
        id: exportDialog
        title: i18n("Export Theme")
        modal: true
        parent: Overlay.overlay
        anchors.centerIn: parent
        standardButtons: Dialog.Cancel | Dialog.Save
        implicitWidth: Kirigami.Units.gridUnit * 28

        onOpened: {
            themesPage.exportThemeName = "";
            themesPage.exportThemeDesc = "";
            themesPage.exportThemeAuthor = "";
        }

        onAccepted: {
            var configJson = themesPage.getFullConfig();
            // Wrap config in theme.json format
            var themeJson = JSON.stringify({
                mrt_version: 1,
                name: themesPage.exportThemeName || "My Theme",
                author: themesPage.exportThemeAuthor || "",
                version: "1.0",
                description: themesPage.exportThemeDesc || "",
                config: JSON.parse(configJson),
                fonts: { required: {}, optional: {} }
            }, null, 4);

            // Open save file dialog
            exportSaveFileDialog._themeJson = themeJson;
            exportSaveFileDialog.open();
        }

        contentItem: ColumnLayout {
            spacing: Kirigami.Units.largeSpacing

            QKC2.Label {
                text: i18n("Give your theme a name and description before exporting.")
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
        nameFilters: [i18n("Modern reClock Theme (*.mrt)")]
        defaultSuffix: "mrt"
        property string _themeJson: ""
        onAccepted: {
            var filePath = exportSaveFileDialog.selectedFile.toString().replace("file://", "");
            // Resolve font paths via fontconfig
            var resolvedFonts = [];
            for (var i = 0; i < themesPage.embedFontPaths.length; i++) {
                var path = themeManager.resolveFontPath(themesPage.embedFontPaths[i].split("/").pop().replace(/\.(ttf|otf)$/i, ""));
                if (path) resolvedFonts.push(path);
            }
            var result = themeManager.exportTheme(filePath, exportSaveFileDialog._themeJson, resolvedFonts);
            if (result)
                log.info("themes", "Theme exported to: " + result);
            else
                log.error("themes", "Theme export failed");
        }
    }

    // ===== UI =====
    Kirigami.FormLayout {
        anchors.fill: parent

        // ==================== FILE OPERATIONS ====================
        Kirigami.Heading {
            text: i18n("Theme Files")
            level: 2
            Layout.fillWidth: true
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("File:")
            QQC2.Button {
                text: i18n("Export .mrt...")
                icon.name: "document-save"
                onClicked: exportDialog.open()
            }
            QQC2.Button {
                text: i18n("Import .mrt...")
                icon.name: "document-import"
                onClicked: importFileDialog.open()
            }
        }

        Repeater {
            model: themesPage.embedFontPaths
            RowLayout {
                Kirigami.FormData.label: index === 0 ? i18n("Fonts:") : ""
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
            Kirigami.FormData.label: themesPage.embedFontPaths.length === 0 ? i18n("Fonts:") : ""
            QQC2.Button {
                text: i18n("Add Font...")
                icon.name: "list-add"
                onClicked: fontFileDialog.open()
            }
        }

        // ==================== COMMUNITY THEMES ====================
        Kirigami.Heading {
            text: i18n("Community Themes")
            level: 2
            Layout.fillWidth: true
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Online:")
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
            Layout.preferredHeight: Kirigami.Units.gridUnit * 14
            visible: themesPage.communityThemes.length > 0
            clip: true

            GridView {
                id: communityGrid
                cellWidth: Kirigami.Units.gridUnit * 10
                cellHeight: Kirigami.Units.gridUnit * 8
                model: themesPage.communityThemes

                delegate: Item {
                    width: communityGrid.cellWidth
                    height: communityGrid.cellHeight

                    QQC2.Card {
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.smallSpacing

                        contentItem: ColumnLayout {
                            spacing: 0

                            Image {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                                fillMode: Image.PreserveAspectCrop
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

                                QQC2.Button {
                                    text: i18n("Preview")
                                    icon.name: "document-preview"
                                    Layout.fillWidth: true
                                    onClicked: {
                                        themesPage.previewThemeData = modelData;
                                        previewDialog.open();
                                    }
                                }
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

        // ==================== LOCAL THEMES ====================
        Kirigami.Heading {
            text: i18n("Local Themes")
            level: 2
            Layout.fillWidth: true
            Kirigami.FormData.isSection: true
        }

        QQC2.Label {
            text: i18n("Your saved themes are in the Appearance tab. Export them as .mrt to share with others.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Kirigami.Theme.colorSet: Kirigami.Theme.View
            color: Kirigami.Theme.disabledTextColor
        }
    }
}
