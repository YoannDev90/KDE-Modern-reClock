#!/usr/bin/env bash
# Common install logic shared across all distro scripts.
# Do not run directly — source from install-{distro}.sh after setting:
#   PACKAGES_BUILD, PACKAGES_BUILD_NO_CMAKE, install_missing_deps()

set -e

REPO_URL="https://github.com/YoannDev90/KDE-Modern-reClock"
RELEASE_API="https://api.github.com/repos/YoannDev90/KDE-Modern-reClock/releases/latest"

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

# ---- Dependency Detection ----

detect_build_deps() {
    HAS_CXX=false; HAS_CMAKE=false; HAS_QT6=false
    HAS_MOC=false; HAS_FONTCONFIG=false; HAS_ZLIB=false
    CXX=""; MOC=""

    # C++ compiler
    if command -v g++ &>/dev/null; then CXX="g++"; HAS_CXX=true
    elif command -v clang++ &>/dev/null; then CXX="clang++"; HAS_CXX=true
    fi

    # cmake
    command -v cmake &>/dev/null && HAS_CMAKE=true

    # Qt6 via pkg-config
    pkg-config --exists Qt6Core Qt6Qml Qt6Gui Qt6Quick Qt6Network Qt6DBus 2>/dev/null && HAS_QT6=true

    # moc (Qt meta-object compiler) — search common Qt6 paths
    for moc_path in \
        /usr/lib/qt6/libexec/moc \
        /usr/lib64/qt6/libexec/moc \
        /usr/lib/x86_64-linux-gnu/qt6/libexec/moc \
        /usr/lib/qt6/bin/moc \
        /usr/lib64/qt6/bin/moc; do
        if [ -x "$moc_path" ]; then
            MOC="$moc_path"
            HAS_MOC=true
            break
        fi
    done
    if [ "$HAS_MOC" = false ]; then
        # Try via qmake6 to find moc
        for cmd in qmake6 qt6-config; do
            if command -v "$cmd" &>/dev/null; then
                QT_HOST_BINS=$("$cmd" -query QT_HOST_BINS 2>/dev/null)
                if [ -n "$QT_HOST_BINS" ] && [ -x "$QT_HOST_BINS/moc" ]; then
                    MOC="$QT_HOST_BINS/moc"
                    HAS_MOC=true
                    break
                fi
            fi
        done
    fi
    # Fallback to PATH-based search
    if [ "$HAS_MOC" = false ]; then
        if command -v moc-qt6 &>/dev/null; then MOC="moc-qt6"; HAS_MOC=true
        elif command -v moc &>/dev/null; then MOC="moc"; HAS_MOC=true
        fi
    fi

    # fontconfig
    pkg-config --exists fontconfig 2>/dev/null && HAS_FONTCONFIG=true
    [ -f /usr/include/fontconfig/fontconfig.h ] && HAS_FONTCONFIG=true

    # zlib
    pkg-config --exists zlib 2>/dev/null && HAS_ZLIB=true
    [ -f /usr/include/zlib.h ] && HAS_ZLIB=true
    [ -f /usr/include/zlib-ng/zlib.h ] && HAS_ZLIB=true  # Arch/cachyOS zlib-ng

    ALL_DEPS_OK=true
    MISSING=()
    if [ "$HAS_CXX" = false ]; then MISSING+=("C++ compiler"); fi
    if [ "$HAS_QT6" = false ]; then MISSING+=("Qt6 development headers"); fi
    if [ "$HAS_MOC" = false ]; then MISSING+=("Qt6 moc"); fi
    if [ "$HAS_FONTCONFIG" = false ]; then MISSING+=("fontconfig headers"); fi
    if [ "$HAS_ZLIB" = false ]; then MISSING+=("zlib headers"); fi
    if [ ${#MISSING[@]} -gt 0 ]; then ALL_DEPS_OK=false; fi
}

report_deps() {
    echo "Build dependencies:"
    echo "  C++ compiler : ${CXX:-NOT FOUND}"
    echo "  cmake        : ${HAS_CMAKE}"
    echo "  Qt6 headers  : ${HAS_QT6}"
    echo "  moc          : ${MOC:-NOT FOUND}"
    echo "  fontconfig   : ${HAS_FONTCONFIG}"
    echo "  zlib         : ${HAS_ZLIB}"
    if [ "$ALL_DEPS_OK" = false ]; then
        echo "Missing: ${MISSING[*]}"
    fi
}

# ---- Build Strategies ----

try_cmake_build() {
    if [ "$HAS_CMAKE" = false ] || [ ! -f "CMakeLists.txt" ]; then
        return 1
    fi
    echo "Building with cmake..."
    (
        mkdir -p build && cd build
        cmake .. -DCMAKE_INSTALL_PREFIX=/usr 2>&1 && make -j$(nproc) 2>&1
    )
    if [ $? -eq 0 ]; then
        # Copy .so and qmldir directly instead of sudo make install (needs terminal for password)
        # Try without sudo first (dir may exist from previous install), then with sudo
        if cp build/libmodernreclock_backend.so "$PLUGIN_DIR/" 2>/dev/null; then
            cp build/qmldir "$PLUGIN_DIR/" 2>/dev/null || true
        else
            sudo mkdir -p "$PLUGIN_DIR"
            sudo cp build/libmodernreclock_backend.so "$PLUGIN_DIR/"
            sudo cp build/qmldir "$PLUGIN_DIR/" 2>/dev/null || true
        fi
        echo "Build successful (cmake)."
        return 0
    fi
    echo "cmake build failed."
    return 1
}

try_direct_compile() {
    if [ "$HAS_CXX" = false ] || [ "$HAS_MOC" = false ] || [ "$HAS_QT6" = false ]; then
        return 1
    fi
    if [ "$HAS_FONTCONFIG" = false ] || [ "$HAS_ZLIB" = false ]; then
        return 1
    fi

    echo "Building directly with $CXX (no cmake)..."
    mkdir -p build

    # Qt6 flags
    local qt6_cflags qt6_libs fc_cflags fc_libs
    qt6_cflags=$(pkg-config --cflags Qt6Core Qt6Qml Qt6Gui Qt6Quick Qt6Network Qt6DBus 2>/dev/null)
    qt6_libs=$(pkg-config --libs Qt6Core Qt6Qml Qt6Gui Qt6Quick Qt6Network Qt6DBus 2>/dev/null)
    fc_cflags=$(pkg-config --cflags fontconfig 2>/dev/null)
    fc_libs=$(pkg-config --libs fontconfig 2>/dev/null)

    # Run moc on headers with Q_OBJECT
    echo "  Running moc..."
    $MOC src/logger.h -o build/moc_logger.cpp
    $MOC src/thememanager.h -o build/moc_thememanager.cpp
    $MOC src/timezonehelper.h -o build/moc_timezonehelper.cpp
    $MOC src/wallpaperhelper.h -o build/moc_wallpaperhelper.cpp
    # plugin.cpp has inline Q_OBJECT class, needs #include "plugin.moc"
    $MOC src/plugin.cpp -o build/plugin.moc

    # Compile
    echo "  Compiling..."
    $CXX -std=c++17 -fPIC -shared -O2 \
        -I build \
        $qt6_cflags $fc_cflags \
        src/plugin.cpp \
        src/timezonehelper.cpp \
        src/wallpaperhelper.cpp \
        src/wallpaperimageprovider.cpp \
        src/wallpaperconfig.cpp \
        src/logger.cpp \
        src/thememanager.cpp \
        src/mrtarchive.cpp \
        build/moc_logger.cpp \
        build/moc_thememanager.cpp \
        build/moc_timezonehelper.cpp \
        build/moc_wallpaperhelper.cpp \
        -o build/libmodernreclock_backend.so \
        $qt6_libs $fc_libs -lz 2>&1

    if [ $? -ne 0 ]; then
        echo "Direct compilation failed."
        return 1
    fi

    # Generate qmldir
    cat > build/qmldir <<'QMLEOF'
module org.kde.plasma.private.modernreclock
linktarget modernreclock_backend
optional plugin modernreclock_backend
classname ModernRecClockPlugin
depends Qt6Core 6.4
depends Qt6Qml 6.4
QMLEOF

    # Install
    if cp build/libmodernreclock_backend.so "$PLUGIN_DIR/" 2>/dev/null; then
        cp build/qmldir "$PLUGIN_DIR/" 2>/dev/null || true
    else
        sudo mkdir -p "$PLUGIN_DIR"
        sudo cp build/libmodernreclock_backend.so "$PLUGIN_DIR/"
        sudo cp build/qmldir "$PLUGIN_DIR/"
    fi

    echo "Build successful (direct compilation)."
    return 0
}

try_download_precompiled() {
    echo "Downloading precompiled plugin..."

    check_dep curl
    check_dep unzip

    local arch
    ARCH=$(uname -m)
    LATEST_TAG=$(curl -sf "$RELEASE_API" 2>/dev/null \
        | grep -oP '"tag_name":\s*"\K[^"]+' || echo "")

    if [ -z "$LATEST_TAG" ]; then
        echo "Could not fetch latest release info."
        return 1
    fi

    local download_url="https://github.com/YoannDev90/KDE-Modern-reClock/releases/download/${LATEST_TAG}/modernreclock-plugins-${LATEST_TAG#v}-${ARCH}.zip"
    local tmpzip
    tmpzip=$(mktemp /tmp/modernreclock-plugins-XXXXXX.zip)

    if ! curl -fSL "$download_url" -o "$tmpzip" 2>/dev/null; then
        echo "Download failed: $download_url"
        rm -f "$tmpzip"
        return 1
    fi

    local tmpdir
    tmpdir=$(mktemp -d)
    unzip -qo "$tmpzip" -d "$tmpdir" 2>/dev/null

    if [ -f "${tmpdir}/${ARCH}/libmodernreclock_backend.so" ]; then
        if cp "${tmpdir}/${ARCH}/libmodernreclock_backend.so" "$PLUGIN_DIR/" 2>/dev/null; then
            cp "${tmpdir}/${ARCH}/qmldir" "$PLUGIN_DIR/" 2>/dev/null || true
        else
            sudo mkdir -p "$PLUGIN_DIR"
            sudo cp "${tmpdir}/${ARCH}/libmodernreclock_backend.so" "$PLUGIN_DIR/"
            sudo cp "${tmpdir}/${ARCH}/qmldir" "$PLUGIN_DIR/"
        fi
        rm -rf "$tmpdir" "$tmpzip"
        echo "Precompiled plugin installed."
        return 0
    fi

    echo "Precompiled archive did not contain expected files."
    rm -rf "$tmpdir" "$tmpzip"
    return 1
}

# ---- Widget Install ----

install_widget() {
    echo "--- Installing the widget ---"
    kpackagetool6 -t Plasma/Applet -u . || kpackagetool6 -t Plasma/Applet -i .
}

# ---- Main ----

restart_plasmashell() {
    echo "--- Restarting plasmashell ---"
    if command -v plasmashell &>/dev/null; then
        killall plasmashell 2>/dev/null || true
        sleep 1
        nohup plasmashell &>/dev/null &
        echo "plasmashell restarted."
    else
        echo "plasmashell not found, skipping restart."
    fi
}

main_install() {
    # Preflight
    check_dep kpackagetool6
    check_dep git

    # C++ Plugins
    echo "--- Installing C++ plugins ---"
    QML_BASE=$(detect_qml_dir) || { echo "Error: cannot find Qt6 QML directory"; exit 1; }
    PLUGIN_DIR="${QML_BASE}/org/kde/plasma/private/modernreclock"
    echo "Plugin dir: ${PLUGIN_DIR}"
    PLUGIN_INSTALLED=false

    # Detect dependencies
    detect_build_deps
    report_deps

    # Try to let the distro script install missing deps
    if [ "$ALL_DEPS_OK" = false ]; then
        install_missing_deps
        # Re-detect after install attempt
        detect_build_deps
        report_deps
    fi

    # Strategy 1: cmake
    if [ "$PLUGIN_INSTALLED" = false ] && [ "$ALL_DEPS_OK" = true ]; then
        try_cmake_build && PLUGIN_INSTALLED=true
    fi

    # Strategy 2: direct compilation
    if [ "$PLUGIN_INSTALLED" = false ] && [ "$ALL_DEPS_OK" = true ]; then
        try_direct_compile && PLUGIN_INSTALLED=true
    fi

    # Strategy 3: download precompiled
    if [ "$PLUGIN_INSTALLED" = false ]; then
        try_download_precompiled && PLUGIN_INSTALLED=true
    fi

    # Final warning
    if [ "$PLUGIN_INSTALLED" = false ]; then
        echo ""
        echo "Warning: Could not install C++ plugins. Some features may not work:"
        echo "  - Secondary timezone"
        echo "  - Wallpaper detection & preview"
        echo "  - Structured logging & debug export"
        if [ ${#MISSING[@]} -gt 0 ]; then
            echo ""
            echo "Missing dependencies: ${MISSING[*]}"
            if type install_missing_deps_hint &>/dev/null; then
                install_missing_deps_hint
            fi
        fi
    fi

    # Widget
    install_widget

    # Restart plasmashell if requested
    restart_plasmashell

    echo ""
    echo "--- Done! ---"
    echo "Add 'Modern reClock' from your panel. Remove and re-add if already active."
}
