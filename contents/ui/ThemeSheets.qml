import QtQml
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.modernreclock as ModernRecClock

/**
 * Theme management OverlaySheets for configAppearance.qml.
 *
 * Parent must set function properties:
 *   - getFullConfig() → string
 *   - applyConfig(jsonString) → bool
 *   - updatePreview()
 *   - saveThemeFn(name, description)
 *   - deleteThemeFn(index)
 *   - loadThemeFn(index)
 *   - themeToJSONFn(index) → string
 *   - themes: var (saved themes array)
 *   - setThemesJson(jsonString)
 */
Item {
    id: root

    readonly property var log: ModernRecClock.Log

    required property var getFullConfig
    required property var applyConfig
    required property var updatePreview
    required property var saveThemeFn
    required property var deleteThemeFn
    required property var loadThemeFn
    required property var themeToJSONFn
    required property var themes
    required property var setThemesJson

    // ===== Save Theme Sheet =====
    Kirigami.OverlaySheet {
        id: saveThemeSheet
        header: Kirigami.Heading { text: i18n("Save Theme"); level: 3 }

        ColumnLayout {
            spacing: Kirigami.Units.largeSpacing
            implicitWidth: Kirigami.Units.gridUnit * 25

            QQC2.TextField {
                id: themeNameField
                Kirigami.FormData.label: i18n("Name:")
                Layout.fillWidth: true
                placeholderText: i18n("My Theme")
            }
            QQC2.TextField {
                id: themeDescField
                Kirigami.FormData.label: i18n("Description:")
                Layout.fillWidth: true
                placeholderText: i18n("Optional description")
            }
            RowLayout {
                Layout.alignment: Qt.AlignRight
                QQC2.Button {
                    text: i18n("Save"); icon.name: "document-save"
                    onClicked: {
                        log.info("theme", "Saving theme via overlay: name=\"" + themeNameField.text + "\"");
                        root.saveThemeFn(themeNameField.text, themeDescField.text);
                        themeNameField.text = "";
                        themeDescField.text = "";
                        saveThemeSheet.close();
                    }
                }
                QQC2.Button { text: i18n("Cancel"); onClicked: {
                    log.debug("theme", "Save theme cancelled");
                    saveThemeSheet.close();
                } }
            }
        }
    }

    // ===== Export Theme Sheet =====
    Kirigami.OverlaySheet {
        id: exportThemeSheet
        header: Kirigami.Heading { text: i18n("Export Theme"); level: 3 }

        ColumnLayout {
            spacing: Kirigami.Units.largeSpacing
            implicitWidth: Kirigami.Units.gridUnit * 25

            QQC2.Label {
                text: i18n("Copy this JSON to share or back up your theme.")
                wrapMode: Text.WordWrap; Layout.fillWidth: true
            }
            QQC2.ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 12
                contentWidth: -1
                QQC2.TextArea {
                    id: exportThemeArea
                    readOnly: true; wrapMode: Text.NoWrap
                    font.family: "Monospace"; width: parent.width
                }
            }
            RowLayout {
                Layout.alignment: Qt.AlignRight
                QQC2.Button { text: i18n("Close"); onClicked: {
                    log.debug("theme", "Export theme closed");
                    exportThemeSheet.close();
                } }
            }
        }
    }

    // ===== Import Theme Sheet =====
    Kirigami.OverlaySheet {
        id: importThemeSheet
        header: Kirigami.Heading { text: i18n("Import Theme"); level: 3 }

        ColumnLayout {
            spacing: Kirigami.Units.largeSpacing
            implicitWidth: Kirigami.Units.gridUnit * 25

            QQC2.Label {
                text: i18n("Paste a theme JSON below. It will be added to your saved themes.")
                wrapMode: Text.WordWrap; Layout.fillWidth: true
            }
            QQC2.ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 12
                contentWidth: -1
                QQC2.TextArea {
                    id: importThemeArea
                    wrapMode: Text.NoWrap; font.family: "Monospace"
                    placeholderText: i18n("Paste theme JSON here..."); width: parent.width
                }
            }
            QQC2.Label {
                id: importErrorLabel
                text: ""; color: Kirigami.Theme.negativeTextColor
                visible: text.length > 0; wrapMode: Text.WordWrap; Layout.fillWidth: true
            }
            RowLayout {
                Layout.alignment: Qt.AlignRight
                QQC2.Button {
                    text: i18n("Import"); icon.name: "document-import"
                    onClicked: {
                        try {
                            let data = JSON.parse(importThemeArea.text);
                            if (data.config && data.name) {
                                log.info("theme", "Importing full theme: \"" + data.name + "\"");
                                let themes = root.themes.slice();
                                themes.push(data);
                                root.setThemesJson(JSON.stringify(themes));
                                importThemeSheet.close();
                            } else {
                                log.info("theme", "Importing raw config JSON");
                                root.applyConfig(importThemeArea.text);
                                root.updatePreview();
                                importThemeSheet.close();
                            }
                        } catch (e) {
                            log.warn("theme", "Import failed: " + e.message);
                            importErrorLabel.text = i18n("Invalid JSON: %1", e.message);
                        }
                    }
                }
                QQC2.Button { text: i18n("Cancel"); onClicked: {
                    log.debug("theme", "Import cancelled");
                    importThemeSheet.close();
                } }
            }
        }
    }

    // ===== Raw JSON Sheet =====
    Kirigami.OverlaySheet {
        id: rawJsonSheet
        header: Kirigami.Heading { text: i18n("Widget Configuration (Raw JSON)"); level: 3 }

        ColumnLayout {
            spacing: Kirigami.Units.largeSpacing
            implicitWidth: Kirigami.Units.gridUnit * 25

            QQC2.Label {
                text: i18n("Copy this JSON to save your full config, or paste a previously saved JSON to restore it.")
                wrapMode: Text.WordWrap; Layout.fillWidth: true
            }
            QQC2.ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 15
                contentWidth: -1
                QQC2.TextArea {
                    id: backupArea
                    wrapMode: Text.NoWrap; font.family: "Monospace"; width: parent.width
                }
            }
            RowLayout {
                Layout.alignment: Qt.AlignRight
                QQC2.Button {
                    text: i18n("Apply Pasted Config"); icon.name: "document-import"
                    onClicked: {
                        log.info("config", "Applying raw JSON config");
                        if (root.applyConfig(backupArea.text)) {
                            root.updatePreview();
                            log.info("config", "Raw JSON config applied successfully");
                            rawJsonSheet.close();
                        } else {
                            log.warn("config", "Raw JSON config application FAILED");
                            backupArea.text = "INVALID JSON!";
                        }
                    }
                }
                QQC2.Button {
                    text: i18n("Reset to current")
                    onClicked: {
                        log.debug("config", "Resetting raw JSON to current config");
                        backupArea.text = root.getFullConfig();
                    }
                }
            }
        }
    }

    // ===== Public API =====
    function openSave() { saveThemeSheet.open(); }
    function openExport(index) {
        exportThemeArea.text = root.themeToJSONFn(index);
        exportThemeSheet.open();
    }
    function openImport() { importThemeSheet.open(); }
    function openRawJson() {
        backupArea.text = root.getFullConfig();
        rawJsonSheet.open();
    }
}
