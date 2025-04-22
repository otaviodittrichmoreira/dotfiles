#!/bin/bash
# Toggle the i3 bar mode
i3-msg bar mode toggle

# Toggle borders for all windows
CURRENT_BORDER=$(i3-msg -t get_tree | jq '.. | .border? // empty' | head -n 1)

if [ "$CURRENT_BORDER" == "normal" ]; then
    i3-msg "for_window [class=.] border none"
else
    i3-msg "for_window [class=.] border normal"
fi
