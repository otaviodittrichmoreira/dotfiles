#!/usr/bin/env bash

preprompt=$(cat ~/dotfiles/tmux/g4f/preprompt.txt)

read -p "Enter Prompt: " prompt

# Check if prompt is in history and has an answer
prompt_in_history=$(cat ~/dotfiles/tmux/g4f/history.json | jq --arg q "$prompt" 'has(($q)) and .[($q)] != ""')

# If prompt was on history, return the previous answer
if [[ $prompt_in_history == "true" ]]; then
    answer=$(cat ~/dotfiles/tmux/g4f/history.json | jq -r --arg q "$prompt" '.[($q)]')

else
    answer=$(python ~/dotfiles/tmux/g4f/g4f-runner.py -s "$preprompt" -u "$prompt")

    # Save answer in history
    cat ~/dotfiles/tmux/g4f/history.json | jq --arg q "$prompt" --arg a "$answer" '.[ $q ] = $a' > ~/dotfiles/tmux/g4f/tmp_history.json
    mv ~/dotfiles/tmux/g4f/tmp_history.json ~/dotfiles/tmux/g4f/history.json
fi

# Process commands and pipe into fzf and send-keys to tmux pane
printf '%s\n' "$answer" | ~/dotfiles/tmux/g4f/preview-command.sh | sed -e 's/"/\\\"/g' -e "s/'/\\\'/g" | xargs -I {} tmux send-keys "{}"
