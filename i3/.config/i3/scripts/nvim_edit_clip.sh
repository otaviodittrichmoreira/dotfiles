#!/bin/bash
tmpfile=$(mktemp /tmp/nvimeditXXXXXX.tex)

# Simulate Ctrl+C to copy selected text
sleep 0.1  # Wait for clipboard to update
xdotool key --clearmodifiers ctrl+a
sleep 0.1  # Wait for clipboard to update
xdotool key --clearmodifiers ctrl+c
sleep 0.2  # Wait for clipboard to update

# Use clipboard content as initial input for Neovim
xclip -o -selection clipboard > "$tmpfile"

# Launch floating terminal with Neovim
alacritty --class nvimfloat -e $HOME/bin/nvim.appimage "$tmpfile"

# After editing, copy updated content back to clipboard
head -c -1 "$tmpfile" | xclip -selection clipboard
sleep 0.2

# Simulate Ctrl+V to paste it back
xdotool key --clearmodifiers ctrl+v

rm "$tmpfile"
