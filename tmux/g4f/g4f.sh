#!/usr/bin/env bash
read -p "Enter Prompt: " query

tmux neww bash -c "rich \"User\" --rule -w 80; rich \"$query\" -w 80 --print; rich \"ChatBot\" --rule -w 80 & cat ~/output.md | rich - --markdown -w 80 --theme dracula & while [ : ]; do sleep 1; done"
