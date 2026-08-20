#!/usr/bin/env bash
# openSUSE specific install script

PACKAGES_BUILD="gcc-c++ cmake libQt6Core-devel libQt6Qml-devel libQt6Gui-devel libQt6Quick-devel libQt6Network-devel libQt6DBus-devel fontconfig-devel zlib-devel pkg-config"
PACKAGES_BUILD_NO_CMAKE="gcc-c++ libQt6Core-devel libQt6Qml-devel libQt6Gui-devel libQt6Quick-devel libQt6Network-devel libQt6DBus-devel fontconfig-devel zlib-devel pkg-config"

install_missing_deps() {
    if [ "$ALL_DEPS_OK" = true ]; then return; fi
    echo ""
    echo "Missing build dependencies for openSUSE."
    read -p "Install them now with sudo zypper? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        local pkgs=""
        [ "$HAS_CXX" = false ] && pkgs+=" gcc-c++"
        [ "$HAS_QT6" = false ] && pkgs+=" libQt6Core-devel libQt6Qml-devel libQt6Gui-devel libQt6Quick-devel libQt6Network-devel libQt6DBus-devel"
        [ "$HAS_MOC" = false ] && pkgs+=" libQt6Core-devel"
        [ "$HAS_FONTCONFIG" = false ] && pkgs+=" fontconfig-devel"
        [ "$HAS_ZLIB" = false ] && pkgs+=" zlib-devel"
        [ "$HAS_CMAKE" = false ] && pkgs+=" cmake"
        pkgs=$(echo "$pkgs" | xargs)
        if [ -n "$pkgs" ]; then
            sudo zypper install -y $pkgs
        fi
    else
        echo "Skipping. Will try to download precompiled plugin."
    fi
}

install_missing_deps_hint() {
    echo ""
    echo "Install with: sudo zypper install gcc-c++ cmake libQt6Core-devel libQt6Qml-devel fontconfig-devel zlib-devel"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/install-common.sh"
main_install
