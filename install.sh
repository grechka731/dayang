#!/bin/bash

echo "[PROCESS] Initializing system update..."
sudo pacman-key --init
sudo pacman-key --populate artix
sudo pacman -Syyu --noconfirm

echo "[PROCESS] Installing base-devel and git..."
sudo pacman -S --noconfirm --needed base-devel git

if ! command -v yay &> /dev/null; then
    echo "[INFO] Installing yay..."
    ORIG_DIR="$(pwd)"
    cd /tmp
    rm -rf yay
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd "$ORIG_DIR"
else
    echo "[INFO] yay already installed."
fi

PACKAGE_FILE="packages.txt"
if [ ! -f "$PACKAGE_FILE" ]; then
    echo "[FATAL] $PACKAGE_FILE not found."
    exit 1
fi

echo "[PROCESS] Installing packages..."
while IFS= read -r line || [ -n "$line" ]; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    manager=$(echo "$line" | cut -d':' -f1)
    package=$(echo "$line" | cut -d':' -f2-)
    case "$manager" in
        p) sudo pacman -S --noconfirm --needed "$package" ;;
        y) yay -S --noconfirm --needed "$package" ;;
        g)
            repo_name=$(basename "$package" .git)
            target_dir="$HOME/.config/$repo_name"
            [ -d "$target_dir" ] || git clone "$package" "$target_dir"
            ;;
    esac
done < "$PACKAGE_FILE"

echo "[PROCESS] Copying configs..."
mkdir -p "$HOME/.config"
[ -d "config" ] && cp -r config/* "$HOME/.config/"

echo "[PROCESS] Making scripts executable..."
chmod +x "$HOME/.config/scripts/"*.sh 2>/dev/null

echo "[PROCESS] Creating directories..."
mkdir -p "$HOME/Pictures/Screenshots"
mkdir -p "$HOME/Pictures/Wallpapers"

echo "[PROCESS] Writing hyprland.conf..."
mkdir -p "$HOME/.config/hypr"
cat > "$HOME/.config/hypr/hyprland.conf" << 'HYPR'
exec-once = ~/.config/scripts/wallpaper.sh init
exec-once = waybar
exec-once = mako

$terminal = kitty
$menu = rofi -show drun -theme ~/.config/rofi/launchers/type-7/style-5.rasi

bind = SUPER, Return, exec, $terminal
bind = SUPER, R,      exec, $menu
bind = SUPER, Q,      killactive
bind = SUPER, M,      exit
bind = SUPER, F,      fullscreen

bind = , Print,      exec, ~/.config/scripts/screenshot.sh area
bind = SHIFT, Print, exec, ~/.config/scripts/screenshot.sh full
bind = SUPER, Print, exec, ~/.config/scripts/screenshot.sh window

bind = SUPER, left,  movefocus, l
bind = SUPER, right, movefocus, r
bind = SUPER, up,    movefocus, u
bind = SUPER, down,  movefocus, d

bind = SUPER, 1, workspace, 1
bind = SUPER, 2, workspace, 2
bind = SUPER, 3, workspace, 3
bind = SUPER, 4, workspace, 4
bind = SUPER, 5, workspace, 5
bind = SUPER, 6, workspace, 6
bind = SUPER, 7, workspace, 7
bind = SUPER, 8, workspace, 8
bind = SUPER, 9, workspace, 9

bind = SUPER SHIFT, 1, movetoworkspace, 1
bind = SUPER SHIFT, 2, movetoworkspace, 2
bind = SUPER SHIFT, 3, movetoworkspace, 3
bind = SUPER SHIFT, 4, movetoworkspace, 4
bind = SUPER SHIFT, 5, movetoworkspace, 5
bind = SUPER SHIFT, 6, movetoworkspace, 6
bind = SUPER SHIFT, 7, movetoworkspace, 7
bind = SUPER SHIFT, 8, movetoworkspace, 8
bind = SUPER SHIFT, 9, movetoworkspace, 9

bindm = SUPER, mouse:272, movewindow
bindm = SUPER, mouse:273, resizewindow

binde = , XF86AudioRaiseVolume,  exec, pactl set-sink-volume @DEFAULT_SINK@ +5%
binde = , XF86AudioLowerVolume,  exec, pactl set-sink-volume @DEFAULT_SINK@ -5%
bind  = , XF86AudioMute,         exec, pactl set-sink-mute @DEFAULT_SINK@ toggle
binde = , XF86MonBrightnessUp,   exec, brightnessctl set +5%
binde = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgb(4e6e4e)
    col.inactive_border = rgb(3e2e34)
    layout = dwindle
}

decoration {
    rounding = 8
    active_opacity = 1.0
    inactive_opacity = 0.95
    blur {
        enabled = true
        size = 5
        passes = 2
        new_optimizations = true
    }
}

animations {
    enabled = true
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows,    1, 5, myBezier
    animation = windowsOut, 1, 4, default, popin 80%
    animation = border,     1, 8, default
    animation = fade,       1, 6, default
    animation = workspaces, 1, 5, default
}

dwindle {
    force_split = 2
}

input {
    kb_layout = us,ru
    kb_options = grp:alt_shift_toggle
    follow_mouse = 1
    touchpad {
        natural_scroll = true
    }
}

misc {
    force_default_wallpaper = 0
    disable_hyprland_logo = true
}

windowrule = float, class:pavucontrol
windowrule = float, class:nm-connection-editor
windowrule = float, title:swappy
HYPR

echo "[PROCESS] Setting up Rust..."
command -v rustup &> /dev/null && rustup default stable

echo ""
echo "[SUCCESS] All done!"
echo ""
echo "  1. Put wallpapers into ~/Pictures/Wallpapers/"
echo "  2. Run: export XDG_RUNTIME_DIR=/run/user/\$(id -u) && Hyprland"
