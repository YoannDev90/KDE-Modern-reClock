#!/usr/bin/env bash
set -e

REPO_URL="https://github.com/YoannDev90/KDE-Modern-reClock"

# ---- Detect distro ----
detect_distro() {
    local id id_like
    id=$(grep -oP '^ID=\K.*' /etc/os-release 2>/dev/null || echo "")
    id_like=$(grep -oP '^ID_LIKE=\K.*' /etc/os-release 2>/dev/null || echo "")

    # Match by ID first, then by ID_LIKE
    for distro in "$id" "$id_like"; do
        case "$distro" in
            fedora|rhel|centos|rocky|alma|nobara) echo "fedora"; return ;;
            debian|ubuntu|linuxmint|pop|kdeaneon|zorin|elementary|raspbian) echo "debian"; return ;;
            arch|manjaro|endeavouros|cachyos|garuda|artix) echo "arch"; return ;;
            suse|opensuse|sles) echo "suse"; return ;;
        esac
    done
    echo "unknown"
}

DISTRO=$(detect_distro)

if [ "$DISTRO" = "unknown" ]; then
    echo "Unsupported distro. Install manually:"
    echo "  - C++ compiler (g++ or clang++)"
    echo "  - cmake (optional)"
    echo "  - Qt6 development headers"
    echo "  - fontconfig development headers"
    echo "  - zlib development headers"
    echo "Then clone the repo and run: bash scripts/install-common.sh"
    exit 1
fi

echo "Detected: $DISTRO"

# ---- Clone repo ----
TEMP_DIR=$(mktemp -d)
echo "--- Downloading Modern reClock ---"
git clone --depth 1 "$REPO_URL" "$TEMP_DIR"
cd "$TEMP_DIR"

# ---- Run distro script ----
chmod +x "scripts/install-${DISTRO}.sh"
source "scripts/install-${DISTRO}.sh"

# ---- Cleanup ----
rm -rf "$TEMP_DIR"
