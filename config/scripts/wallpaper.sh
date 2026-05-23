#!/bin/bash
# wallpaper.sh — swww wallpaper manager
# Usage:
#   wallpaper.sh init              — start daemon + set random wallpaper (exec-once)
#   wallpaper.sh set <file>        — set specific wallpaper
#   wallpaper.sh random [dir]      — set random from directory
#   wallpaper.sh cycle [dir] [sec] — cycle wallpapers every N seconds

TRANSITION="--transition-type wipe --transition-angle 30 --transition-duration 1.5 --transition-fps 60"
DEFAULT_DIR="$HOME/Pictures/Wallpapers"
DEFAULT_INTERVAL=1800

find_random() {
    local dir="${1:-$DEFAULT_DIR}"
    find "$dir" -type f \( \
        -iname "*.jpg" -o \
        -iname "*.jpeg" -o \
        -iname "*.png" -o \
        -iname "*.webp" -o \
        -iname "*.gif" \
    \) 2>/dev/null | shuf -n 1
}

set_wallpaper() {
    local wall="$1"
    if [ -z "$wall" ] || [ ! -f "$wall" ]; then
        echo "wallpaper.sh: file not found: '$wall'"
        return 1
    fi
    swww img "$wall" $TRANSITION
}

case "${1:-init}" in
    init)
        # Start daemon if not running
        if ! pgrep -x swww-daemon &>/dev/null; then
            swww-daemon &
            sleep 0.8
        fi
        WALL=$(find_random "$DEFAULT_DIR")
        if [ -n "$WALL" ]; then
            set_wallpaper "$WALL"
        else
            echo "wallpaper.sh: no images in $DEFAULT_DIR"
        fi
        ;;
    set)
        [ -z "${2:-}" ] && { echo "Usage: wallpaper.sh set <file>"; exit 1; }
        set_wallpaper "$2"
        ;;
    random)
        WALL=$(find_random "${2:-$DEFAULT_DIR}")
        if [ -n "$WALL" ]; then
            set_wallpaper "$WALL"
        else
            echo "wallpaper.sh: no images found in '${2:-$DEFAULT_DIR}'"
            exit 1
        fi
        ;;
    cycle)
        DIR="${2:-$DEFAULT_DIR}"
        INTERVAL="${3:-$DEFAULT_INTERVAL}"
        echo "wallpaper.sh: cycling from $DIR every ${INTERVAL}s (Ctrl+C to stop)"
        while true; do
            WALL=$(find_random "$DIR")
            [ -n "$WALL" ] && set_wallpaper "$WALL"
            sleep "$INTERVAL"
        done
        ;;
    *)
        echo "Usage: wallpaper.sh [init|set <file>|random [dir]|cycle [dir] [seconds]]"
        exit 1
        ;;
esac
