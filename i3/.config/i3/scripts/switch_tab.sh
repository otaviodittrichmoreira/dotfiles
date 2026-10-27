#!/usr/bin/env bash

# switch_tab.sh <tab_number>
STATE="$HOME/.config/i3/current_tab"
TAB_STATE_DIR="$HOME/.config/i3/tab_workspaces"
NEW_TAB=$1

# default to tab 1 if state file doesn't exist
[[ -f "$STATE" ]] && CUR_TAB=$(<"$STATE") || CUR_TAB=1

# find current workspace number
CUR_WS=$(i3-msg -t get_workspaces | jq '.[] | select(.focused==true).num')

# compute workspace within current tab (1–10)
REL=$(( (CUR_WS - 1) % 10 + 1 ))

# remember the workspace being left, then restore the new tab's last workspace
mkdir -p "$TAB_STATE_DIR"
echo "$REL" > "$TAB_STATE_DIR/$CUR_TAB"
[[ -f "$TAB_STATE_DIR/$NEW_TAB" ]] && NEW_REL=$(<"$TAB_STATE_DIR/$NEW_TAB") || NEW_REL=1

# compute new workspace number
TARGET_WS=$((NEW_REL + 10 * (NEW_TAB - 1)))

echo "$NEW_TAB" > "$STATE"
i3-msg workspace number "$TARGET_WS"
