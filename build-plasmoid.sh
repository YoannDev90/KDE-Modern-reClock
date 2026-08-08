#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

# ---- Defaults ----
WITH_PLUGIN=true
OUTPUT_DIR="."

# ---- Parse args ----
while [[ $# -gt 0 ]]; do
    case "$1" in
        --without-plugin) WITH_PLUGIN=false; shift ;;
        --with-plugin)    WITH_PLUGIN=true; shift ;;
        --output=*)       OUTPUT_DIR="${1#*=}"; shift ;;
        --output)         OUTPUT_DIR="$2"; shift 2 ;;
        -h|--help)
            echo "Usage: $0 [--with-plugin|--without-plugin] [--output=DIR]"
            echo ""
            echo "  --with-plugin     Build C++ plugin and include it (default)"
            echo "  --without-plugin  Skip C++ plugin, generate QML-only .plasmoid"
            echo "  --output=DIR      Output directory (default: .)"
            exit 0 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# ---- Read version from metadata.json ----
VERSION=$(python3 -c "import json,sys; print(json.load(open('metadata.json'))['KPlugin']['Version'])")
PLASMOID_ID=$(python3 -c "import json,sys; print(json.load(open('metadata.json'))['KPlugin']['Id'])")
PLASMOID_NAME="com.github.yoanndev90.modernreclock"

echo "=== Building ${PLASMOID_NAME} v${VERSION} ==="

# ---- Compile translations ----
echo "[1/3] Compiling translations..."
if [ -f "translate/build.sh" ]; then
    chmod +x translate/build.sh
    ./translate/build.sh
else
    echo "  No translate/build.sh found, skipping"
fi

# ---- Build C++ plugin (optional) ----
PLUGIN_INSTALLED=false
if [ "$WITH_PLUGIN" = true ]; then
    echo "[2/3] Building C++ plugin..."
    if command -v cmake &>/dev/null && [ -f "CMakeLists.txt" ]; then
        mkdir -p build && cd build
        if cmake .. -DCMAKE_INSTALL_PREFIX=/usr 2>/dev/null && make -j$(nproc) 2>/dev/null; then
            PLUGIN_INSTALLED=true
            echo "  Plugin built: $(pwd)/libmodernreclock_backend.so"
        else
            echo "  WARNING: Plugin build failed, continuing without plugin"
        fi
        cd ..
    else
        echo "  cmake not found or no CMakeLists.txt, skipping plugin build"
    fi
else
    echo "[2/3] Skipping C++ plugin (--without-plugin)"
fi

# ---- Create .plasmoid ----
echo "[3/3] Creating .plasmoid package..."
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Copy widget files
cp metadata.json "$TMPDIR/"
cp -r contents "$TMPDIR/"

# Include plugin if built
if [ "$PLUGIN_INSTALLED" = true ] && [ -f "build/libmodernreclock_backend.so" ]; then
    mkdir -p "$TMPDIR/contents/code"
    cp build/libmodernreclock_backend.so "$TMPDIR/contents/code/"
    # Copy qmldir
    if [ -f "build/qmldir" ]; then
        cp build/qmldir "$TMPDIR/contents/code/"
    else
        cat > "$TMPDIR/contents/code/qmldir" <<'EOF'
module org.kde.plasma.private.modernreclock
linktarget modernreclock_backend
optional plugin modernreclock_backend
classname ModernRecClockPlugin
depends Qt6Core 6.4
depends Qt6Qml 6.4
EOF
    fi
    echo "  Included C++ plugin"
else
    echo "  No plugin included (QML-only package)"
fi

# Create zip
if [ "$WITH_PLUGIN" = true ] && [ "$PLUGIN_INSTALLED" = true ]; then
    OUTFILE="${OUTPUT_DIR}/${PLASMOID_NAME}-${VERSION}.plasmoid"
    echo "  Plugin included — user will need to run install command on first load"
else
    OUTFILE="${OUTPUT_DIR}/${PLASMOID_NAME}-${VERSION}.plasmoid"
fi

(cd "$TMPDIR" && zip -r "$OLDPWD/$OUTFILE" . -x '*.DS_Store' '*/__MACOSX/*')
echo ""
echo "=== Done! ==="
echo "Output: $OUTFILE"
echo ""
echo "Install with:"
echo "  kpackagetool6 -t Plasma/Applet -i \"$OUTFILE\""
