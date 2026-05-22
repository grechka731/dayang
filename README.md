# artix-dots

Hyprland dotfiles. Style: Depressive Rose.

## Structure

```
config/
├── kitty/
│   ├── kitty.conf
│   └── themes/depressive_rose.conf
├── mako/config
├── rofi/
│   ├── config.rasi
│   ├── colors/          ← 18 color schemes
│   ├── images/          ← background images for rofi
│   └── launchers/type-7/style-5.rasi
├── waybar/
│   ├── config.jsonc
│   └── style.css
└── scripts/
    ├── screenshot.sh
    └── wallpaper.sh
packages.txt
install.sh
```

## Install

```bash
git clone <your-repo>
cd <repo>
bash install.sh
```

## After install

**1. Wallpapers** — put images into `~/Pictures/Wallpapers/`

**2. hyprland.conf** — add to `exec-once`:

```ini
exec-once = ~/.config/scripts/wallpaper.sh init
exec-once = waybar
exec-once = mako
```

**3. Keybinds** — add to hyprland.conf:

```ini
bind = , Print,       exec, ~/.config/scripts/screenshot.sh area
bind = SHIFT, Print,  exec, ~/.config/scripts/screenshot.sh full
bind = SUPER, Print,  exec, ~/.config/scripts/screenshot.sh window
bind = SUPER, R,      exec, rofi -show drun -theme ~/.config/rofi/launchers/type-7/style-5.rasi
```

**4. Rust** (first run):

```bash
rustup default stable
```

## Screenshots

| Bind | Action |
|------|--------|
| `Print` | Select area → open in swappy editor |
| `Shift+Print` | Fullscreen → save + copy to clipboard |
| `Super+Print` | Active window → open in swappy editor |

Saved to: `~/Pictures/Screenshots/`

## Wallpapers

| Command | Action |
|---------|--------|
| `wallpaper.sh init` | Start daemon + set random wallpaper (use in exec-once) |
| `wallpaper.sh set <file>` | Set specific wallpaper |
| `wallpaper.sh random [dir]` | Set random from directory |
| `wallpaper.sh cycle [dir] [seconds]` | Auto-cycle wallpapers |

## Waybar

| Click | Action |
|-------|--------|
| 󰹑 LMB | Screenshot area → swappy |
| 󰹑 RMB | Screenshot fullscreen → clipboard |
| 󰐥 LMB | wlogout (power menu) |
| 󰐥 RMB | Suspend |
| Clock LMB | Toggle time/date format |
| Clock RMB | Toggle calendar month/year |
| CPU/RAM click | Open htop in kitty |
| Volume scroll | ±2% volume |

## Fixes applied

- `depressive_rose.conf`: `background_selection` → `selection_background`
- `mako/config`: `sort=-time` moved before urgency sections; added missing `[urgency=normal]`; added `default-timeout=0` for high urgency
- `install.sh`: `configs/` → `config/` (dir name mismatch); added `--needed` flag to pacman/yay to skip already-installed; added `chmod +x` for scripts; added directory creation for screenshots/wallpapers
- `packages.txt`: added `wlogout` (used by waybar power button); added `jq` (used by screenshot window mode)
- `waybar/config.jsonc`: removed Cyrillic strings from format fields (can break some locales); added `custom/screenshot` module
- `waybar/style.css`: added `#custom-screenshot` styles
