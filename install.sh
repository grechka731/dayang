#!/bin/bash
# ============================================================
# install.sh — Depressive Rose dotfiles installer
# Artix Linux (OpenRC / runit / s6)
# ============================================================

RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[1;33m'
BLU='\033[0;34m'
RST='\033[0m'

step()  { echo -e "\n${BLU}[>>]${RST} $*"; }
ok()    { echo -e "${GRN}[OK]${RST} $*"; }
warn()  { echo -e "${YLW}[!!]${RST} $*"; }
fatal() { echo -e "${RED}[XX]${RST} $*"; exit 1; }

[ "$EUID" -eq 0 ] && fatal "Do NOT run as root. The script uses sudo internally."
[ -f packages.txt ] || fatal "packages.txt not found — run from the repo root."

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---- cleanup broken state from old installs ----
if [ -e "$HOME/.config/hypr" ] && [ ! -d "$HOME/.config/hypr" ]; then
    warn "~/.config/hypr is a file (broken old install) — removing..."
    rm -f "$HOME/.config/hypr"
fi

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

# ============================================================
# ---- Hyprland smart install ----
# ============================================================
install_hyprland() {
    step "Installing Hyprland (trying all methods)..."

    if sudo pacman -S --noconfirm --needed hyprland 2>/dev/null; then
        ok "Hyprland installed via pacman."
        return 0
    fi
    warn "pacman method failed, trying galaxy repo..."

    if sudo pacman -S --noconfirm --needed galaxy/hyprland 2>/dev/null; then
        ok "Hyprland installed via galaxy."
        return 0
    fi
    warn "galaxy method failed, trying AUR stable packages..."

    local FAILED=0
    for pkg in hyprutils aquamarine hyprlang hyprcursor hyprland; do
        if ! yay -S --noconfirm --needed \
                --answerdiff=None \
                --answerclean=None \
                --removemake \
                "$pkg" 2>/dev/null; then
            warn "AUR: could not install $pkg"
            FAILED=1
        fi
    done

    if command -v Hyprland &>/dev/null; then
        ok "Hyprland installed via AUR."
        return 0
    fi

    warn "Could not install Hyprland automatically."
    warn "Run manually after install: sudo pacman -S hyprland"
    return 1
}

install_hyprland

# ============================================================
# ---- packages from packages.txt ----
# ============================================================
step "Installing packages from packages.txt..."
ERRORS=()

while IFS= read -r line || [ -n "$line" ]; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    manager="${line%%:*}"
    package="${line#*:}"

    [ "$package" = "hyprland" ] && continue

    case "$manager" in
        p)
            if ! sudo pacman -S --noconfirm --needed "$package" 2>/dev/null; then
                warn "pacman: failed → $package (skipping)"
                ERRORS+=("pacman:$package")
            fi
            ;;
        y)
            if ! yay -S --noconfirm --needed \
                    --answerdiff=None \
                    --answerclean=None \
                    "$package" 2>/dev/null; then
                warn "yay: failed → $package (skipping)"
                ERRORS+=("yay:$package")
            fi
            ;;
        g)
            repo_name="$(basename "$package" .git)"
            target="$HOME/.config/$repo_name"
            if [ -d "$target" ]; then
                git -C "$target" pull --ff-only 2>/dev/null || true
                ok "Updated $repo_name"
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
if [ -e "$HOME/.config/hypr" ] && [ ! -d "$HOME/.config/hypr" ]; then
    rm -f "$HOME/.config/hypr"
fi
mkdir -p "$HOME/.config/hypr"
cp "$DOTFILES_DIR/hypr/hyprland.conf" "$HOME/.config/hypr/hyprland.conf"
ok "hyprland.conf installed."

# ---- scripts executable ----
step "Making scripts executable..."
find "$HOME/.config/scripts" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
ok "Scripts are executable."

# ---- directories ----
step "Creating required directories..."
mkdir -p "$HOME/Pictures/Screenshots"
mkdir -p "$HOME/Pictures/Wallpapers"
ok "Directories ready."

# ---- Rust ----
if command -v rustup &>/dev/null; then
    step "Setting rustup default to stable..."
    if rustup default stable 2>/dev/null; then
        ok "Rust stable active."
    else
        warn "rustup: no internet? Run 'rustup default stable' manually later."
    fi
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
echo -e "     (in VirtualBox add: WLR_RENDERER=pixman WLR_BACKENDS=drm,libinput)"
echo ""
echo -e "  ${YLW}Keybinds:${RST}"
echo -e "  ${BLU}Super+Return${RST}  terminal  |  ${BLU}Super+R${RST}  launcher"
echo -e "  ${BLU}Super+Q${RST}       close     |  ${BLU}Super+F${RST}  fullscreen"
echo -e "  ${BLU}Super+V${RST}       float     |  ${BLU}Super+M${RST}  exit"
echo -e "  ${BLU}Print${RST}         screenshot area"
echo ""
