#!/bin/bash
tmpfile=$(mktemp /tmp/noteXXXXXX.tex)
alacritty -o "font.size=20" --class nvimfloat -e $HOME/bin/nvim.appimage "$tmpfile"

# Copy to clipboard
head -c -1 "$tmpfile" | sed -E \
  -e 's/\\\(\s*/$/g' \
  -e 's/\s*\\\)/$/g' \
  -e 's/\\\[/$$/g' \
  -e 's/\\\]/$$/g' \
  | xclip -selection clipboard

# Wait for window to lose focus (to avoid pasting into the terminal itself)
sleep 0.5

# Simulate Ctrl+V
xdotool key --clearmodifiers ctrl+v

rm "$tmpfile"
