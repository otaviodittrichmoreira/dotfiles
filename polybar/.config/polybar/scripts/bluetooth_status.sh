#!/bin/bash

status_file="/tmp/polybar-bluetooth-status"

# Check if a temporary status (like "Connecting...") exists
if [ -f "$status_file" ]; then
    cat "$status_file"
    rm "$status_file"
    exit 0
fi

# No temp file -> show real Bluetooth status
power=$(bluetoothctl show | grep "Powered:" | awk '{print $2}')

if [ "$power" == "yes" ]; then
    device_info=$(bluetoothctl info)

    device_name=$(echo "$device_info" | grep "Name:" | awk '{print substr($0, index($0,$2))}')
    battery_level=$(echo "$device_info" | grep "Battery Percentage:" | awk '{print $3}')

    if [ -n "$device_name" ]; then
        if [ -n "$battery_level" ]; then
            echo " $device_name ($battery_level%)"
        else
            echo " $device_name" 
        fi
    else
        echo " On"
    fi
else
    echo "󰂲 Off"
fi
