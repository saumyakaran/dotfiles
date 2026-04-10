#!/usr/bin/env bash

notify="notify-send"

# Get list of available wifi networks
networks=$(nmcli -t -f SSID,SIGNAL,SECURITY dev wifi list --rescan no | grep -v '^$' | sort -t: -k2 -nr | uniq -f0)

# Get currently connected SSID
current=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)

# Format for rofi with fixed-width columns
list=""
while IFS=: read -r ssid signal security; do
    [ -z "$ssid" ] && continue

    # Signal strength icon
    if [ "$signal" -ge 80 ]; then
        icon="󰤨"
    elif [ "$signal" -ge 60 ]; then
        icon="󰤥"
    elif [ "$signal" -ge 40 ]; then
        icon="󰤢"
    elif [ "$signal" -ge 20 ]; then
        icon="󰤟"
    else
        icon="󰤯"
    fi

    # Lock icon for secured networks
    if [ -n "$security" ]; then
        lock="󰌾"
    else
        lock=""
    fi

    # Connected indicator
    if [ "$ssid" = "$current" ]; then
        conn="󰄬"
    else
        conn=" "
    fi

    list+="$(printf '%s  %-40s %s  %3s%%  %s' "$icon" "$ssid" "$conn" "$signal" "$lock")\n"
done <<< "$networks"

# Show rofi menu
chosen=$(echo -e "$list" | rofi -dmenu -i -p " " -no-show-icons)
[ -z "$chosen" ] && exit 0

# Extract SSID
ssid=$(echo "$chosen" | sed 's/^[^ ]*  //' | sed 's/ *󰄬.*//' | sed 's/ * .*//' | sed 's/ *$//')

# Check if already known
if nmcli -t -f NAME con show | grep -qx "$ssid"; then
    nmcli con up "$ssid" && $notify "WiFi" "Connected to $ssid" || $notify "WiFi" "Failed to connect to $ssid"
else
    # Ask for password
    pass=$(rofi -dmenu -p "Password" -password)
    [ -z "$pass" ] && exit 0
    nmcli dev wifi connect "$ssid" password "$pass" && $notify "WiFi" "Connected to $ssid" || $notify "WiFi" "Failed to connect to $ssid"
fi
