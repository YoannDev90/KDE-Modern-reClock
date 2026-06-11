cmake_minimum_required(VERSION 3.16)
project(modernreclock VERSION 1.3.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

include(GNUInstallDirs)

# Qt 6
find_package(Qt6 6.4 REQUIRED COMPONENTS Core Qml)

# KF6 — no umbrella "KF6" package, use individual components
find_package(KF6CoreAddons REQUIRED)

# Plugin — keep default "lib" prefix so the .so is named libmodernreclock_timezone.so
# which matches what qmldir expects (plugin <name> → lib<name>.so)
set(PLUGIN_NAME modernreclock_timezone)

add_library(${PLUGIN_NAME} MODULE
    src/timezoneplugin.cpp
)
target_link_libraries(${PLUGIN_NAME} PRIVATE
    Qt6::Core
    Qt6::Qml
    KF6::CoreAddons
)

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
)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/qmldir
    DESTINATION ${PLUGIN_INSTALL_DIR}
)