#!/usr/bin/env bash
set -euo pipefail
if ! command -v fzf >/dev/null; then
    if [[ -n ${TMUX:-} ]]; then
        tmux choose-tree -Zw
    else
        tmux new-session -A -s main
    fi
    exit
fi
project="$(find "$HOME/Rice" "$HOME/Projects" "$HOME/dev" -mindepth 1 -maxdepth 2 -type d -not -path '*/.git*' 2>/dev/null | fzf --prompt='Project > ' || true)"
[[ -n "$project" ]] || exit 0
name="$(basename "$project" | tr '.: ' '___')"
if ! tmux has-session -t "=$name" 2>/dev/null; then
    tmux new-session -d -s "$name" -c "$project"
fi
if [[ -n ${TMUX:-} ]]; then
    tmux switch-client -t "=$name"
else
    exec tmux attach-session -t "=$name"
fi
