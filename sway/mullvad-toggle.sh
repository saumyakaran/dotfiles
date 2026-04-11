#!/usr/bin/env bash
if mullvad status | grep -q "Connected"; then
    mullvad disconnect
    notify-send -t 2000 "󰖂 Mullvad" "Disconnected"
else
    mullvad connect
    for i in {1..10}; do
        sleep 0.5
        status=$(mullvad status 2>/dev/null)
        if echo "$status" | grep -q "Connected"; then
            relay=$(echo "$status" | grep "Relay:" | sed 's/.*Relay:\s*//')
            location=$(echo "$status" | grep "Visible location:" | sed 's/.*Visible location:\s*//')
            notify-send -t 3000 "󰖂 Mullvad" "Connected\n$location\n$relay"
            exit 0
        fi
    done
    notify-send -t 3000 "󰖂 Mullvad" "Failed to connect"
fi
