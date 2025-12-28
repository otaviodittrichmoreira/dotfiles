#!/usr/bin/env bash

sleep 0.05
# Get player status
STATUS=$(playerctl status 2>/dev/null)

count=0
while [[ $STATUS == "Stopped" && count -lt 100 ]] do
    STATUS=$(playerctl status 2>/dev/null)
    sleep 0.05
    ((count++))
done

# Exit silently if no player is running
[ -z "$STATUS" ] && exit 0

# Metadata
TITLE=$(playerctl metadata title 2>/dev/null)
ARTIST=$(playerctl metadata artist 2>/dev/null)
PLAYER=$(playerctl -l 2>/dev/null | head -n 1)

# Icons (requires a Nerd Font or system icons)
case "$STATUS" in
    Playing)
        ICON=""
        ;;
    Paused)
        ICON=""
        ;;
    Stopped)
        ICON=""
        ;;
    *)
        ICON=""
        ;;
esac

# Fallbacks
[ -z "$TITLE" ] && TITLE="Unknown title"
[ -z "$ARTIST" ] && ARTIST="Unknown artist"

NOTIFY_ID=9999

# Send notification
notify-send \
  -r $NOTIFY_ID \
  -a "Music" \
  -u low \
  "$ICON $STATUS" \
  "$TITLE\n$ARTIST"
