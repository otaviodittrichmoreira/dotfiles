#!/usr/bin/env bash

export DISPLAY=:0

m1="eDP-1"

notif() {
    notify-send -t 3000 -h string:bgcolor:#ebcb8b "Brightness adjusted"
}

[ "$1" = 10 ] && percent="1" || percent="0.$1"

[ "$2" = night ] && gamma="1.0:0.95:0.9" || gamma="1.0:1.0:1.0"

xrandr --output "$m1" --brightness "$percent" --gamma "$gamma"
