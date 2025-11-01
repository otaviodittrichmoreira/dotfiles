#!/usr/bin/env bash

# go_workspace.sh <relative_number 1–10>
STATE="$HOME/.config/i3/current_tab"
[[ -f "$STATE" ]] && TAB=$(<"$STATE") || TAB=1

NUM=$1

if [[ "$TAB" == "1" ]]; then
  TARGET_WS=$NUM
else
  TARGET_WS=$((NUM + 10))
fi

i3-msg workspace number "$TARGET_WS"
