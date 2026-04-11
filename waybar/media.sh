#!/usr/bin/env bash
# Media now-playing for waybar with player detection and scrolling marquee
# Outputs JSON: {"text": "icon Artist — Title", "class": "player-name"}

MAX=40
SPEED=0.3

get_player() {
    # Find the first player that's Playing, or the first Paused one
    local playing="" paused=""
    while IFS= read -r name; do
        status=$(playerctl -p "$name" status 2>/dev/null)
        case "$status" in
            Playing) playing="$name"; break ;;
            Paused)  [[ -z "$paused" ]] && paused="$name" ;;
        esac
    done < <(playerctl -l 2>/dev/null)
    echo "${playing:-$paused}"
}

get_icon() {
    local player="$1" title="$2"
    case "$player" in
        spotify*)    echo "󰓇" ;;
        *stremio*)   echo "󰑈" ;;
        *vlc*)       echo "󰕼" ;;
        *mpv*)       echo "󰐹" ;;
        *brave*|*chromium*|*chrome*|*firefox*)
            # Check URL/title for known sites
            local url=$(playerctl -p "$player" metadata xesam:url 2>/dev/null)
            case "$url" in
                *youtube.com*|*youtu.be*) echo "󰗃" ;;
                *)                        echo "󰖟" ;;
            esac ;;
        *)           echo "󰎆" ;;
    esac
}

get_class() {
    local player="$1"
    case "$player" in
        spotify*)    echo "spotify" ;;
        *stremio*)   echo "stremio" ;;
        *brave*|*chromium*|*chrome*|*firefox*)
            local url=$(playerctl -p "$player" metadata xesam:url 2>/dev/null)
            case "$url" in
                *youtube.com*|*youtu.be*) echo "youtube" ;;
                *)                        echo "browser" ;;
            esac ;;
        *)           echo "other" ;;
    esac
}

output() {
    local text="$1" class="$2"
    # Escape JSON
    text="${text//\\/\\\\}"
    text="${text//\"/\\\"}"
    echo "{\"text\": \"$text\", \"class\": \"$class\"}"
}

while true; do
    player=$(get_player)
    if [[ -z "$player" ]]; then
        output "" "none"
        sleep 2
        continue
    fi

    class=$(get_class "$player")
    icon=$(get_icon "$player")
    text=$(playerctl -p "$player" metadata --format '{{artist}} — {{title}}' 2>/dev/null)

    # Skip if no useful metadata
    if [[ -z "$text" || "$text" == " — " ]]; then
        # Try title only (some players don't set artist)
        text=$(playerctl -p "$player" metadata --format '{{title}}' 2>/dev/null)
    fi
    [[ -z "$text" ]] && { output "" "none"; sleep 2; continue; }

    display="$icon $text"

    if (( ${#display} <= MAX )); then
        output "$display" "$class"
        sleep 2
    else
        padded="$text   ·   "
        len=${#padded}
        offset=0
        while (( offset < len )); do
            # Re-check player is still active
            if [[ "$(playerctl -p "$player" status 2>/dev/null)" != "Playing" ]]; then
                output "$icon $text" "$class"
                break
            fi
            doubled="$padded$padded"
            output "$icon ${doubled:$offset:$((MAX - ${#icon} - 1))}" "$class"
            (( offset++ ))
            sleep "$SPEED"
        done
    fi
done
