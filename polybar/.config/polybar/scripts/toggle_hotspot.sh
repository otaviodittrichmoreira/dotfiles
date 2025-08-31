#!/usr/bin/env bash
IFACE="wlo1"
SSID="wifidootavio"
PASSWORD="automaker-gurgle-proven"
CON_NAME="Hotspot"

# Check if hotspot is running (interface in AP mode)
MODE=$(nmcli -t -f GENERAL.TYPE,GENERAL.STATE device show "$IFACE" 2>/dev/null | grep GENERAL.TYPE | awk -F: '{print $2}')
STATE=$(nmcli -t -f GENERAL.STATE device show "$IFACE" 2>/dev/null | grep GENERAL.STATE | awk -F: '{print $2}')

if nmcli connection show --active | grep -q "$CON_NAME"; then
    NAME=$(nmcli connection show --active | grep -o "^$CON_NAME\S*")
    echo "󰖪 Stopping Hotspot..."
    nmcli connection down "$NAME"
else
    echo "󰖩 Starting Hotspot..."
    nmcli dev wifi hotspot ifname "$IFACE" ssid "$SSID" password "$PASSWORD"
    sudo sysctl -w net.ipv4.ip_forward=1
    sudo iptables -t nat -A POSTROUTING -o enp2s0 -j MASQUERADE
    sudo iptables -A FORWARD -i wlo1 -o enp2s0 -j ACCEPT
    sudo iptables -A FORWARD -i enp2s0 -o wlo1 -m state --state RELATED,ESTABLISHED -j ACCEPT
fi
