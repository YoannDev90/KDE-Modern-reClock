cmake_minimum_required(VERSION 3.16)
project(modernreclock VERSION 2.6.3 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

include(GNUInstallDirs)

# Qt 6
find_package(Qt6 6.4 REQUIRED COMPONENTS Core Qml Gui Quick Network DBus)

# Zlib for CRC32 in zip archive
find_package(ZLIB REQUIRED)

# Fontconfig for font path resolution
find_package(PkgConfig REQUIRED)
pkg_check_modules(FONTCONFIG REQUIRED fontconfig)

# Plugin — keep default "lib" prefix so the .so is named libmodernreclock_backend.so
# which matches what qmldir expects (plugin <name> → lib<name>.so)
set(PLUGIN_NAME modernreclock_backend)

add_library(${PLUGIN_NAME} MODULE
    src/plugin.cpp
    src/timezonehelper.cpp
    src/wallpaperhelper.cpp
    src/wallpaperimageprovider.cpp
    src/wallpaperconfig.cpp
    src/logger.cpp
    src/thememanager.cpp
    src/mrtarchive.cpp
)
target_link_libraries(${PLUGIN_NAME} PRIVATE
    Qt6::Core
    Qt6::Qml
    Qt6::Gui
    Qt6::Quick
    Qt6::Network
    Qt6::DBus
    ${FONTCONFIG_LIBRARIES}
    ZLIB::ZLIB
)
target_include_directories(${PLUGIN_NAME} PRIVATE ${FONTCONFIG_INCLUDE_DIRS})

# Install plugin to KDE QML dir so plasma shell can find it
# KDE_INSTALL_QMLDIR may not resolve; use qt6 qml path as fallback
if(DEFINED KDE_INSTALL_QMLDIR AND NOT "${KDE_INSTALL_QMLDIR}" STREQUAL "")
    set(PLUGIN_INSTALL_DIR ${KDE_INSTALL_QMLDIR}/org/kde/plasma/private/modernreclock)
else()
    set(PLUGIN_INSTALL_DIR ${CMAKE_INSTALL_PREFIX}/lib64/qt6/qml/org/kde/plasma/private/modernreclock)
endif()

install(TARGETS ${PLUGIN_NAME}
    LIBRARY DESTINATION ${PLUGIN_INSTALL_DIR}
)

# Generate qmldir matching KDE convention (see containmentlayoutmanager, digitalclock, etc.)
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/qmldir
    "module org.kde.plasma.private.modernreclock\n"
    "linktarget ${PLUGIN_NAME}\n"
    "optional plugin ${PLUGIN_NAME}\n"
    "classname ModernRecClockPlugin\n"
    "depends Qt6Core 6.4\n"
    "depends Qt6Qml 6.4\n"
)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/qmldir
    DESTINATION ${PLUGIN_INSTALL_DIR}
)