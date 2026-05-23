# artix-dots — Depressive Rose

Hyprland dotfiles for **Artix Linux**. Dark rose + forest green aesthetic.

## Structure

```
artix-dots/
├── hypr/
│   └── hyprland.conf          ← main config (Hyprland 0.41+)
├── config/
│   ├── kitty/
│   │   ├── kitty.conf
│   │   └── themes/depressive_rose.conf
│   ├── mako/config
│   ├── rofi/                  ← created by install.sh
│   │   ├── config.rasi
│   │   ├── colors/depressive-rose.rasi
│   │   └── launchers/type-7/style-5.rasi
│   ├── waybar/
│   │   ├── config.jsonc
│   │   └── style.css
│   └── scripts/
│       ├── screenshot.sh
│       └── wallpaper.sh
├── install.sh
└── packages.txt
```

## Install

```bash
git clone https://github.com/grechka731/dayang.git
cd dayang
bash install.sh
```

The installer will:
1. Update keyring and repos
2. Install yay (if missing)
3. Install all packages from `packages.txt`
4. Copy configs to `~/.config/`
5. Install hyprland.conf
6. Create rofi theme and colors
7. Make scripts executable
8. Create `~/Pictures/Screenshots/` and `~/Pictures/Wallpapers/`

## After install

**1. Wallpapers** — put images into `~/Pictures/Wallpapers/`

**2. Start Hyprland:**

```bash
export XDG_RUNTIME_DIR=/run/user/$(id -u) && Hyprland
```

Or add to your display manager / `.bash_profile`.

## Keybinds

| Bind | Action |
|------|--------|
| `Super+Return` | Open kitty terminal |
| `Super+R` | Rofi launcher |
| `Super+Q` | Close window |
| `Super+F` | Fullscreen |
| `Super+V` | Toggle float |
| `Super+M` | Exit Hyprland |
| `Super+arrows` | Focus window |
| `Super+Shift+arrows` | Move window |
| `Super+Alt+arrows` | Resize window |
| `Super+1-9` | Switch workspace |
| `Super+Shift+1-9` | Move window to workspace |
| `Print` | Screenshot area → swappy |
| `Shift+Print` | Screenshot fullscreen → clipboard |
| `Super+Print` | Screenshot active window → swappy |

## Waybar interactions

| Element | Click | Action |
|---------|-------|--------|
| 󰹑 Screenshot | LMB | Area screenshot → swappy |
| 󰹑 Screenshot | RMB | Fullscreen → clipboard |
| 󰐥 Power | LMB | wlogout menu |
| 󰐥 Power | RMB | Suspend |
| Clock | LMB | Toggle time/date |
| Clock | RMB | Toggle calendar |
| CPU / RAM | LMB | Open htop in kitty |
| Volume | Scroll | ±2% volume |
| Network | RMB | nm-connection-editor |

## Wallpaper commands

```bash
wallpaper.sh init              # Start daemon + random (use in exec-once)
wallpaper.sh set <file>        # Set specific file
wallpaper.sh random [dir]      # Random from directory
wallpaper.sh cycle [dir] [sec] # Auto-cycle every N seconds (default 1800)
```

## Colors

| Name | Hex |
|------|-----|
| Background | `#1a1016` |
| Surface | `#221520` |
| Foreground | `#f0e6e6` |
| Accent Green | `#4e6e4e` |
| Accent Rose | `#8e4e5e` |
| Accent Blue | `#6e8eae` |
| Border | `#3e2e34` |

## Fixes vs original (Hyprland 0.41+)

- `windowrule = float, class:X` → `windowrulev2 = float, class:(X)` — fixes the "invalid field float: missing a value" error on lines 101-103
- Removed `new_optimizations` from `blur {}` (removed in Hyprland 0.40)
- Removed `cursor_trail` from kitty.conf (syntax changed)
- Added `shadow {}` block syntax (new in Hyprland 0.41)
- Added `resize_on_border`, `focus_on_activate`, `animate_manual_resizes` to misc/general
- install.sh: proper error handling, colored output, summary
- rofi config + theme created automatically by install.sh
- Added `playerctl` for media key support
- Added `polkit-gnome`, `xdg-desktop-portal-hyprland` to packages
