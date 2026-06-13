#!/usr/bin/env bash
set -e

REPO_URL="https://github.com/YoannDev90/KDE-Modern-reClock"
TEMP_DIR=$(mktemp -d)

echo "--- Downloading Modern reClock ---"
git clone --depth 1 "$REPO_URL" "$TEMP_DIR"

cd "$TEMP_DIR"

echo "--- Preparing translations ---"
if [ -f "translate/build.sh" ]; then
    chmod +x translate/build.sh
    ./translate/build.sh
fi

echo "--- Installing C++ plugins ---"
# modernreclock_backend.so includes TimeZone, Wallpaper, WallpaperConfig, WallpaperImageProvider, Logger
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
    echo "  - Secondary timezone"
    echo "  - Wallpaper detection & preview"
    echo "  - Structured logging & debug export"
fi

echo "--- Installing the widget ---"
# Try to update, if it fails (not installed yet), install it
kpackagetool6 -t Plasma/Applet -u . || kpackagetool6 -t Plasma/Applet -i .

echo "--- Cleaning up ---"
rm -rf "$TEMP_DIR"

echo "--- Done! ---"
echo "You can now add the 'Modern reClock' widget from your Plasma panel."
echo "If the widget is already active, you might need to remove and re-add it to see all changes."