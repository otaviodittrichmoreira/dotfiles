#!/usr/bin/env bash

preprompt=$(cat ~/dotfiles/tmux/g4f/preprompt.txt)

read -p "Enter Prompt: " query
# query="Copy all files from folder bigfolder to bigfolder2 with progress bar and ETA"

# Save query in a temp file
cat ~/dotfiles/tmux/g4f/history.json | jq --arg q "$query" '. + { ($q): ""}' > ~/dotfiles/tmux/g4f/tmp.json
mv ~/dotfiles/tmux/g4f/tmp_prompt.json ~/dotfiles/tmux/g4f/history.json

# Run the GPT model
python ~/dotfiles/tmux/g4f/g4f-runner.py -s "$preprompt" -u "$query" | ~/dotfiles/tmux/g4f/preview-command.sh | sed -e 's/"/\\\"/g' -e "s/'/\\\'/g" | xargs -I {} tmux send-keys "{}"
