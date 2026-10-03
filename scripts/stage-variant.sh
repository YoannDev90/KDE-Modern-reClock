#!/usr/bin/env bash
set -euo pipefail

# Stage a plasmoid package variant into a destination directory.
#
# Usage: stage-variant.sh <full|taskbar> <dest-dir>
#
#   full     Copy metadata.json + contents as-is (minus build artifacts).
#   taskbar  Stamp metadata/defaults for "Modern reClock Taskbar":
#            new Id/Name/TranslationDomain, reduced defaults, 1 config
#            category, Preview/Saved Themes/Themes files removed.
#
# The repository always stays in the "full" state — this script never
# touches the source tree.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/metadata.json" ]; then
    ROOT="$(realpath "$SCRIPT_DIR")"
elif [ -f "$SCRIPT_DIR/../metadata.json" ]; then
    ROOT="$(realpath "$SCRIPT_DIR/..")"
else
    echo "Error: plasmoid root (metadata.json) not found near $SCRIPT_DIR" >&2
    exit 1
fi

VARIANT="${1:-}"
DEST="${2:-}"

usage() {
    echo "Usage: $0 <full|taskbar> <dest-dir>" >&2
    exit 1
}

case "$VARIANT" in
    full|taskbar) ;;
    *) usage ;;
esac
[ -n "$DEST" ] || usage

TASKBAR_ID="com.github.yoanndev90.modernreclock.taskbar"
FULL_ID="com.github.yoanndev90.modernreclock"

mkdir -p "$DEST"
DEST="$(realpath "$DEST")"

echo "=== Staging '$VARIANT' variant -> $DEST ==="

# ---- Copy source (exclude build artifacts) ----
cp "$ROOT/metadata.json" "$DEST/"
(
    cd "$ROOT"
    tar --exclude='*.qmlc' --exclude='*.qmlc?' --exclude='__pycache__' \
        --exclude='.DS_Store' -cf - contents
) | tar -xf - -C "$DEST"

if [ "$VARIANT" = "full" ]; then
    echo "=== Staged (full) ==="
    exit 0
fi

# ---- Taskbar stamping ----

# 1. metadata.json: new identity
python3 - "$DEST/metadata.json" "$TASKBAR_ID" <<'PYEOF'
import json, sys

path, new_id = sys.argv[1], sys.argv[2]
with open(path, encoding="utf-8") as f:
    data = json.load(f)

kp = data["KPlugin"]
kp["Id"] = new_id
kp["Name"] = "Modern reClock Taskbar"
kp["Description"] = "A modern looking clock widget for your Panel!"
kp["TranslationDomain"] = "plasma_applet_" + new_id

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
print("  metadata: Id=%s" % new_id)
PYEOF

# 2. Variant.qml: flag -> taskbar
VARIANT_QML="$DEST/contents/ui/Variant.qml"
if ! grep -q 'readonly property bool taskbar: false' "$VARIANT_QML"; then
    echo "Error: Variant.qml default flag not found in $VARIANT_QML" >&2
    exit 1
fi
sed -i 's/readonly property bool taskbar: false/readonly property bool taskbar: true/' "$VARIANT_QML"
echo "  Variant.qml: taskbar: true"

# 3. main.xml: reduced defaults (mirrors sectionDefaults/resetGlobal in QML)
python3 - "$DEST/contents/config/main.xml" <<'PYEOF'
import re, sys

path = sys.argv[1]
defaults = {
    "day_font_size": "18",
    "day_letter_spacing": "3",
    "date_font_size": "12",
    "date_letter_spacing": "1",
    "time_font_size": "12",
    "time_letter_spacing": "1",
    "timezone_font_size": "9",
    "timezone_letter_spacing": "1",
    "widget_spacing": "2",
}
with open(path, encoding="utf-8") as f:
    xml = f.read()

for key, value in defaults.items():
    xml, n = re.subn(
        r'(<entry name="%s"[^>]*>\s*<default>)[^<]*(</default>)' % re.escape(key),
        lambda m: m.group(1) + value + m.group(2),
        xml, count=1, flags=re.S,
    )
    if n != 1:
        sys.exit("Error: <default> for '%s' not found in %s" % (key, path))

with open(path, "w", encoding="utf-8") as f:
    f.write(xml)
print("  main.xml: %d defaults reduced" % len(defaults))
PYEOF

# 4. config.qml: Appearance category only (Themes dropped)
cat > "$DEST/contents/config/config.qml" <<'QMLEOF'
import QtQml
import org.kde.plasma.configuration
import org.kde.plasma.private.modernreclock as ModernRecClock

ConfigModel {
    Component.onCompleted: {
        if (ModernRecClock.Log)
            ModernRecClock.Log.info("config", "ConfigModel loaded — 1 category: Appearance");
    }

    ConfigCategory {
        name: i18n("Appearance")
        icon: "preferences-desktop-color"
        source: "configAppearance.qml"
    }
}
QMLEOF
echo "  config.qml: 1 category (Appearance)"

# 5. Strip files that only the full variant references
STRIP=(
    contents/ui/configThemes.qml
    contents/ui/configSavedThemesPage.qml
    contents/ui/configPreviewPage.qml
    contents/ui/ThemeSheets.qml
    contents/ui/ThemeSheetsHost.qml
)
for f in "${STRIP[@]}"; do
    rm -f "$DEST/$f"
done
echo "  stripped: ${#STRIP[@]} files (Themes/Preview/Saved Themes/ThemeSheets)"

# 6. Rename translation catalogs to the new TranslationDomain
if [ -d "$DEST/contents/locale" ]; then
    OLD_CAT="plasma_applet_${FULL_ID}.mo"
    NEW_CAT="plasma_applet_${TASKBAR_ID}.mo"
    while IFS= read -r -d '' f; do
        mv "$f" "$(dirname "$f")/$NEW_CAT"
    done < <(find "$DEST/contents/locale" -name "$OLD_CAT" -print0 2>/dev/null)
    echo "  locale: $OLD_CAT -> $NEW_CAT"
fi

echo "=== Staged (taskbar): $TASKBAR_ID ==="
