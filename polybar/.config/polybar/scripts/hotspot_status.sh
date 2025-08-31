#!/bin/bash

IFACE="wlo1"

# 1. Check if interface exists
if ! ip link show "$IFACE" &>/dev/null; then
    echo " 󰘊 "
    exit 1
fi

# 2. Check if interface is in AP mode
MODE=$(/usr/sbin/iw dev "$IFACE" info | grep type | awk '{print $2}')
if [ "$MODE" != "AP" ]; then
    echo " 󰘊 "
    exit 1
fi

# 3. Check if NetworkManager reports Hotspot active
if ! nmcli -t -f NAME connection show --active | grep -q "Hotspot"; then
    echo " 󰘊 "
    exit 1
fi

# 4. Count connected clients
CLIENTS=$(/usr/sbin/iw dev "$IFACE" station dump | grep "^Station" | wc -l)

# 5. Check internet connectivity
if ping -q -w 1 -c 1 8.8.8.8 >/dev/null 2>&1; then
    echo "%{F#a6e3a1} 󰘊%{F-} $CLIENTS "
else
    echo "%{F#f38ba8} 󰘊%{F-} $CLIENTS "
fi
