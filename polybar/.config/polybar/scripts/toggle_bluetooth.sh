#!/bin/bash

status_file="/tmp/polybar-bluetooth-status"

power=$(bluetoothctl show | grep "Powered:" | awk '{print $2}')

if [ "$power" == "yes" ]; then
    echo "🔌 Disconnecting…" > "$status_file"
    bluetoothctl power off
else
    echo "🔄 Connecting…" > "$status_file"
    bluetoothctl power on
fi

# Wait a little before status script updates naturally
sleep 1

# After 1 second, the bluetooth_status.sh script will overwrite the status again automatically
