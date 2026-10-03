import QtQuick 2.15

/**
 * Variant flag — scripts/stage-variant.sh rewrites `taskbar: true` when
 * packaging "Modern reClock Taskbar". The repository keeps the full
 * desktop variant (false).
 */
QtObject {
    readonly property bool taskbar: false
}
