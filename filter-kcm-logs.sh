#!/usr/bin/env bash
# Filter Plasma/KCM config-dialog noise; keep only the actionable QML errors.
#
# Usage:
#   plasmashell --replace 2>&1 | filter-kcm-logs.sh
#
# Drops the benign messages that flood the output when opening a plasmoid
# configuration dialogs: pointless propertyCache warnings, the KCM framework
# pushing unrelated cfg_* keys onto every page ("Setting initial properties
# failed"), the DBus deprecation notice, and the helper "Component is not
# ready" line that always precedes the real page error.

grep -vE \
  -e 'qt\.qml\.propertyCache\.append:' \
  -e 'Connecting to deprecated signal QDBusConnectionInterface::serviceOwnerChanged' \
  -e 'Setting initial properties failed:' \
  -e 'Created graphical object was not placed in the graphics scene' \
  -e '^QQmlComponent: Component is not ready$' \
  -e 'ConfigurationShortcuts' \
  "$@"