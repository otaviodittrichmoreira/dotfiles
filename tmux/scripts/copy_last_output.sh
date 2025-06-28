#!/bin/bash

# How many lines to capture (increase if needed)
LINES=10000
PROMPT_REGEX="^λ ›"

# Capture pane output
BUFFER=$(tmux capture-pane -J -p -S -$LINES)

# Find all prompt line numbers
PROMPT_LINES=($(echo "$BUFFER" | grep -n "$PROMPT_REGEX" | cut -d: -f1))

# If we don’t have at least two prompts, abort
if [ "${#PROMPT_LINES[@]}" -lt 2 ]; then
  echo "Not enough prompt lines found." >&2
  exit 1
fi

# Get the second-to-last and last prompt line numbers
START_LINE=${PROMPT_LINES[-2]}
END_LINE=${PROMPT_LINES[-1]}

# Extract lines between those two prompts (output of the last command)
echo "$BUFFER" | sed -n "$((START_LINE+1)),$((END_LINE-1))p" | xclip -selection clipboard
