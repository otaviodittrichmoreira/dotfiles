#!/usr/bin/env bash
# Displays current tab and its 10 workspaces

STATE="$HOME/.config/i3/current_tab"
[[ -f "$STATE" ]] && TAB=$(<"$STATE") || TAB=1

# i3-msg returns info about all workspaces
WORKSPACES_JSON=$(i3-msg -t get_workspaces)
FOCUSED_WS=$(echo "$WORKSPACES_JSON" | jq '.[] | select(.focused==true).num')

# relative active workspace number within 1–10
REL=$(( (FOCUSED_WS - 1) % 10 + 1 ))

# Print header
printf "Tab:%s " "$TAB"

for i in {1..10}; do
  if [[ "$i" -eq "$REL" ]]; then
    printf "%%{A1:~/.config/i3/scripts/go_workspace.sh %d:}%%{F#00ff00}[%d]%%{F-}%%{A}" "$i" "$i"
  else
    printf "%%{A1:~/.config/i3/scripts/go_workspace.sh %d:} %d%%{A} " "$i" "$i"
  fi
done

echo

