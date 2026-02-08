#!/bin/bash

# Polybar ProtonVPN module
# Requires: protonvpn-cli (official)

ICON_ON="󰖂"
ICON_OFF="󰖃"
ICON_ERR="󰖂"

COLOR_ON="#a6e3a1"
COLOR_OFF="#f38ba8"
COLOR_ERR="#f9e2af"

# ProtonVPN CLI sometimes lives under different names
if command -v protonvpn-cli >/dev/null 2>&1; then
    STATUS=$(protonvpn-cli status 2>/dev/null)
elif command -v protonvpn >/dev/null 2>&1; then
    STATUS=$(protonvpn status 2>/dev/null)
else
    echo "%{F$COLOR_ERR}$ICON_ERR no-cli%{F-}"
    exit 0
fi

if echo "$STATUS" | grep -qi "Connected"; then
    SERVER=$(echo "$STATUS" | awk -F': ' '/Server/ {print $2}')
    COUNTRY=$(echo "$STATUS" | awk -F': ' '/Country/ {print $2}')

    # Prefer country, fallback to server
    LABEL=${COUNTRY:-$SERVER}

    echo "%{F$COLOR_ON}$ICON_ON $LABEL%{F-}"
    exit 0
fi

if echo "$STATUS" | grep -qi "Disconnected"; then
    echo "%{F$COLOR_OFF}$ICON_OFF Off%{F-}"
    exit 0
fi

# Unknown / error state
echo "%{F$COLOR_ERR}$ICON_ERR ?%{F-}"
