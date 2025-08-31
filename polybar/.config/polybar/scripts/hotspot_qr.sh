#!/usr/bin/env bash

# Configuration
IFACE="wlo1"
SSID="wifidootavio"
PASSWORD="automaker-gurgle-proven"
TERMINAL="alacritty"  # Can be kitty, urxvt, etc.
CON_NAME="Hotspot"

# Generate QR code command
QR_CMD="qrencode -t ansiutf8 \"WIFI:T:WPA;S:$SSID;P:$PASSWORD;;\""

# Open a new terminal and run the QR code
$TERMINAL --title "$CON_NAME" -e bash -c "$QR_CMD; echo; read -p 'Press enter to close...'"
