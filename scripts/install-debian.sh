#!/usr/bin/env bash
# Debian / Ubuntu / Linux Mint / Pop!_OS specific install script

PACKAGES_BUILD="g++ cmake qt6-base-dev qt6-declarative-dev libfontconfig1-dev zlib1g-dev pkg-config"
PACKAGES_BUILD_NO_CMAKE="g++ qt6-base-dev qt6-declarative-dev libfontconfig1-dev zlib1g-dev pkg-config"

install_missing_deps() {
    if [ "$ALL_DEPS_OK" = true ]; then return; fi
    echo ""
    echo "Missing build dependencies for Debian/Ubuntu."
    read -p "Install them now with sudo apt? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo apt-get update -qq
        local pkgs=""
        [ "$HAS_CXX" = false ] && pkgs+=" g++"
        [ "$HAS_QT6" = false ] && pkgs+=" qt6-base-dev qt6-declarative-dev"
        [ "$HAS_MOC" = false ] && pkgs+=" qt6-base-dev"
        [ "$HAS_FONTCONFIG" = false ] && pkgs+=" libfontconfig1-dev"
        [ "$HAS_ZLIB" = false ] && pkgs+=" zlib1g-dev"
        [ "$HAS_CMAKE" = false ] && pkgs+=" cmake"
        pkgs=$(echo "$pkgs" | xargs)
        if [ -n "$pkgs" ]; then
            sudo apt-get install -y $pkgs
        fi
    else
        echo "Skipping. Will try to download precompiled plugin."
    fi
}

install_missing_deps_hint() {
    echo ""
    echo "Install with: sudo apt install g++ cmake qt6-base-dev qt6-declarative-dev libfontconfig1-dev zlib1g-dev"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/install-common.sh"
main_install
