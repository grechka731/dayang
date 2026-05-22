#!/bin/bash
# screenshot.sh — grim + slurp + swappy
# Usage: screenshot.sh [area|full|window]

SAVE_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SAVE_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILE="$SAVE_DIR/screenshot_$TIMESTAMP.png"

case "${1:-area}" in
    area)
        GEOM=$(slurp -d -b "#1a101680" -c "#4e6e4eFF" -w 2 -s "#4e6e4e20") || exit 0
        grim -g "$GEOM" - | swappy -f - -o "$FILE"
        ;;
    full)
        grim "$FILE"
        wl-copy < "$FILE"
        notify-send -i "$FILE" "Screenshot" "Saved & copied to clipboard"
        ;;
    window)
        GEOM=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
        grim -g "$GEOM" - | swappy -f - -o "$FILE"
        ;;
    *)
        echo "Usage: screenshot.sh [area|full|window]"
        exit 1
        ;;
esac
