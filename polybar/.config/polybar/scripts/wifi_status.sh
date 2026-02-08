#!/bin/bash

IFACE="wlp130s0"
ETHERNET="enp2s0"

# Check if ethernet cable is connected
if nmcli device status | grep -q "$ETHERNET.*connected"; then
    if ping -q -w 1 -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo "%{F#a6e3a1}󰈁%{F-} ETH"
    else
        echo "%{F#f38ba8}󰈁 %{F-} ETH"
    fi
    exit 0
fi

# Check if Wi-Fi is disabled
if [ "$(nmcli radio wifi)" = "disabled" ]; then
    echo "󰖪 Off"  # You can also use 🚫 or ❌
    exit 0
fi

# NordVPN helpers
nordvpn_connected() {
    nordvpn status 2>/dev/null | grep -q "Status: Connected"
}

nordvpn_country() {
    nordvpn status 2>/dev/null | awk -F': ' '/Country/ {print $2}'
}


if nmcli device status | grep -q "$IFACE.*connected"; then
    ESSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
    SIGNAL=$(nmcli -f IN-USE,SIGNAL dev wifi | grep '*' | awk '{print $2}')
    BAR=""

    if [[ "$SIGNAL" =~ ^[0-9]+$ ]]; then
        if ping -q -w 1 -c 1 8.8.8.8 >/dev/null 2>&1; then
            # if nordvpn_connected; then # Remove bc I have a module for VPN now
            if false; then
                # Signal bars
                if [ "$SIGNAL" -ge 80 ]; then
                    BAR="%{F#a6e3a1}󰤪%{F-}"
                elif [ "$SIGNAL" -ge 60 ]; then
                    BAR="%{F#a6e3a1}󰤧%{F-}"
                elif [ "$SIGNAL" -ge 40 ]; then
                    BAR="%{F#a6e3a1}󰤤%{F-}"
                elif [ "$SIGNAL" -ge 20 ]; then
                    BAR="%{F#a6e3a1}󰤡%{F-}"
                else
                    BAR="%{F#a6e3a1}󰤬%{F-}"
                fi
            else
                # Signal bars
                if [ "$SIGNAL" -ge 80 ]; then
                    BAR="%{F#a6e3a1}󰤨%{F-}"
                elif [ "$SIGNAL" -ge 60 ]; then
                    BAR="%{F#a6e3a1}󰤥%{F-}"
                elif [ "$SIGNAL" -ge 40 ]; then
                    BAR="%{F#a6e3a1}󰤢%{F-}"
                elif [ "$SIGNAL" -ge 20 ]; then
                    BAR="%{F#a6e3a1}󰤟%{F-}"
                else
                    BAR="%{F#a6e3a1}󰤯%{F-}"
                fi
            fi
        else
            # Signal bars
            if [ "$SIGNAL" -ge 80 ]; then
                BAR="%{F#f38ba8}󰤩%{F-}"
            elif [ "$SIGNAL" -ge 60 ]; then
                BAR="%{F#f38ba8}󰤦%{F-}"
            elif [ "$SIGNAL" -ge 40 ]; then
                BAR="%{F#f38ba8}󰤣%{F-}"
            elif [ "$SIGNAL" -ge 20 ]; then
                BAR="%{F#f38ba8}󰤠%{F-}"
            else
                BAR="%{F#f38ba8}󰤫%{F-}"
            fi
        fi
    else
        BAR="%{F#a6e3a1}󰖩%{F-} "
    fi

    # # VPN check (looks for tun0, wg0, or nmcli VPN)
    # if ip a | grep -qE 'tun0|wg0'; then
    #     VPN=" 🔐"
    # elif nmcli connection show --active | grep -qi vpn; then
    #     VPN=" 🔐"
    # else
    #     VPN=""
    # fi
    #
    #
    # if ping -q -w 1 -c 1 8.8.8.8 >/dev/null 2>&1; then
    #     INTERNET=""
    # else
    #     INTERNET=" "
    # fi

    echo "$BAR $ESSID"

else
    echo " Disconnected"
fi
