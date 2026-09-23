import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15

import org.kde.kirigami 2.0 as Kirigami

ColumnLayout {
    id: savedThemesPage
    property var ctx: null

    spacing: Kirigami.Units.largeSpacing

    Kirigami.Heading {
        text: i18n("Themes")
        level: 2
        horizontalAlignment: Text.AlignHCenter
        Layout.fillWidth: true
    }

    QQC2.Button {
        text: i18n("Save Current Theme")
        icon.name: "document-save"
        Layout.alignment: Qt.AlignHCenter
        onClicked: ctx.themeSheets.openSave()
    }

    Repeater {
        model: ctx.savedThemes
        delegate: RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true
                QQC2.Label {
                    text: modelData.name || i18n("Untitled")
                    font.bold: true
                }
                QQC2.Label {
                    text: modelData.description || ""
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.7
                    visible: text.length > 0
                }
            }

            QQC2.Button {
                icon.name: "document-open"
                onClicked: ctx.loadThemeConfig(index)
                QQC2.ToolTip.text: i18n("Load this theme")
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: 800
            }

            QQC2.Button {
                icon.name: "document-export"
                onClicked: ctx.themeSheets.openExport(index)
                QQC2.ToolTip.text: i18n("Export this theme")
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: 800
            }

            QQC2.Button {
                icon.name: "edit-delete"
                onClicked: ctx.deleteTheme(index)
                QQC2.ToolTip.text: i18n("Delete this theme")
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: 800
            }
        }
    }

    QQC2.Label {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: i18n("No saved themes yet.")
        visible: ctx.savedThemes.length === 0
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        opacity: 0.6
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Kirigami.Units.smallSpacing

        QQC2.Button {
            text: i18n("Import Theme")
            icon.name: "document-import"
            onClicked: ctx.themeSheets.openImport()
        }

        QQC2.Button {
            text: i18n("Advanced: Raw JSON")
            icon.name: "text-x-generic"
            onClicked: ctx.themeSheets.openRawJson()
        }
    }
}