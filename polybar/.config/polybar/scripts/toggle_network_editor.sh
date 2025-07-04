#!/bin/bash

# Check if nmtui is already running (in any terminal)
if pgrep -f "nmtui" > /dev/null; then
    # Kill all nmtui instances
    pkill -f "nmtui"
else
    # Launch nmtui in a floating terminal (change alacritty if needed)
    nohup alacritty -e nmtui >/dev/null 2>&1 &
fi
