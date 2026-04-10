#!/usr/bin/env bash

chosen=$(echo -e '<span color="#8aadf4">󰒲</span>  Sleep\n<span color="#a6da95">󰍃</span>  Logout\n<span color="#f5a97f">󰜉</span>  Reboot\n<span color="#ed8796">󰐥</span>  Shutdown' | rofi -dmenu -p "" -markup-rows -theme ~/dotfiles/rofi/powermenu.rasi)

case "$chosen" in
    *Sleep*) ssh-add -D; swaylock -c 1e2030 && systemctl suspend ;;
    *Logout*) swaymsg exit ;;
    *Reboot*) systemctl reboot ;;
    *Shutdown*) systemctl poweroff ;;
esac
