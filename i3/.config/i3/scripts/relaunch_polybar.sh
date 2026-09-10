#!/usr/bin/env bash

# Kill existing bars
killall -q polybar

# Wait until they have exited
while pgrep -x polybar >/dev/null; do
    sleep 0.1
done

# Launch your bar(s)
~/.config/polybar/launch_polybar.sh
