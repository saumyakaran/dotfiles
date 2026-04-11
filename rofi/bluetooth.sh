#!/usr/bin/env bash

# Rofi script mode — launched via:
#   rofi -modi "bt:~/dotfiles/rofi/bluetooth.sh" -show bt -no-show-icons -p "󰂱 "
# Rofi stays open and calls this script on each selection.

build_menu() {
    power_status=$(bluetoothctl show 2>/dev/null | grep "Powered:" | awk '{print $2}')

    if [ "$power_status" = "no" ]; then
        echo -e "󰂯  Power On\0info\x1fpoweron"
        return
    fi

    paired=$(bluetoothctl devices Paired 2>/dev/null | sed 's/Device //')
    connected=$(bluetoothctl devices Connected 2>/dev/null | sed 's/Device //')

    while IFS= read -r line; do
        [ -z "$line" ] && continue
        mac=$(echo "$line" | awk '{print $1}')
        name=$(echo "$line" | cut -d' ' -f2-)

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
            echo -e "$icon  $name  󰄬  Connected\0info\x1fdisconnect:$mac"
        else
            echo -e "$icon  $name      Paired\0info\x1fconnect:$mac"
        fi
    done <<< "$paired"

    # Show discovered but unpaired devices
    all_devices=$(bluetoothctl devices | sed 's/Device //')
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        mac=$(echo "$line" | awk '{print $1}')
        echo "$paired" | grep -q "$mac" && continue
        name=$(echo "$line" | cut -d' ' -f2-)
        echo -e "󰂱  $name      New\0info\x1fpair:$mac"
    done <<< "$all_devices"

    echo -e "󰑐  Scan for devices\0info\x1fscan"
    echo -e "󰂲  Power Off\0info\x1fpoweroff"
}

# Initial call — no selection yet
if [ "$ROFI_RETV" = "0" ] || [ -z "$ROFI_RETV" ]; then
    build_menu
    exit 0
fi

# Handle selection
case "$ROFI_INFO" in
    poweron)
        bluetoothctl power on
        notify-send "Bluetooth" "Powered on"
        build_menu
        ;;
    scan)
        notify-send -t 4000 -h string:x-canonical-private-synchronous:bluetooth "Bluetooth" "Scanning..."
        bluetoothctl --timeout 3 scan on >/dev/null 2>&1
        notify-send -t 1500 -h string:x-canonical-private-synchronous:bluetooth "Bluetooth" "Scan complete"
        build_menu
        ;;
    poweroff)
        bluetoothctl power off
        notify-send "Bluetooth" "Powered off"
        # Output nothing — rofi closes
        ;;
    connect:*)
        mac="${ROFI_INFO#connect:}"
        name=$(bluetoothctl info "$mac" 2>/dev/null | grep "Alias:" | cut -d' ' -f2-)
        bluetoothctl connect "$mac" && notify-send "Bluetooth" "Connected to $name" || notify-send "Bluetooth" "Failed to connect"
        build_menu
        ;;
    disconnect:*)
        mac="${ROFI_INFO#disconnect:}"
        name=$(bluetoothctl info "$mac" 2>/dev/null | grep "Alias:" | cut -d' ' -f2-)
        bluetoothctl disconnect "$mac" && notify-send "Bluetooth" "Disconnected $name" || notify-send "Bluetooth" "Failed"
        build_menu
        ;;
    pair:*)
        mac="${ROFI_INFO#pair:}"
        name=$(bluetoothctl info "$mac" 2>/dev/null | grep "Alias:" | cut -d' ' -f2-)
        notify-send "Bluetooth" "Pairing with $name..."
        bluetoothctl pair "$mac" 2>/dev/null
        bluetoothctl connect "$mac" && notify-send "Bluetooth" "Connected to $name" || notify-send "Bluetooth" "Failed to connect"
        build_menu
        ;;
esac
