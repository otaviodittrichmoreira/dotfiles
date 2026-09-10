#!/usr/bin/env bash
# battery-alert.sh — notify once at 15% and once at 5% battery
# Run via cron or i3 exec, e.g.:
#   * * * * * DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus /path/to/battery-alert.sh

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/battery-alert"
mkdir -p "$STATE_DIR"

BATTERY_PATH=$(find /sys/class/power_supply/ -maxdepth 1 -name "BAT*" | head -n1)

if [[ -z "$BATTERY_PATH" ]]; then
    echo "No battery found." >&2
    exit 1
fi

STATUS=$(cat "$BATTERY_PATH/status" 2>/dev/null)
CAPACITY=$(cat "$BATTERY_PATH/capacity" 2>/dev/null)

# Only alert when discharging
if [[ "$STATUS" != "Discharging" ]]; then
    # Reset flags when charging so alerts fire again next discharge cycle
    rm -f "$STATE_DIR/alerted_30" "$STATE_DIR/alerted_10"
    exit 0
fi

if [[ "$CAPACITY" -le 10 ]] && [[ ! -f "$STATE_DIR/alerted_10" ]]; then
    notify-send \
        --urgency=critical \
        --icon=battery-caution \
        "⚠️  Battery Critical: ${CAPACITY}%" \
        "<span font='30px'>Connect your charger immediately!</span>"
    touch "$STATE_DIR/alerted_10"

elif [[ "$CAPACITY" -le 30 ]] && [[ ! -f "$STATE_DIR/alerted_30" ]]; then
    notify-send \
        --urgency=normal \
        --icon=battery-low \
        "🔋 Battery Low: ${CAPACITY}%" \
        "<span font='30px'>Consider plugging in soon.</span>"
    touch "$STATE_DIR/alerted_30"
fi
