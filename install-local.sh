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

# Qt 6 qmlcachegen: NEVER use the bare 'qmlcachegen' from PATH — it may be
# Qt 5, whose .qmlc bytecode is rejected by the Qt 6 runtime (causes
# "Cannot assign to non-existent property" on local types).
detect_qmlcachegen() {
    local bin
    for cmd in qt6-config qmake6; do
        if command -v "$cmd" &>/dev/null; then
            bin=$("$cmd" -query QT_INSTALL_BINS 2>/dev/null)
            if [ -n "$bin" ] && [ -x "$bin/qmlcachegen" ]; then
                echo "$bin/qmlcachegen"
                return 0
            fi
        fi
    done
    for d in /usr/lib/qt6/bin /usr/lib64/qt6/bin /usr/lib/x86_64-linux-gnu/qt6/bin; do
        [ -x "$d/qmlcachegen" ] && echo "$d/qmlcachegen" && return 0
    done
    # Some distros ship qmlcachegen directly in the QML install dir
    for d in /usr/lib/qt6 /usr/lib64/qt6; do
        [ -x "$d/qmlcachegen" ] && echo "$d/qmlcachegen" && return 0
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

# ---- QML precompilation (qmlc) — instant first-load ----
echo "--- Precompiling QML to bytecode (qmlc) ---"
QMLC_OK=false
QMLCGEN=$(detect_qmlcachegen || true)
if [ -z "$QMLCGEN" ]; then
    echo "no Qt6 qmlcachegen found — runtime QML cache will be used."
else
    echo "Using qmlcachegen: $QMLCGEN ($("$QMLCGEN" --version 2>/dev/null | head -1))"
fi
if [ "$QMLCGEN" != "" ] && [ -f "build/CMakeCache.txt" ]; then
    if cmake --build build --target qmlcache 2>/dev/null; then
        QMLC_OK=true
    fi
fi
if [ "$QMLC_OK" = false ] && [ "$QMLCGEN" != "" ]; then
    for qml in contents/ui/*.qml; do
        qmlc="${qml}c"
        if "$QMLCGEN" "$qml" -o "$qmlc" 2>/dev/null; then
            echo "  $(basename "$qmlc") ($(du -h "$qmlc" | cut -f1))"
            QMLC_OK=true
        else
            echo "  skip: $(basename "$qml")"
            rm -f "$qmlc"
        fi
    done
fi
if [ "$QMLC_OK" = true ]; then
    echo "QML bytecode ready — first config open will skip QML parsing."
    ls -lh contents/ui/*.qmlc 2>/dev/null | awk '{print "  " $9 " " $5}'
else
    echo "No Qt6 qmlcachegen — runtime QML cache will be used."
fi

# ---- Translations ----
echo "--- Preparing translations ---"
if [ -f "translate/build.sh" ]; then
    chmod +x translate/build.sh
    ./translate/build.sh
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

# Restart is unconditional: QML/.qmlc and plugin changes are only picked up
# by a fresh plasmashell. (--fr / -force-reload are kept as harmless no-ops.)
echo "--- Restarting Plasmashell ---"
plasmashell --replace 2>&1 | ./filter-kcm-logs.sh & disown

echo "--- Done! ---"
echo "Add 'Modern reClock' from your panel."