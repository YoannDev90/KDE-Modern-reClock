import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15

import org.kde.kirigami 2.0 as Kirigami

/*
 * Shared font-family selector for the config pages (day/date/time/timezone).
 *
 * The old pattern (declarative currentIndex + write from onEditTextChanged)
 * silently rewrote cfg_fontFamily* to fontArray[0] whenever the async font
 * list arrived: replacing the model resets currentIndex/editText, which fired
 * onEditTextChanged and committed the first family into every cfg key.
 *
 * Here cfg_* is written ONLY from explicit user actions (activated/accepted);
 * the display is re-synced from configValue on every cfg/model change.
 *
 * Parent must set:
 *   - ctx:         appearancePage (fontArray, fontIndexCache, cfg_*)
 *   - fontKey:     cfg property name, e.g. "cfg_fontFamilyDay"
 *   - configValue: static binding to that cfg value, e.g. ctx.cfg_fontFamilyDay
 */
QQC2.ComboBox {
    id: control

    property var ctx: null
    property string fontKey: ""
    property string configValue: ""

    Kirigami.FormData.label: i18n("Font:")
    Layout.fillWidth: true

    editable: true
    model: ctx ? ctx.fontArray : []

    function syncFromConfig() {
        if (!ctx) return;
        var name = configValue;
        var idx = ctx.fontIndexCache[name];
        if (idx !== undefined && idx >= 0 && idx < count) {
            currentIndex = idx;
        } else {
            currentIndex = -1;
        }
        if (editText !== name)
            editText = name;
    }

    onConfigValueChanged: syncFromConfig()
    Component.onCompleted: syncFromConfig()

    Connections {
        target: control.ctx
        function onFontArrayChanged() { control.syncFromConfig(); }
        function onFontIndexCacheChanged() { control.syncFromConfig(); }
    }

    onActivated: function(index) {
        if (!ctx || index < 0 || index >= ctx.fontArray.length)
            return;
        var family = ctx.fontArray[index];
        if (configValue !== family)
            ctx[fontKey] = family;
    }

    onAccepted: function() {
        if (!ctx) return;
        if (ctx.fontIndexCache[editText] !== undefined) {
            if (configValue !== editText)
                ctx[fontKey] = editText;
        } else {
            syncFromConfig();
        }
    }
}
