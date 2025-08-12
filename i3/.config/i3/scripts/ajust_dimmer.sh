#!/usr/bin/env bash

hour=$(date | grep -oP "\d{2}:\d{2}:\d{2}" | awk -F ":" '{print $1}')

if [ "$hour" -eq 20 ]; then
    /home/otavio/.config/i3/scripts/dimmer.sh 9
elif [ "$hour" -eq 21 ]; then
    /home/otavio/.config/i3/scripts/dimmer.sh 8 night
elif [ "$hour" -eq 22 ]; then
    /home/otavio/.config/i3/scripts/dimmer.sh 7 night
elif [ "$hour" -le 6 -o "$hour" -ge 23 ]; then
    /home/otavio/.config/i3/scripts/dimmer.sh 6 night
else
    /home/otavio/.config/i3/scripts/dimmer.sh 10
fi
