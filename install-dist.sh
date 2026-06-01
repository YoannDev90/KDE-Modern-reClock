#!/usr/bin/env bash
set -e

REPO_URL="https://github.com/YoannDev90/KDE-Modern-reClock"
TEMP_DIR=$(mktemp -d)

echo "--- Downloading Modern reClock ---"
git clone --depth 1 "$REPO_URL" "$TEMP_DIR"

cd "$TEMP_DIR"

echo "--- Preparing translations ---"
if [ -f "package/translate/build.sh" ]; then
    chmod +x package/translate/build.sh
    ./package/translate/build.sh
fi

echo "--- Installing the widget ---"
# Try to update, if it fails (not installed yet), install it
kpackagetool6 -t Plasma/Applet -u package || kpackagetool6 -t Plasma/Applet -i package

echo "--- Cleaning up ---"
rm -rf "$TEMP_DIR"

echo "--- Done! ---"
echo "You can now add the 'Modern reClock' widget from your Plasma panel."
echo "If the widget is already active, you might need to remove and re-add it to see all changes."