#!/usr/bin/env bash

preprompt=$(cat preprompt.txt)

read -p "Enter Prompt: " query

echo "Prompt: $query" & python ~/dotfiles/tmux/scripts/g4f-runner.py -s "$preprompt" -u "$query" | sed -n '/^```/,/^```/p' | sed '/^```/d' | fzf | sed -e 's/"/\\\"/g' -e "s/'/\\\'/g" | xargs -I {} tmux send-keys "{}"
