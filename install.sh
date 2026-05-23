#!/bin/bash
# ============================================================
# install.sh — Depressive Rose dotfiles installer
# Artix Linux (OpenRC / runit / s6)
# ============================================================

# NO set -e — we handle errors manually so one failed package
# doesn't abort the whole install.

RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[1;33m'
BLU='\033[0;34m'
RST='\033[0m'

step()  { echo -e "\n${BLU}[>>]${RST} $*"; }
ok()    { echo -e "${GRN}[OK]${RST} $*"; }
warn()  { echo -e "${YLW}[!!]${RST} $*"; }
fatal() { echo -e "${RED}[XX]${RST} $*"; exit 1; }

# ---- sanity checks ----
[ "$EUID" -eq 0 ] && fatal "Do NOT run as root. The script uses sudo internally."
[ -f packages.txt ] || fatal "packages.txt not found — run from the repo root."

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---- keyring ----
step "Refreshing pacman keyring..."
sudo pacman-key --init
sudo pacman-key --populate artix archlinux 2>/dev/null \
    || sudo pacman-key --populate artix
sudo pacman -Syyu --noconfirm
ok "Keyring and repos updated."

# ---- base-devel + git ----
step "Installing base-devel and git..."
sudo pacman -S --noconfirm --needed base-devel git curl
ok "base-devel ready."

# ---- yay ----
if ! command -v yay &>/dev/null; then
    step "Installing yay (AUR helper)..."
    ORIG="$(pwd)"
    cd /tmp
    rm -rf yay
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd "$ORIG"
    ok "yay installed."
else
    ok "yay already present."
fi

# ---- packages ----
step "Installing packages from packages.txt..."
SKIP_PKGS=("steam" "discord")   # optional — skip in minimal/VM installs
ERRORS=()

while IFS= read -r line || [ -n "$line" ]; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    manager="${line%%:*}"
    package="${line#*:}"

    # skip known-optional packages if pacman multilib is not enabled
    if [[ " ${SKIP_PKGS[*]} " == *" $package "* ]]; then
        warn "Skipping optional package: $package"
        continue
    fi

    case "$manager" in
        p)
            if ! sudo pacman -S --noconfirm --needed "$package" 2>/dev/null; then
                warn "pacman: failed → $package (skipping)"
                ERRORS+=("pacman:$package")
            fi
            ;;
        y)
            if ! yay -S --noconfirm --needed --answerdiff=None --answerclean=None "$package" 2>/dev/null; then
                warn "yay: failed → $package (skipping)"
                ERRORS+=("yay:$package")
            fi
            ;;
        g)
            repo_name="$(basename "$package" .git)"
            target="$HOME/.config/$repo_name"
            if [ -d "$target" ]; then
                ok "git repo '$repo_name' already cloned, pulling..."
                git -C "$target" pull --ff-only 2>/dev/null || true
            else
                git clone "$package" "$target" && ok "Cloned $repo_name"
            fi
            ;;
        *)
            warn "Unknown manager '$manager' for '$package', skipping."
            ;;
    esac
done < "$DOTFILES_DIR/packages.txt"

