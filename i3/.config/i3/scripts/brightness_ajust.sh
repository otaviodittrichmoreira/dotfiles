#!/usr/bin/env bash

# Usage:
#   brightness.sh up
#   brightness.sh down

DEVICE="intel_backlight"

current=$(brightnessctl -d "$DEVICE" g)
max=$(brightnessctl -d "$DEVICE" m)

# Current brightness percentage
percent=$(( current * 100 / max ))

next_down() {
    if (( percent <= 1 )); then
        echo 0
    elif (( percent <= 2 )); then
        echo 1
    elif (( percent <= 5 )); then
        echo 2
    elif (( percent <= 10 )); then
        echo 5
    elif (( percent <= 20 )); then
        echo 10
    else
        echo $(( ((percent + 5) / 10 - 1) * 10 ))
    fi
}

next_up() {
    if (( percent < 1 )); then
        echo 1
    elif (( percent < 2 )); then
        echo 2
    elif (( percent < 5 )); then
        echo 5
    elif (( percent < 10 )); then
        echo 10
    else
        echo $(( ((percent + 5) / 10 + 1) * 10 ))
    fi
}

case "$1" in
    up)
        target=$(next_up)
        echo $target
        brightnessctl -d "$DEVICE" s "${target}%"
        ;;
    down)
        target=$(next_down)
        brightnessctl -d "$DEVICE" s "${target}%"
        ;;
    *)
        echo "Usage: $0 {up|down}"
        exit 1
        ;;
esac
