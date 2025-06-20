#!/bin/bash

# Get the current layout
CURRENT_LAYOUT=$(setxkbmap -query | grep layout | awk '{print $2}')

# Toggle between layouts
if [ "$CURRENT_LAYOUT" == "us" ]; then
    setxkbmap br
else
    setxkbmap us
fi
