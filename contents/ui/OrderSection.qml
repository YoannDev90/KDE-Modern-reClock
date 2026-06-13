import QtQml
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.modernreclock as ModernRecClock

/**
 * Element order section for configAppearance.qml.
 * ListModel-based reorderable list with numbered rows and KDE icons.
 *
 * Parent must set:
 *   - elementOrder: string (comma-separated order, read/write via signal)
 */
Item {
    id: root

    readonly property var log: ModernRecClock.Log

    required property string elementOrder

    signal orderChanged(string newOrder)
    signal resetRequested()

    // ===== Order Model =====
    ListModel {
        id: orderListModel
        ListElement { key: "day" }
        ListElement { key: "date" }
        ListElement { key: "time" }
        ListElement { key: "custom" }
        ListElement { key: "timezone" }
    }

    QtObject {
        id: _state
        readonly property var circledNumbers: ["\u2460", "\u2461", "\u2462", "\u2463", "\u2464"]

        function labelForKey(key) {
            if (key === "day") return i18n("Day");
            if (key === "date") return i18n("Date");
            if (key === "time") return i18n("Time");
            if (key === "custom") return i18n("Custom");
            if (key === "timezone") return i18n("Timezone");
            return key;
        }

        function iconForKey(key) {
            if (key === "day") return "weather-clear";
            if (key === "date") return "view-calendar";
            if (key === "time") return "clock";
            if (key === "custom") return "text-x-generic";
            if (key === "timezone") return "globe";
            return "help";
        }

        function initOrder() {
            let raw = root.elementOrder ? root.elementOrder.trim() : "";
            if (!raw || raw.length === 0) {
                log.debug("config", "OrderSection.initOrder: empty order config, using defaults");
                return;
            }

            let k = raw.split(",");
            let valid = ["day", "date", "time", "custom", "timezone"];
            k = k.filter(function(v) { return valid.indexOf(v.trim()) !== -1; })
                .map(function(v) { return v.trim(); });
            if (k.length === 0) {
                log.debug("config", "OrderSection.initOrder: no valid elements after filter");
                return;
            }

            log.info("config", "OrderSection.initOrder: restoring order → " + k.join(","));

            var currentOrder = [];
            for (var i = 0; i < orderListModel.count; i++)
                currentOrder.push(orderListModel.get(i).key);

            for (var targetIdx = 0; targetIdx < k.length; targetIdx++) {
                var key = k[targetIdx];
                var currentIdx = currentOrder.indexOf(key);
                if (currentIdx !== -1 && currentIdx !== targetIdx) {
                    orderListModel.move(currentIdx, targetIdx, 1);
                    var moved = currentOrder.splice(currentIdx, 1)[0];
                    currentOrder.splice(targetIdx, 0, moved);
                }
            }
            _state.saveOrder();
        }

        function moveOrder(from, to) {
            if (from === to) return;
            if (from < 0 || from >= orderListModel.count) return;
            if (to < 0 || to >= orderListModel.count) return;
            var key = orderListModel.get(from).key;
            orderListModel.move(from, to, 1);
            log.debug("config", "OrderSection.moveOrder: " + key + " from " + from + " → " + to);
            _state.saveOrder();
        }

        function saveOrder() {
            var order = [];
            for (var i = 0; i < orderListModel.count; i++)
                order.push(orderListModel.get(i).key);
            var newOrder = order.join(",");
            log.info("config", "OrderSection.saveOrder → " + newOrder);
            root.orderChanged(newOrder);
        }

        function resetOrder() {
            log.info("config", "OrderSection.resetOrder: restoring default order");
            orderListModel.clear();
            orderListModel.append({"key": "day"});
            orderListModel.append({"key": "date"});
            orderListModel.append({"key": "time"});
            orderListModel.append({"key": "custom"});
            orderListModel.append({"key": "timezone"});
            root.orderChanged("day,date,time,custom,timezone");
        }
    }

    Connections {
        target: root
        function onResetRequested() { _state.resetOrder(); }
    }

    Component.onCompleted: _state.initOrder()

    // ===== UI =====
    implicitHeight: orderColumn.implicitHeight

    ColumnLayout {
        id: orderColumn
        width: parent.width
        spacing: 2

        Repeater {
            id: orderRepeater
            model: orderListModel
            delegate: Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: delegateRow.implicitHeight + Kirigami.Units.smallSpacing * 2
                radius: Kirigami.Units.cornerRadius
                color: index % 2 === 0
                    ? Qt.rgba(Kirigami.Theme.highlightColor.r,
                              Kirigami.Theme.highlightColor.g,
                              Kirigami.Theme.highlightColor.b, 0.08)
                    : "transparent"

                RowLayout {
                    id: delegateRow
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.smallSpacing

                    QQC2.Label {
                        text: _state.circledNumbers[index] || (index + 1)
                        font.bold: true
                        font.pixelSize: 14
                        Layout.preferredWidth: 28
                        horizontalAlignment: Text.AlignHCenter
                        color: Kirigami.Theme.highlightColor
                    }

                    Kirigami.Icon {
                        source: _state.iconForKey(modelData)
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                    }

                    QQC2.Label {
                        text: _state.labelForKey(modelData)
                        font.pixelSize: 13
                        Layout.fillWidth: true
                    }

                    QQC2.Button {
                        icon.name: "arrow-up"
                        enabled: index > 0
                        onClicked: _state.moveOrder(index, index - 1)
                        QQC2.ToolTip.text: i18n("Move up")
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.delay: 800
                    }

                    QQC2.Button {
                        icon.name: "arrow-down"
                        enabled: index < orderListModel.count - 1
                        onClicked: _state.moveOrder(index, index + 1)
                        QQC2.ToolTip.text: i18n("Move down")
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.delay: 800
                    }
                }
            }
        }
    }
}
