#!/bin/bash
# screenshot.sh — grim + slurp + swappy
# Usage: screenshot.sh [area|full|window]

SAVE_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SAVE_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILE="$SAVE_DIR/screenshot_$TIMESTAMP.png"

notify_screenshot() {
    local msg="$1"
    notify-send -i "$FILE" -t 3000 "Screenshot" "$msg" 2>/dev/null || true
}

case "${1:-area}" in
    area)
        GEOM=$(slurp -d \
            -b "#1a101680" \
            -c "#4e6e4eFF" \
            -w 2 \
            -s "#4e6e4e20") || exit 0
        grim -g "$GEOM" - | swappy -f - -o "$FILE"
        [ -f "$FILE" ] && notify_screenshot "Area saved"
        ;;
    full)
        grim "$FILE"
        wl-copy < "$FILE"
        notify_screenshot "Fullscreen saved & copied"
        ;;
    window)
        GEOM=$(hyprctl activewindow -j \
            | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' 2>/dev/null)
        if [ -z "$GEOM" ] || [ "$GEOM" = "null,null nullxnull" ]; then
            notify-send "Screenshot" "No active window found" -t 2000 2>/dev/null || true
            exit 1
        fi
        grim -g "$GEOM" - | swappy -f - -o "$FILE"
        [ -f "$FILE" ] && notify_screenshot "Window saved"
        ;;
    *)
        echo "Usage: screenshot.sh [area|full|window]"
        exit 1
        ;;
esac
