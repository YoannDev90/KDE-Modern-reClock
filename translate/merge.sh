#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_ROOT="$(realpath "$DIR/..")"
METADATA="$PACKAGE_ROOT/metadata.json"

echo "[merge] Starting merge process in $DIR"

PLASMOID_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["KPlugin"]["Id"])' "$METADATA")"
WIDGET_NAME="${PLASMOID_ID##*.}"
BUGS_REPORT_URL="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["KPlugin"].get("BugReportUrl", json.load(open(sys.argv[1]))["KPlugin"].get("Website", "")))' "$METADATA")"

if [[ -z "$WIDGET_NAME" ]]; then
    echo "[merge] Error: Could not determine widget name from metadata.json"
    exit 1
fi

echo "[merge] Plasmoid ID: $PLASMOID_ID"
echo "[merge] Widget name: $WIDGET_NAME"
echo "[merge] Extracting messages"

cd "$PACKAGE_ROOT"

find . \
    \( -name '*.qml' -o -name '*.js' -o -name '*.xml' -o -name '*.json' \) \
    ! -path './contents/locale/*' \
    ! -path './translate/*' \
    | sort > "$DIR/infiles.list"

xgettext \
    --files-from="$DIR/infiles.list" \
    --from-code=UTF-8 \
    --width=400 \
    --add-location=file \
    -C \
    -kde \
    -ci18n \
    -ki18n:1 \
    -ki18nc:1c,2 \
    -ki18np:1,2 \
    -ki18ncp:1c,2,3 \
    -ktr2i18n:1 \
    -kI18N_NOOP:1 \
    -kI18N_NOOP2:1c,2 \
    -kN_:1 \
    -kki18n:1 \
    -kki18nc:1c,2 \
    -kki18np:1,2 \
    -kki18ncp:1c,2,3 \
    --package-name="$WIDGET_NAME" \
    --msgid-bugs-address="$BUGS_REPORT_URL" \
    -o "$DIR/template.pot.new" \
    || {
        echo "[merge] Error: xgettext failed"
        exit 1
    }

sed -i 's/charset=CHARSET/charset=UTF-8/' "$DIR/template.pot.new"
sed -i 's|#: \./|#: |g' "$DIR/template.pot.new"

if [[ -f "$DIR/template.pot" ]]; then
    newPotDate="$(grep "POT-Creation-Date:" "$DIR/template.pot.new" | sed 's/.\{3\}$//')"
    oldPotDate="$(grep "POT-Creation-Date:" "$DIR/template.pot" | sed 's/.\{3\}$//')"

    sed -i 's/'"${newPotDate}"'/'"${oldPotDate}"'/' "$DIR/template.pot.new"

    changes="$(diff "$DIR/template.pot" "$DIR/template.pot.new" || true)"

    if [[ -n "$changes" ]]; then
        sed -i 's/'"${oldPotDate}"'/'"${newPotDate}"'/' "$DIR/template.pot.new"
        mv "$DIR/template.pot.new" "$DIR/template.pot"

        addedKeys="$(printf '%s\n' "$changes" | grep "> msgid" | cut -c 9- | sort || true)"
        removedKeys="$(printf '%s\n' "$changes" | grep "< msgid" | cut -c 9- | sort || true)"

        echo ""
        echo "Added Keys:"
        echo "$addedKeys"
        echo ""
        echo "Removed Keys:"
        echo "$removedKeys"
        echo ""
    else
        rm "$DIR/template.pot.new"
        echo "[merge] template.pot unchanged"
    fi
else
    mv "$DIR/template.pot.new" "$DIR/template.pot"
    echo "[merge] template.pot created"
fi

rm "$DIR/infiles.list"

echo "[merge] Done extracting messages"

echo "[merge] Merging messages"
catalogs=$(find . -name '*.po' | sort)
for cat in $catalogs; do
    echo "[merge] $cat"
    CAT_LOCALE=$(basename "${cat%.*}")
    msgmerge \
        --width=400 \
        --add-location=file \
        --no-fuzzy-matching \
        -o "$cat.new" \
        "$cat" "$DIR/template.pot"
    sed -i 's/# SOME DESCRIPTIVE TITLE./'"# Translation of $WIDGET_NAME in $CAT_LOCALE"'/' "$cat.new"
    sed -i 's/# Translation of '"$WIDGET_NAME"' in LANGUAGE/'"# Translation of $WIDGET_NAME in $CAT_LOCALE"'/' "$cat.new"
    sed -i 's/# Copyright (C) YEAR THE PACKAGE'"'"'S COPYRIGHT HOLDER/'"# Copyright (C) $(date +%Y)"'/' "$cat.new"

    mv "$cat.new" "$cat"
done

echo "[merge] Done merging messages"

echo "[merge] All done"
