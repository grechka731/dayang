#!/bin/bash

set -e

echo "[PROCESS] Initializing system update..."
sudo pacman-key --init
sudo pacman-key --populate archlinux artix
sudo pacman -Syyu --noconfirm

echo "[PROCESS] Installing base-devel and git..."
sudo pacman -S --noconfirm base-devel git

if ! command -v yay &> /dev/null; then
    echo "[INFO] Installing yay..."
    cd /tmp
    rm -rf yay
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd -
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
        p)
            echo "[pacman] $package"
            sudo pacman -S --noconfirm --needed "$package"
            ;;
        y)
            echo "[yay] $package"
            yay -S --noconfirm --needed "$package"
            ;;
        g)
            repo_name=$(basename "$package" .git)
            target_dir="$HOME/.config/$repo_name"
            echo "[git] $package -> $target_dir"
            if [ -d "$target_dir" ]; then
                echo "[INFO] $target_dir exists, skipping."
            else
                git clone "$package" "$target_dir"
            fi
            ;;
        *)
            echo "[WARNING] Unknown prefix '$manager' for '$package', skipping."
            ;;
    esac
done < "$PACKAGE_FILE"

echo "[PROCESS] Copying configs..."
mkdir -p "$HOME/.config"

# FIX: source dir is 'config' not 'configs'
if [ -d "config" ]; then
    cp -r config/* "$HOME/.config/"
    echo "[INFO] config/ copied to $HOME/.config/"
else
    echo "[WARNING] config/ directory not found."
fi

echo "[PROCESS] Making scripts executable..."
if [ -d "$HOME/.config/scripts" ]; then
    chmod +x "$HOME/.config/scripts/"*.sh
fi

echo "[PROCESS] Creating default directories..."
mkdir -p "$HOME/Pictures/Screenshots"
mkdir -p "$HOME/Pictures/Wallpapers"

echo ""
echo "[SUCCESS] Done."
echo ""
echo "  Next steps:"
echo "  1. Put wallpapers into ~/Pictures/Wallpapers/"
echo "  2. Add to hyprland.conf:"
echo "       exec-once = ~/.config/scripts/wallpaper.sh init"
echo "       exec-once = waybar"
echo "       exec-once = mako"
echo "  3. Add keybinds to hyprland.conf:"
echo "       bind = , Print, exec, ~/.config/scripts/screenshot.sh area"
echo "       bind = SHIFT, Print, exec, ~/.config/scripts/screenshot.sh full"
echo "       bind = SUPER, Print, exec, ~/.config/scripts/screenshot.sh window"
echo "       bind = SUPER, R, exec, rofi -show drun -theme ~/.config/rofi/launchers/type-7/style-5.rasi"
echo "  4. Run: rustup default stable  (for Rust)"
