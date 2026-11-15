#!/usr/bin/env bash
set -euo pipefail
shell_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# Run this script as your normal user from a terminal in the niri session.
sudo pacman -Syu --needed matugen imagemagick libnotify qt6-svg ttf-cascadia-code-nerd ttf-jetbrains-mono-nerd brightnessctl
if ! command -v wl-screenrec >/dev/null; then
    yay -S --needed wl-screenrec
fi
fc-cache -f
niri validate
mkdir -p "$HOME/.local/state/ryu"
python3 "$shell_dir/scripts/theme.py" "$shell_dir/assets/wallpaper.svg" dark scheme-content
printf '\nStarting Phoenix. Keep this terminal open for the first test; Ctrl+C stops it.\n'
exec bash "$shell_dir/scripts/start.sh"
