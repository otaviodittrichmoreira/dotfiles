#!/bin/bash

# Set your calendar app here
CAL_APP="gnome-calendar"

# Check if the calendar app is running
if pgrep -x "$CAL_APP" > /dev/null; then
    # If running, kill it
    pkill -x "$CAL_APP"
else
    # Otherwise, start it in the background
    "$CAL_APP" &
fi
