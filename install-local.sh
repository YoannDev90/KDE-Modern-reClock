#!/usr/bin/env bash
set -e

# Move to the script's directory
cd "$(dirname "$0")"

echo "--- Compiling project ---"
# Check if kpackagetool6 is available
if ! command -v kpackagetool6 &> /dev/null; then
    echo "Error: kpackagetool6 not found. Please ensure KDE Plasma 6 development tools are installed."
    exit 1
fi

echo "--- Preparing translations ---"
if [ -f "translate/build.sh" ]; then
    chmod +x translate/build.sh
    ./translate/build.sh
fi

echo "--- Installing the widget ---"
# Try to update, if it fails (not installed yet), install it
kpackagetool6 -t Plasma/Applet -u . || kpackagetool6 -t Plasma/Applet -i .

echo "--- Cleaning Plasma cache ---"
# Clear the QML cache to ensure changes are picked up immediately
rm -rf ~/.cache/plasmashell/qmlcache/*modernreclock* 2>/dev/null || true

if [[ " $* " == *" -force-reload "* ]] || [[ " $* " == *" --fr "* ]]; then
    echo "--- Restarting Plasmashell ---"
    plasmashell --replace & disown
fi

echo "--- Done! ---"
echo "You can now add the 'Modern reClock' widget from your Plasma panel."
echo "If the widget is already active, you might need to remove and re-add it to see all changes."