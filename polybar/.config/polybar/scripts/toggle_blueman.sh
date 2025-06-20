#!/bin/bash

# Check if blueman-manager is running
if pgrep -x "blueman-manager" > /dev/null; then
    # If running, kill it
    pkill -x "blueman-manager"
else
    # Otherwise, start it in background
    blueman-manager &
fi
