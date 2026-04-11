#!/usr/bin/env bash

notify="notify-send"

signal_icon() {
    local s=$1
    if [ "$s" -ge 80 ]; then echo "󰤨"
    elif [ "$s" -ge 60 ]; then echo "󰤥"
    elif [ "$s" -ge 40 ]; then echo "󰤢"
    elif [ "$s" -ge 20 ]; then echo "󰤟"
    else echo "󰤯"
    fi
}

while true; do
    networks=$(nmcli -t -f SSID,SIGNAL,SECURITY dev wifi list --rescan no | grep -v '^$' | sort -t: -k2 -nr | uniq -f0)
    current=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)

    list=""
    ssids=()
    signals=()

    # Add disconnect option if connected
    if [ -n "$current" ]; then
        list="$(printf '󰖪  Disconnect from %s' "$current")\n"
        ssids+=("__disconnect__")
        signals+=(0)
    fi

    while IFS=: read -r ssid signal security; do
        [ -z "$ssid" ] && continue

        icon=$(signal_icon "$signal")
        [ -n "$security" ] && lock="󰌾" || lock=""

        if [ "$ssid" = "$current" ]; then
            conn="󰄬"
        else
            conn=" "
        fi

        list+="$(printf '%s  %-40s %s  %3s%%  %s' "$icon" "$ssid" "$conn" "$signal" "$lock")\n"
        ssids+=("$ssid")
        signals+=("$signal")
    done <<< "$networks"

    chosen=$(echo -e "$list" | rofi -dmenu -i -p " " -no-show-icons -format i)
    [ -z "$chosen" ] && exit 0

    ssid="${ssids[$chosen]}"
    sig="${signals[$chosen]}"

    if [ "$ssid" = "__disconnect__" ]; then
        nmcli con down "$current" && $notify "WiFi" "Disconnected from $current" || $notify "WiFi" "Failed to disconnect"
        continue
    fi

    if nmcli -t -f NAME con show | grep -qx "$ssid"; then
        nmcli con up "$ssid" && $notify "WiFi" "Connected to $ssid" || $notify "WiFi" "Failed to connect to $ssid"
        exit 0
    else
        sig_icon=$(signal_icon "$sig")
        pass=$(echo -e "󰌾  Connect\n󰁍  Back" | rofi -dmenu -i -p "" -password \
            -mesg "$sig_icon  <b>$ssid</b>" \
            -theme-str "mainbox { children: [message, inputbar, listview]; }" \
            -theme-str "message { margin: 0 0 8px 0; padding: 10px 12px; background-color: @bg-alt; border-radius: 4px; }" \
            -theme-str "textbox { background-color: @bg-alt; text-color: @fg; }" \
            -theme-str "entry { placeholder: \"Enter password\"; }" \
            -theme-str "listview { lines: 2; }" \
            -no-show-icons)
        [ -z "$pass" ] && exit 0
        [[ "$pass" == *"Back"* ]] && continue
        [[ "$pass" == *"Connect"* ]] && { notify-send "WiFi" "No password entered"; continue; }

        nmcli dev wifi connect "$ssid" password "$pass" && $notify "WiFi" "Connected to $ssid" || $notify "WiFi" "Failed to connect to $ssid"
        exit 0
    fi
done
