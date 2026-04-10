#!/usr/bin/env bash

notify="notify-send"

# Get list of available wifi networks
networks=$(nmcli -t -f SSID,SIGNAL,SECURITY dev wifi list | grep -v '^$' | sort -t: -k2 -nr | uniq -f0)

# Format for rofi
list=""
while IFS=: read -r ssid signal security; do
    [ -z "$ssid" ] && continue
    if [ -n "$security" ]; then
        list+="󰤨  ${ssid}  (${signal}% ${security})\n"
    else
        list+="󰤨  ${ssid}  (${signal}%)\n"
    fi
done <<< "$networks"

# Show rofi menu
chosen=$(echo -e "$list" | rofi -dmenu -i -p "WiFi" -dpi 144)
[ -z "$chosen" ] && exit 0

# Extract SSID
ssid=$(echo "$chosen" | sed 's/^󰤨  //' | sed 's/  (.*//')

# Check if already known
if nmcli -t -f NAME con show | grep -qx "$ssid"; then
    nmcli con up "$ssid" && $notify "WiFi" "Connected to $ssid" || $notify "WiFi" "Failed to connect to $ssid"
else
    # Ask for password
    pass=$(rofi -dmenu -p "Password" -password -dpi 144)
    [ -z "$pass" ] && exit 0
    nmcli dev wifi connect "$ssid" password "$pass" && $notify "WiFi" "Connected to $ssid" || $notify "WiFi" "Failed to connect to $ssid"
fi
