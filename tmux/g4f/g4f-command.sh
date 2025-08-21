#!/usr/bin/env bash

preprompt=$(cat ~/dotfiles/tmux/g4f/preprompt.txt)
HISTORY_FILE="$HOME/dotfiles/tmux/g4f/history.json"

mapfile -t history < <(jq -r 'keys_unsorted[]' "$HISTORY_FILE")

# Temporary file for readline history
TMP_HISTORY=$(mktemp)
printf "%s\n" "${history[@]}" > "$TMP_HISTORY"

# Run an interactive subshell with custom history
bash --rcfile <( 
    # Minimal rcfile for the subshell
    echo "HISTFILE=$TMP_HISTORY"
    echo 'bind -m vi-insert "\"\C-p\": previous-history"'
    echo 'bind -m vi-insert "\"\C-n\": next-history"'
    echo "set -o vi"               # enable Readline
    echo "[ -f ~/.bashrc ] && source ~/.bashrc"  # load fzf bindings
) -i -c '
    set +o history   # do not save commands to global history
    history -r       # read temp history
    read -e -p "Enter Prompt: " prompt
    echo "$prompt" > tmp.txt
'

prompt=$(cat tmp.txt)

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
