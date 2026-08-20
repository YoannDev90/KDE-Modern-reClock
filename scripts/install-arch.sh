#!/usr/bin/env bash
# Arch Linux / CachyOS / Manjaro specific install script

PACKAGES_BUILD="gcc cmake qt6-base qt6-declarative fontconfig zlib pkgconf"
PACKAGES_BUILD_NO_CMAKE="gcc qt6-base qt6-declarative fontconfig zlib pkgconf"

install_missing_deps() {
    if [ "$ALL_DEPS_OK" = true ]; then return; fi
    echo ""
    echo "Missing build dependencies for Arch Linux."
    read -p "Install them now with sudo pacman? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        local pkgs=""
        [ "$HAS_CXX" = false ] && pkgs+=" gcc"
        [ "$HAS_QT6" = false ] && pkgs+=" qt6-base qt6-declarative"
        [ "$HAS_MOC" = false ] && pkgs+=" qt6-base"  # moc comes with qt6-base
        [ "$HAS_FONTCONFIG" = false ] && pkgs+=" fontconfig"
        [ "$HAS_ZLIB" = false ] && pkgs+=" zlib"
        [ "$HAS_CMAKE" = false ] && pkgs+=" cmake"
        pkgs=$(echo "$pkgs" | xargs)  # trim
        if [ -n "$pkgs" ]; then
            sudo pacman -S --noconfirm $pkgs
        fi
    else
        echo "Skipping. Will try to download precompiled plugin."
    fi
}

install_missing_deps_hint() {
    echo ""
    echo "Install with: sudo pacman -S gcc cmake qt6-base qt6-declarative fontconfig zlib"
}

# Source common logic and run
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/install-common.sh"
main_install
