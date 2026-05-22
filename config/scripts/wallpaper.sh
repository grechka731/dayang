#!/bin/bash
# wallpaper.sh — swww wallpaper setter
# Usage:
#   wallpaper.sh init          — start swww daemon (call from hyprland.conf exec-once)
#   wallpaper.sh set <file>    — set specific wallpaper
#   wallpaper.sh random <dir>  — set random wallpaper from directory
#   wallpaper.sh cycle <dir>   — cycle wallpapers every N seconds (default: 1800)

TRANSITION="--transition-type wipe --transition-angle 30 --transition-duration 1.5"
DEFAULT_WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
DEFAULT_INTERVAL=1800

case "${1:-init}" in
    init)
        swww-daemon &
        sleep 0.5
        if [ -d "$DEFAULT_WALLPAPER_DIR" ]; then
            WALL=$(find "$DEFAULT_WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) | shuf -n 1)
            [ -n "$WALL" ] && swww img "$WALL" $TRANSITION
        fi
        ;;
    set)
        [ -z "$2" ] && { echo "Usage: wallpaper.sh set <file>"; exit 1; }
        swww img "$2" $TRANSITION
        ;;
    random)
        DIR="${2:-$DEFAULT_WALLPAPER_DIR}"
        WALL=$(find "$DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) | shuf -n 1)
        [ -n "$WALL" ] && swww img "$WALL" $TRANSITION || echo "No images found in $DIR"
        ;;
    cycle)
        DIR="${2:-$DEFAULT_WALLPAPER_DIR}"
        INTERVAL="${3:-$DEFAULT_INTERVAL}"
        while true; do
            WALL=$(find "$DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) | shuf -n 1)
            [ -n "$WALL" ] && swww img "$WALL" $TRANSITION
            sleep "$INTERVAL"
        done
        ;;
    *)
        echo "Usage: wallpaper.sh [init|set <file>|random [dir]|cycle [dir] [interval]]"
        exit 1
        ;;
esac
