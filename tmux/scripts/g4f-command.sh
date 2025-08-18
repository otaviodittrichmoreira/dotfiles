#!/usr/bin/env bash

options="Copiar"
preprompt="Answer the question with options of one-line bash code and its explanation right above
"

read -p "Enter Prompt: " query
# query="How to list disks in linux?"

echo "Prompt: $query" & g4f "$preprompt $query" | sed -n '/^```/,/^```/p' | sed '/^```/d' | fzf | xargs -I {} sh -c "tmux send-keys \"{}\""