if [ ${#ERRORS[@]} -gt 0 ]; then
    warn "Some packages failed (non-fatal):"
    for e in "${ERRORS[@]}"; do echo "    - $e"; done
fi

# ---- copy configs ----
step "Copying configs to ~/.config/ ..."
mkdir -p "$HOME/.config"

if [ -d "$DOTFILES_DIR/config" ]; then
    cp -r "$DOTFILES_DIR/config/." "$HOME/.config/"
    ok "configs copied."
else
    warn "'config/' directory not found — skipping."
fi

# ---- hyprland.conf ----
step "Writing hypr/hyprland.conf..."
# mkdir -p is idempotent — safe even if dir exists
mkdir -p "$HOME/.config/hypr"
cp "$DOTFILES_DIR/hypr/hyprland.conf" "$HOME/.config/hypr/hyprland.conf"
ok "hyprland.conf installed."

# ---- scripts executable ----
step "Making scripts executable..."
find "$HOME/.config/scripts" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
ok "Scripts are executable."

# ---- required directories ----
step "Creating required directories..."
mkdir -p "$HOME/Pictures/Screenshots"
mkdir -p "$HOME/Pictures/Wallpapers"
ok "Directories ready."

# ---- rofi config ----
step "Setting up rofi config..."
mkdir -p "$HOME/.config/rofi/launchers/type-7"
mkdir -p "$HOME/.config/rofi/colors"

if [ ! -f "$HOME/.config/rofi/config.rasi" ]; then
cat > "$HOME/.config/rofi/config.rasi" << 'EOF'
configuration {
    modi:               "drun,run,window";
    show-icons:         true;
    drun-display-format: "{name}";
    display-drun:       " Apps";
    display-run:        " Run";
    display-window:     "󰖯 Windows";
    icon-theme:         "Papirus-Dark";
    font:               "JetBrainsMono Nerd Font 11";
}
EOF
    ok "rofi config.rasi created."
fi

cat > "$HOME/.config/rofi/colors/depressive-rose.rasi" << 'EOF'
* {
    bg:           #1a1016;
    bg-alt:       #130b0e;
    bg-surface:   #221520;
    bg-hover:     #2e1e28;
    fg:           #f0e6e6;
    fg-dim:       #cdd6f4;
    fg-muted:     #6c7086;
    accent-green: #4e6e4e;
    accent-rose:  #8e4e5e;
    accent-blue:  #6e8eae;
    border:       #3e2e34;
}
EOF

cat > "$HOME/.config/rofi/launchers/type-7/style-5.rasi" << 'EOF'
/* Depressive Rose — rofi type-7 style-5 */
@import "../../colors/depressive-rose.rasi"

* {
    font:         "JetBrainsMono Nerd Font 11";
    background:   transparent;
    text-color:   @fg;
}
configuration {
    show-icons:  true;
    icon-theme:  "Papirus-Dark";
}
window {
    width:            480px;
    background-color: @bg;
    border:           2px solid;
    border-color:     @accent-green;
    border-radius:    12px;
}
mainbox {
    background-color: transparent;
    children:  [ inputbar, listview ];
    padding:   12px;
    spacing:   8px;
}
inputbar {
    background-color: @bg-surface;
    border-radius:    8px;
    border:           1px solid @border;
    children:         [ prompt, entry ];
    padding:          8px 12px;
    spacing:          8px;
}
prompt {
    color: @accent-green;
}
entry {
    color:             @fg;
    placeholder:       "Search...";
    placeholder-color: @fg-muted;
}
listview {
    background-color: transparent;
    columns:   1;
    lines:     8;
    spacing:   2px;
    scrollbar: false;
}
element {
    background-color: transparent;
    border-radius:    6px;
    padding:          6px 10px;
    spacing:          8px;
    children:         [ element-icon, element-text ];
}
element selected {
    background-color: @bg-hover;
    border:           1px solid @accent-green;
}
element-icon {
    size:             24px;
    background-color: transparent;
}
element-text {
    background-color: transparent;
    color:            @fg;
    vertical-align:   0.5;
}
EOF
ok "rofi theme installed."

# ---- Rust ----
if command -v rustup &>/dev/null; then
    step "Setting rustup default to stable..."
    rustup default stable || true
    ok "Rust stable active."
fi

# ---- done ----
echo ""
echo -e "${GRN}╔══════════════════════════════════════════════╗${RST}"
echo -e "${GRN}║         Installation complete!               ║${RST}"
echo -e "${GRN}╚══════════════════════════════════════════════╝${RST}"
echo ""
echo -e "  ${YLW}Next steps:${RST}"
echo -e "  1. Put wallpapers into ${BLU}~/Pictures/Wallpapers/${RST}"
echo -e "  2. Start Hyprland:"
echo -e "     ${BLU}export XDG_RUNTIME_DIR=/run/user/\$(id -u) && Hyprland${RST}"
echo ""
echo -e "  ${YLW}Keybinds:${RST}"
echo -e "  ${BLU}Super+Return${RST}  terminal  |  ${BLU}Super+R${RST} launcher"
echo -e "  ${BLU}Super+Q${RST}       close     |  ${BLU}Super+F${RST} fullscreen"
echo -e "  ${BLU}Super+V${RST}       float     |  ${BLU}Super+M${RST} exit"
echo -e "  ${BLU}Print${RST}         screenshot area → swappy"
echo -e "  ${BLU}Shift+Print${RST}   fullscreen → clipboard"
echo ""
