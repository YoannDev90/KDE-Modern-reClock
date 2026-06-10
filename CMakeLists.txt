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

# Plugin
add_library(modernreclock_timezone MODULE
    src/timezoneplugin.cpp
)
target_link_libraries(modernreclock_timezone PRIVATE
    Qt6::Core
    Qt6::Qml
    KF6::CoreAddons
)
set_target_properties(modernreclock_timezone PROPERTIES
    PREFIX ""
    SUFFIX "${Qt6_QML_MODULE_SUFFIX}"
)

# Install plugin to KDE QML dir so plasma shell can find it
# KDE_INSTALL_QMLDIR may not resolve; use qt6 qml path as fallback
if(DEFINED KDE_INSTALL_QMLDIR AND NOT "${KDE_INSTALL_QMLDIR}" STREQUAL "")
    set(PLUGIN_INSTALL_DIR ${KDE_INSTALL_QMLDIR}/org/kde/plasma/private/modernreclock)
else()
    set(PLUGIN_INSTALL_DIR ${CMAKE_INSTALL_PREFIX}/lib64/qt6/qml/org/kde/plasma/private/modernreclock)
endif()

install(TARGETS modernreclock_timezone
    LIBRARY DESTINATION ${PLUGIN_INSTALL_DIR}
)

file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/qmldir
    "module org.kde.plasma.private.modernreclock\nplugin modernreclock_timezone\n")
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/qmldir
    DESTINATION ${PLUGIN_INSTALL_DIR}
)