#!/usr/bin/env bash

power_status=$(bluetoothctl show 2>/dev/null | grep "Powered:" | awk '{print $2}')

if [ "$power_status" = "no" ]; then
    choice=$(echo -e "󰂯  Power On\n󰂲  Exit" | rofi -dmenu -i -p "󰂱 ")
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

    # Try to determine device type from icon
    icon_type=$(bluetoothctl info "$mac" 2>/dev/null | grep "Icon:" | awk '{print $2}')
    case "$icon_type" in
        audio*|headset*|headphone*) icon="󰋋" ;;
        input-keyboard*) icon="󰌌" ;;
        input-mouse*) icon="󰍽" ;;
        input-gaming*) icon="󰊗" ;;
        phone*) icon="󰏲" ;;
        computer*) icon="󰍹" ;;
        *) icon="󰂱" ;;
    esac

    if echo "$connected" | grep -q "$mac"; then
        menu+="$(printf '%s  %-40s 󰄬  Connected' "$icon" "$name")\n"
    else
        menu+="$(printf '%s  %-40s     Paired' "$icon" "$name")\n"
    fi
done <<< "$paired"

menu+="$(printf '󰑐  %-40s' "Scan for devices")\n$(printf '󰂲  %-40s' "Power Off")"

chosen=$(echo -e "$menu" | rofi -dmenu -i -p "󰂱 " -no-show-icons)
[ -z "$chosen" ] && exit 0

case "$chosen" in
    *"Scan for devices"*)
        notify-send "Bluetooth" "Scanning..."
        bluetoothctl --timeout 10 scan on &
        sleep 10
        new_devices=$(bluetoothctl devices | sed 's/Device //')
        selected=$(echo "$new_devices" | awk '{$1=""; print substr($0,2)}' | rofi -dmenu -i -p "Connect")
        [ -z "$selected" ] && exit 0
        mac=$(echo "$new_devices" | grep "$selected" | awk '{print $1}')
        bluetoothctl pair "$mac" 2>/dev/null
        bluetoothctl connect "$mac" && notify-send "Bluetooth" "Connected to $selected" || notify-send "Bluetooth" "Failed to connect"
        ;;
    *"Power Off"*)
        bluetoothctl power off
        notify-send "Bluetooth" "Powered off"
        ;;
    *"Connected"*)
        name=$(echo "$chosen" | sed 's/^[^ ]*  //' | sed 's/\t.*//')
        mac=$(echo "$paired" | grep "$name" | awk '{print $1}')
        bluetoothctl disconnect "$mac" && notify-send "Bluetooth" "Disconnected $name" || notify-send "Bluetooth" "Failed"
        ;;
    *)
        name=$(echo "$chosen" | sed 's/^[^ ]*  //' | sed 's/\t.*//')
        mac=$(echo "$paired" | grep "$name" | awk '{print $1}')
        bluetoothctl connect "$mac" && notify-send "Bluetooth" "Connected to $name" || notify-send "Bluetooth" "Failed"
        ;;
esac
