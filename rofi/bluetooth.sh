#!/usr/bin/env bash

power_status=$(bluetoothctl show 2>/dev/null | grep "Powered:" | awk '{print $2}')

if [ "$power_status" = "no" ]; then
    choice=$(echo -e "󰂯  Power On\n󰂲  Exit" | rofi -dmenu -i -p "Bluetooth" -dpi 144)
    case "$choice" in
        *"Power On"*) bluetoothctl power on; notify-send "Bluetooth" "Powered on" ;;
    esac
    exit 0
fi

# Get paired devices
paired=$(bluetoothctl devices Paired 2>/dev/null | sed 's/Device //')

# Get connected devices
connected=$(bluetoothctl devices Connected 2>/dev/null | sed 's/Device //')

# Build menu
menu=""
while IFS= read -r line; do
    [ -z "$line" ] && continue
    mac=$(echo "$line" | awk '{print $1}')
    name=$(echo "$line" | cut -d' ' -f2-)
    if echo "$connected" | grep -q "$mac"; then
        menu+="󰂱  $name (connected)\n"
    else
        menu+="󰂳  $name\n"
    fi
done <<< "$paired"

menu+="󰂯  Scan for devices\n󰂲  Power Off"

chosen=$(echo -e "$menu" | rofi -dmenu -i -p "Bluetooth" -dpi 144)
[ -z "$chosen" ] && exit 0

case "$chosen" in
    *"Scan for devices"*)
        notify-send "Bluetooth" "Scanning..."
        bluetoothctl --timeout 10 scan on &
        sleep 10
        new_devices=$(bluetoothctl devices | sed 's/Device //')
        selected=$(echo "$new_devices" | awk '{$1=""; print substr($0,2)}' | rofi -dmenu -i -p "Connect" -dpi 144)
        [ -z "$selected" ] && exit 0
        mac=$(echo "$new_devices" | grep "$selected" | awk '{print $1}')
        bluetoothctl pair "$mac" 2>/dev/null
        bluetoothctl connect "$mac" && notify-send "Bluetooth" "Connected to $selected" || notify-send "Bluetooth" "Failed to connect"
        ;;
    *"Power Off"*)
        bluetoothctl power off
        notify-send "Bluetooth" "Powered off"
        ;;
    *"connected"*)
        name=$(echo "$chosen" | sed 's/󰂱  //;s/ (connected)//')
        mac=$(echo "$paired" | grep "$name" | awk '{print $1}')
        bluetoothctl disconnect "$mac" && notify-send "Bluetooth" "Disconnected $name" || notify-send "Bluetooth" "Failed"
        ;;
    *)
        name=$(echo "$chosen" | sed 's/󰂳  //')
        mac=$(echo "$paired" | grep "$name" | awk '{print $1}')
        bluetoothctl connect "$mac" && notify-send "Bluetooth" "Connected to $name" || notify-send "Bluetooth" "Failed"
        ;;
esac
