#!/usr/bin/env bash
set -e

REPO_URL="https://github.com/YoannDev90/KDE-Modern-reClock"

# ---- Helpers ----
detect_qml_dir() {
    for cmd in qt6-config qmake6; do
        if command -v "$cmd" &>/dev/null; then
            local dir
            dir=$("$cmd" -query QT_INSTALL_QML 2>/dev/null) && [ -n "$dir" ] && echo "$dir" && return 0
        fi
    done
    for d in /usr/lib/qt6/qml /usr/lib64/qt6/qml /usr/lib/x86_64-linux-gnu/qt6/qml; do
        [ -d "$d" ] && echo "$d" && return 0
    done
    return 1
}

check_dep() {
    if ! command -v "$1" &>/dev/null; then
        echo "Error: '$1' not found. Install it and retry."
        exit 1
    fi
}

# ---- Preflight ----
check_dep kpackagetool6
check_dep git

TEMP_DIR=$(mktemp -d)

echo "--- Downloading Modern reClock ---"
git clone --depth 1 "$REPO_URL" "$TEMP_DIR"
cd "$TEMP_DIR"

# ---- Translations ----
echo "--- Preparing translations ---"
if [ -f "translate/build.sh" ]; then
    chmod +x translate/build.sh
    ./translate/build.sh
fi

# ---- C++ Plugins ----
echo "--- Installing C++ plugins ---"
QML_BASE=$(detect_qml_dir) || { echo "Error: cannot find Qt6 QML directory"; exit 1; }
PLUGIN_DIR="${QML_BASE}/org/kde/plasma/private/modernreclock"
echo "Plugin dir: ${PLUGIN_DIR}"
PLUGIN_INSTALLED=false

if command -v cmake &>/dev/null && [ -f "CMakeLists.txt" ]; then
    echo "Building from source..."
    mkdir -p build && cd build
    if cmake .. -DCMAKE_INSTALL_PREFIX=/usr 2>/dev/null && make -j$(nproc) 2>/dev/null; then
        sudo make install 2>/dev/null && PLUGIN_INSTALLED=true
    fi
    cd ..
fi

if [ "$PLUGIN_INSTALLED" = false ]; then
    check_dep curl
    check_dep unzip

    ARCH=$(uname -m)
    LATEST_TAG=$(curl -s "https://api.github.com/repos/YoannDev90/KDE-Modern-reClock/releases/latest" 2>/dev/null \
        | grep -oP '"tag_name":\s*"\K[^"]+' || echo "")
    if [ -n "$LATEST_TAG" ]; then
        DOWNLOAD_URL="https://github.com/YoannDev90/KDE-Modern-reClock/releases/download/${LATEST_TAG}/modernreclock-plugins-${LATEST_TAG#v}-${ARCH}.zip"
        echo "Downloading precompiled plugin (${ARCH}) from ${LATEST_TAG}..."
        TMPZIP=$(mktemp /tmp/modernreclock-plugins-XXXXXX.zip)
        if curl -fSL "$DOWNLOAD_URL" -o "$TMPZIP" 2>/dev/null; then
            TMPDIR=$(mktemp -d)
            unzip -qo "$TMPZIP" -d "$TMPDIR" 2>/dev/null
            if [ -f "${TMPDIR}/${ARCH}/libmodernreclock_backend.so" ]; then
                sudo mkdir -p "$PLUGIN_DIR"
                sudo cp "${TMPDIR}/${ARCH}/libmodernreclock_backend.so" "$PLUGIN_DIR/"
                sudo cp "${TMPDIR}/${ARCH}/qmldir" "$PLUGIN_DIR/"
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


# ---- Widget ----
echo "--- Installing the widget ---"
kpackagetool6 -t Plasma/Applet -u . || kpackagetool6 -t Plasma/Applet -i .

# ---- Cleanup ----
echo "--- Cleaning up ---"
rm -rf "$TEMP_DIR"

echo "--- Done! ---"
echo "Add 'Modern reClock' from your panel. Remove and re-add if already active."