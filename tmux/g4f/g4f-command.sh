#!/usr/bin/env bash

preprompt=$(cat ~/dotfiles/tmux/g4f/preprompt.txt)

read -p "Enter Prompt: " prompt
# prompt="Copy all files from folder bigfolder to bigfolder2 with progress bar and ETA"

# Check if prompt is in history and has an answer
prompt_in_history=$(cat ~/dotfiles/tmux/g4f/history.json | jq --arg q "$prompt" 'has(($q)) and .[($q)] != ""')

# Save prompt in history regardless
cat ~/dotfiles/tmux/g4f/history.json | jq --arg q "$prompt" '. + { ($q): ""}' > ~/dotfiles/tmux/g4f/tmp_history.json
mv "$g4f_path"tmp_history.json ~/dotfiles/tmux/g4f/history.json

# If prompt was on history, return the previous answer
if [[ $prompt_in_history == "true" ]]; then
    answer=$(cat ~/dotfiles/tmux/g4f/history.json | jq --arg q "$prompt" '.[($q)]')
else
    answer=$(python ~/dotfiles/tmux/g4f/g4f-runner.py -s "$preprompt" -u "$prompt")
fi

# Save answer in history
cat ~/dotfiles/tmux/g4f/history.json | jq --arg q "$prompt" --arg a "$(cat ~/dotfiles/tmux/g4f/tmp_answer.md)" '.[($q)] = ($a)' > ~/dotfiles/tmux/g4f/tmp_history.json
mv "$g4f_path"tmp_history.json ~/dotfiles/tmux/g4f/history.json

# Process commands and pipe into fzf and send-keys to tmux pane
cat ~/dotfiles/tmux/g4f/tmp_answer.md | ~/dotfiles/tmux/g4f/preview-command.sh | sed -e 's/"/\\\"/g' -e "s/'/\\\'/g" | xargs -I {} tmux send-keys "{}"
