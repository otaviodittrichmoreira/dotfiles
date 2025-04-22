#!/bin/bash

DIR=~/Pictures/Screenshots
mkdir -p "$DIR"

FILENAME="screenshot_$(date +'%Y-%m-%d_%H-%M-%S').png"
FULLPATH="$DIR/$FILENAME"

# Take screenshot (select area)
import "$FULLPATH"

# If successful, copy to clipboard and send notification
if [ $? -eq 0 ]; then
    xclip -selection clipboard -t image/png -i "$FULLPATH"
    notify-send "📸 Screenshot Saved" "Copied to clipboard:\n$FULLPATH"
else
    notify-send "❌ Screenshot Failed"
fi
