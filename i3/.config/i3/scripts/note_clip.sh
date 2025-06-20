#!/bin/bash
tmpfile=$(mktemp /tmp/noteXXXXXX.txt)
alacritty --class nvimfloat -e $HOME/bin/nvim.appimage "$tmpfile"

# Copy to clipboard
xclip -selection clipboard < "$tmpfile"

# Wait for window to lose focus (to avoid pasting into the terminal itself)
sleep 0.5

# Simulate Ctrl+V
xdotool key --clearmodifiers ctrl+v

rm "$tmpfile"
