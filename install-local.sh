#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

# ---- Helpers ----
detect_qml_dir() {
    for cmd in qt6-config qmake6; do
        if command -v "$cmd" &>/dev/null; then
            local dir
            dir=$("$cmd" -query QT_INSTALL_QML 2>/dev/null) && [ -n "$dir" ] && echo "$dir" && return 0
        fi
    done
    # Fallback: common paths
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

# ---- Detect QML dir ----
QML_BASE=$(detect_qml_dir) || { echo "Error: cannot find Qt6 QML directory"; exit 1; }
PLUGIN_DIR="${QML_BASE}/org/kde/plasma/private/modernreclock"
echo "Plugin dir: ${PLUGIN_DIR}"

# ---- C++ Plugins ----
echo "--- Installing C++ plugins ---"
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
    echo "  - Secondary timezone (TimeZoneHelper)"
    echo "  - Wallpaper detection & preview (WallpaperHelper, WallpaperImageProvider)"
    echo "  - Logger (structured logging, async log fetch, export)"
    echo "Install cmake and kf6-devel packages to build from source, or open an issue."
fi

# ---- Translations ----
echo "--- Preparing translations ---"
if [ -f "translate/build.sh" ]; then
    chmod +x translate/build.sh
    ./translate/build.sh
fi

# ---- MIME ----
echo "--- Registering .mrt MIME type ---"
if [ -f "pkg/mime/modernreclock-theme.xml" ]; then
    MIME_DIR="${HOME}/.local/share/mime/packages"
    mkdir -p "$MIME_DIR"
    cp pkg/mime/modernreclock-theme.xml "$MIME_DIR/"
    command -v update-mime-database &>/dev/null && update-mime-database "${HOME}/.local/share/mime" 2>/dev/null || true
    echo "  .mrt → ZIP"
fi

# ---- Widget ----
echo "--- Installing the widget ---"
kpackagetool6 -t Plasma/Applet -u . || kpackagetool6 -t Plasma/Applet -i .

# ---- Cache ----
echo "--- Cleaning cache ---"
rm -rf ~/.cache/plasmashell/qmlcache/*modernreclock* 2>/dev/null || true
rm -rf ~/.cache/kpackage/.*modernreclock* 2>/dev/null || true
rm -rf ~/.cache/kirigami/*modernreclock* 2>/dev/null || true
find ~/.cache -name "*.qmlc" -path "*modernreclock*" -delete 2>/dev/null || true

if [[ " $* " == *" -force-reload "* ]] || [[ " $* " == *" --fr "* ]]; then
    echo "--- Restarting Plasmashell ---"
    plasmashell --replace & disown
fi

echo "--- Done! ---"
echo "Add 'Modern reClock' from your panel."