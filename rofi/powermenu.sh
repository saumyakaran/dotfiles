#!/usr/bin/env bash
source ~/dotfiles/theme/vars.sh

chosen=$(echo -e "<span color=\"#${BASE0D}\">󰒲</span>  Sleep\n<span color=\"#${BASE0B}\">󰍃</span>  Logout\n<span color=\"#${BASE09}\">󰜉</span>  Reboot\n<span color=\"#${BASE08}\">󰐥</span>  Shutdown" | rofi -dmenu -p "" -markup-rows -theme ~/dotfiles/rofi/powermenu.rasi)

case "$chosen" in
    *Sleep*) ssh-add -D; swaylock && systemctl suspend ;;
    *Logout*) pkill -f stremio; swaymsg exit ;;
    *Reboot*) systemctl reboot ;;
    *Shutdown*) systemctl poweroff ;;
esac
