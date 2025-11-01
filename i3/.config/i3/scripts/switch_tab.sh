#!/usr/bin/env bash

# switch_tab.sh <tab_number>
STATE="$HOME/.config/i3/current_tab"
NEW_TAB=$1

# default to tab 1 if state file doesn't exist
[[ -f "$STATE" ]] && CUR_TAB=$(<"$STATE") || CUR_TAB=1

# find current workspace number
CUR_WS=$(i3-msg -t get_workspaces | jq '.[] | select(.focused==true).num')

# compute workspace within current tab (1–10)
REL=$(( (CUR_WS - 1) % 10 + 1 ))

# compute new workspace number
if [[ "$NEW_TAB" == "1" ]]; then
  TARGET_WS=$REL
else
  TARGET_WS=$((REL + 10))
fi

echo "$NEW_TAB" > "$STATE"
i3-msg workspace number "$TARGET_WS"
