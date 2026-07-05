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

echo "--- Installing C++ plugins ---"
# Also known as: modernreclock_backend.so (includes TimeZone, Wallpaper, WallpaperConfig, WallpaperImageProvider, Logger)
PLUGIN_DIR="/usr/lib64/qt6/qml/org/kde/plasma/private/modernreclock"
PLUGIN_INSTALLED=false

# 1) Try compiling from source first
if command -v cmake &> /dev/null && [ -f "CMakeLists.txt" ]; then
    echo "Building from source..."
    mkdir -p build && cd build
    if cmake .. -DCMAKE_INSTALL_PREFIX=/usr 2>/dev/null && make -j$(nproc) 2>/dev/null; then
        sudo make install 2>/dev/null && PLUGIN_INSTALLED=true
    fi
    cd ..
fi

# 2) Fallback: download precompiled binary from latest GitHub release
if [ "$PLUGIN_INSTALLED" = false ]; then
    ARCH=$(uname -m)
    REPO_URL="https://github.com/YoannDev90/KDE-Modern-reClock"
    # Get latest release tag
    LATEST_TAG=$(curl -s "$REPO_URL/releases/latest" 2>/dev/null | grep -oP '"tag_name":\s*"\K[^"]+' || echo "")
    if [ -n "$LATEST_TAG" ]; then
        DOWNLOAD_URL="$REPO_URL/releases/download/$LATEST_TAG/modernreclock-timezone-${LATEST_TAG#v}-${ARCH}.zip"
        echo "Downloading precompiled plugin ($ARCH) from $LATEST_TAG..."
        TMPZIP=$(mktemp /tmp/modernreclock-tz-XXXXXX.zip)
        if curl -fSL "$DOWNLOAD_URL" -o "$TMPZIP" 2>/dev/null; then
            TMPDIR=$(mktemp -d)
            unzip -qo "$TMPZIP" -d "$TMPDIR" 2>/dev/null
            if [ -f "$TMPDIR/$ARCH/libmodernreclock_backend.so" ]; then
                sudo mkdir -p "$PLUGIN_DIR"
                sudo cp "$TMPDIR/$ARCH/libmodernreclock_backend.so" "$PLUGIN_DIR/"
                sudo cp "$TMPDIR/$ARCH/qmldir" "$PLUGIN_DIR/"
                PLUGIN_INSTALLED=true
            fi
            rm -rf "$TMPDIR" "$TMPZIP"
        fi
    fi
fi

if [ "$PLUGIN_INSTALLED" = false ]; then
    echo "Warning: Could not install C++ plugins. Some features may not work:"
    echo "  - Secondary timezone (TimeZoneHelper)"
    echo "  - Wallpaper detection & preview (WallpaperHelper, WallpaperImageProvider)"
    echo "  - Logger (structured logging, async log fetch, export)"
    echo "Install cmake and kf6-devel packages to build from source, or open an issue."
fi

echo "--- Preparing translations ---"
if [ -f "translate/build.sh" ]; then
    chmod +x translate/build.sh
    ./translate/build.sh
fi

echo "--- Registering .mrt MIME type for ZIP detection ---"
MIME_SRC="pkg/mime/modernreclock-theme.xml"
if [ -f "$MIME_SRC" ]; then
    MIME_DIR="${HOME}/.local/share/mime/packages"
    mkdir -p "$MIME_DIR"
    cp "$MIME_SRC" "$MIME_DIR/modernreclock-theme.xml"
    if command -v update-mime-database &>/dev/null; then
        update-mime-database "${HOME}/.local/share/mime" 2>/dev/null || true
    fi
    echo "  .mrt files will now be recognized as ZIP archives"
fi

echo "--- Installing the widget ---"
# Try to update, if it fails (not installed yet), install it
kpackagetool6 -t Plasma/Applet -u . || kpackagetool6 -t Plasma/Applet -i .

echo "--- Cleaning cache ---"
# Clear QML caches to ensure changes are picked up immediately
rm -rf ~/.cache/plasmashell/qmlcache/*modernreclock* 2>/dev/null || true
rm -rf ~/.cache/kpackage/.*modernreclock* 2>/dev/null || true
rm -rf ~/.cache/kirigami/*modernreclock* 2>/dev/null || true
find ~/.cache -name "*.qmlc" -path "*modernreclock*" -delete 2>/dev/null || true

if [[ " $* " == *" -force-reload "* ]] || [[ " $* " == *" --fr "* ]]; then
    echo "--- Restarting Plasmashell ---"
    plasmashell --replace & disown
fi

echo "--- Done! ---"
echo "You can now add the 'Modern reClock' widget from your Plasma panel."