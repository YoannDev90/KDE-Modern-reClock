#!/usr/bin/env bash
# Fedora specific install script

PACKAGES_BUILD="gcc-c++ cmake qt6-qtbase-devel qt6-qtdeclarative-devel fontconfig-devel zlib-devel"
PACKAGES_BUILD_NO_CMAKE="gcc-c++ qt6-qtbase-devel qt6-qtdeclarative-devel fontconfig-devel zlib-devel"

install_missing_deps() {
    if [ "$ALL_DEPS_OK" = true ]; then return; fi
    echo ""
    echo "Missing build dependencies for Fedora."
    read -p "Install them now with sudo dnf? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        local pkgs=""
        [ "$HAS_CXX" = false ] && pkgs+=" gcc-c++"
        [ "$HAS_QT6" = false ] && pkgs+=" qt6-qtbase-devel qt6-qtdeclarative-devel"
        [ "$HAS_MOC" = false ] && pkgs+=" qt6-qtbase-devel"
        [ "$HAS_FONTCONFIG" = false ] && pkgs+=" fontconfig-devel"
        [ "$HAS_ZLIB" = false ] && pkgs+=" zlib-devel"
        [ "$HAS_CMAKE" = false ] && pkgs+=" cmake"
        pkgs=$(echo "$pkgs" | xargs)
        if [ -n "$pkgs" ]; then
            sudo dnf install -y $pkgs
        fi
    else
        echo "Skipping. Will try to download precompiled plugin."
    fi
}

install_missing_deps_hint() {
    echo ""
    echo "Install with: sudo dnf install gcc-c++ cmake qt6-qtbase-devel qt6-qtdeclarative-devel fontconfig-devel zlib-devel"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/install-common.sh"
main_install
