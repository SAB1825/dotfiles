#!/usr/bin/env bash
set -euo pipefail
shell_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
for command in phoenix python3 magick matugen notify-send; do
    if ! command -v "$command" >/dev/null; then
        echo "Phoenix needs $command. Run: bash $shell_dir/scripts/setup.sh" >&2
        if [[ ${1:-} == --session ]]; then exec waybar; fi
        exit 1
    fi
done
state_dir="$HOME/.local/state/ryu"
mkdir -p "$state_dir" "$HOME/Pictures" "$HOME/Videos" "$HOME/Screenshots"
[[ -f "$state_dir/state.json" ]] || printf '{}\n' > "$state_dir/state.json"
[[ -f "$state_dir/colors.json" ]] || cp "$shell_dir/theme/fallback.json" "$state_dir/colors.json"
# Stop competing desktop surfaces only after the dependencies are available.
pkill -x waybar || true
pkill -x mako || true
pkill -x swaybg || true
export QT_QPA_PLATFORM=wayland
exec phoenix "$shell_dir"
