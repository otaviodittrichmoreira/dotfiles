#!/usr/bin/env bash

# Configuration
IFACE="wlo1"
SSID="wifidootavio"
PASSWORD="prevalent-passenger-quickstep"
TERMINAL="alacritty"
CON_NAME="HotspotQR"  # Unique title for the terminal

# Check if terminal with this title is running
PID=$(pgrep -f "$TERMINAL.*$CON_NAME")

if [ -n "$PID" ]; then
    # If running, kill it
    kill "$PID"
    echo "Closed existing QR terminal."
else
    # If not running, open new terminal with QR code
    $TERMINAL --title "$CON_NAME" -e bash -c "qrencode -t ansiutf8 \"WIFI:T:WPA;S:$SSID;P:$PASSWORD;;\"; read -p ''" &
    echo "Opened QR terminal."
fi
