import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    id: aboutPage

    Kirigami.FormLayout {
        // anchors.fill: parent removed to avoid layout loops in SimpleKCM

        // ================= SECTION: ABOUT =================
        Kirigami.Heading {
            text: i18n("About")
            level: 2
            Layout.fillWidth: true
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing

            Image {
                source: Qt.resolvedUrl("../images/icon.png")
                Layout.preferredWidth: 64
                Layout.preferredHeight: 64
                Layout.alignment: Qt.AlignTop
                visible: status === Image.Ready
                // Fallback: use the Plasma icon
                QQC2.BusyIndicator {
                    anchors.centerIn: parent
                    running: parent.status === Image.Loading
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Heading {
                    text: i18n("Modern reClock")
                    level: 3
                }

                QQC2.Label {
                    text: i18n("Version: %1", "1.3.0")
                    opacity: 0.7
                }

                QQC2.Label {
                    text: i18n("A modern looking clock widget for your KDE Plasma desktop!")
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        // ================= SECTION: AUTHOR =================
        Kirigami.Heading {
            text: i18n("Author")
            level: 2
            Layout.fillWidth: true
            Kirigami.FormData.isSection: true
        }

        QQC2.Label {
            text: i18n("Yoann (YoannDev90)")
            Layout.fillWidth: true
        }

        QQC2.Label {
            text: i18n("Email: yoanndev@outlook.fr")
            Layout.fillWidth: true
            opacity: 0.7
        }

        // ================= SECTION: LINKS =================
        Kirigami.Heading {
            text: i18n("Links")
            level: 2
            Layout.fillWidth: true
            Kirigami.FormData.isSection: true
        }

        QQC2.Label {
            text: '<a href="https://github.com/YoannDev90/KDE-Modern-reClock">' + i18n("Source Code") + '</a>'
            textFormat: Text.RichText
            Layout.fillWidth: true
            onLinkActivated: Qt.openUrlExternally(link)
        }

        QQC2.Label {
            text: '<a href="https://github.com/YoannDev90/KDE-Modern-reClock/issues">' + i18n("Report a Bug") + '</a>'
            textFormat: Text.RichText
            Layout.fillWidth: true
            onLinkActivated: Qt.openUrlExternally(link)
        }

        // ================= SECTION: LICENSE =================
        Kirigami.Heading {
            text: i18n("License")
            level: 2
            Layout.fillWidth: true
            Kirigami.FormData.isSection: true
        }

        QQC2.Label {
            text: i18n("This widget is licensed under the GNU General Public License v3.0 (GPLv3).")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
}
