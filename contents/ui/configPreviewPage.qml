import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15

import org.kde.kirigami 2.0 as Kirigami

ColumnLayout {
    id: previewPage
    property var ctx: null

    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: Kirigami.Units.largeSpacing

    // C++ plugin warning banner
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: pluginWarningRow.implicitHeight + 24
        visible: !(ctx && ctx.themeManager)
        color: Qt.rgba(1, 0.8, 0, 0.15)
        border.color: Qt.rgba(1, 0.8, 0, 0.5)
        border.width: 1
        radius: Kirigami.Units.cornerRadius

        RowLayout {
            id: pluginWarningRow
            anchors.fill: parent
            anchors.margins: 12
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: "dialog-warning"
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Kirigami.Heading {
                    text: i18n("C++ plugin not installed")
                    level: 4
                    color: "#FFD700"
                }

                QQC2.Label {
                    text: i18n("Some features are disabled (timezone, wallpaper detection, preview). Install the plugin to enable them:")
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                QQC2.TextField {
                    id: pluginInstallCmd
                    Layout.fillWidth: true
                    readOnly: true
                    font.family: "Monospace"
                    font.pixelSize: 11
                    text: {
                        // Detect package path from QML file location
                        var pkgPath = Qt.resolvedUrl("../").toString();
                        pkgPath = pkgPath.replace(/^file:\/\//, "").replace(/\/$/, "");
                        var qmlDir = "/usr/lib64/qt6/qml/org/kde/plasma/private/modernreclock";
                        return "sudo cp " + pkgPath + "/code/libmodernreclock_backend.so " + qmlDir + "/ && sudo cp " + pkgPath + "/code/qmldir " + qmlDir + "/";
                    }
                    QQC2.ToolTip.text: i18n("Click to copy")
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: 500
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            parent.selectAll();
                            parent.copy();
                        }
                    }
                }

                QQC2.Label {
                    text: i18n("Then restart Plasma: plasmashell --replace")
                    font.italic: true
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.7
                }
            }
        }
    }

    Kirigami.Heading {
        text: i18n("Preview")
        level: 2
        horizontalAlignment: Text.AlignHCenter
        Layout.fillWidth: true
    }

    // Centered preview — fills available height, keeps 16:9 ratio
    Rectangle {
        id: previewFrame
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.maximumWidth: parent.width * 0.9
        Layout.alignment: Qt.AlignHCenter
        color: "#2a2a2a"
        border.color: "#555"
        border.width: 1
        radius: Kirigami.Units.cornerRadius
        clip: true

        Image {
            id: previewImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            source: ctx ? ctx.previewImagePath : ""
            onStatusChanged: {
                if (status === Image.Ready && ctx) ctx.log.info("config", "IMG ready: " + source);
                else if (status === Image.Error && ctx) ctx.log.warn("config", "IMG ERROR: " + source);
                else if (status === Image.Loading && ctx) ctx.log.info("config", "IMG loading: " + source);
            }

            QQC2.BusyIndicator {
                anchors.centerIn: parent
                running: parent.status === Image.Loading
            }

            QQC2.Label {
                anchors.centerIn: parent
                text: i18n("Adjust settings to generate preview")
                color: Kirigami.Theme.disabledTextColor
                visible: parent.status !== Image.Ready && parent.status !== Image.Loading
            }
        }
    }
}