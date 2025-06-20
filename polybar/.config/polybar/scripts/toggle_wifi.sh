#!/bin/bash

IFACE="wlo1"

# Get Wi-Fi radio state (enabled/disabled)
STATE=$(nmcli radio wifi)

if [ "$STATE" = "enabled" ]; then
    nmcli radio wifi off
else
    nmcli radio wifi on
fi
