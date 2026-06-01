#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_ROOT="$(realpath "$DIR/..")"
METADATA="$PACKAGE_ROOT/metadata.json"

echo "[build] Starting build process in $DIR"

PLASMOID_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["KPlugin"]["Id"])' "$METADATA")"

if [[ -z "$PLASMOID_ID" ]]; then
    echo "[build] Error: Could not determine widget ID from metadata.json"
    exit 1
fi

echo "[build] Compiling messages"

catalogs=$(find . -name '*.po' | sort)
for cat in $catalogs; do
    echo "$cat"
    CAT_LOCALE=$(basename "${cat%.*}")
    msgfmt -o "$CAT_LOCALE.mo" "$cat"

    INSTALL_PATH="$DIR/../contents/locale/$CAT_LOCALE/LC_MESSAGES/plasma_applet_$PLASMOID_ID.mo"

    echo "[build] Install to $INSTALL_PATH"
    mkdir -p "$(dirname "$INSTALL_PATH")"
    mv "$CAT_LOCALE.mo" "$INSTALL_PATH"
done

echo "[build] Done building messages"

echo "[build] All done"
