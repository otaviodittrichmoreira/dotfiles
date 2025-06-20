#!/bin/bash

# This gets the window ID of the open editor if it exists
WINDOW_ID=$(xdotool search --onlyvisible --class nm-connection-editor 2>/dev/null | head -n1)

if [ -n "$WINDOW_ID" ]; then
    # If it's open, close it gracefully
    xdotool windowclose "$WINDOW_ID"
else
    # Otherwise, open it
    nohup nm-connection-editor >/dev/null 2>&1 &
fi
