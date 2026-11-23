#!/usr/bin/env bash
set -u

session="${XDG_RUNTIME_DIR:?}/hypr-region-${HYPRLAND_INSTANCE_SIGNATURE:-default}"
exec 9>"$session.lock" || exit 1
if ! flock -n 9; then
    if [[ -s $session.pid ]] && read -r pid 2>/dev/null < "$session.pid" &&
        [[ $pid =~ ^[0-9]+$ ]] &&
        [[ $(cat "/proc/$pid/comm" 2>/dev/null) == wf-recorder ]]; then
        kill -INT "$pid" 2>/dev/null
    fi
    exit 0
fi

rm -f -- "$session.pid"
trap 'rm -f -- "$session.pid"' EXIT

region=$(slurp 9>&-) && [[ -n $region ]] || exit 0
videos=$(xdg-user-dir VIDEOS)
videos="${videos:-$HOME/Videos}"
if ! mkdir -p -- "$videos"; then
    notify-send "Screen recording failed" "Could not create $videos" 9>&-
    exit 1
fi
output="$videos/Recording-$(date +%Y%m%d-%H%M%S-%N).mp4"

env --default-signal=INT wf-recorder -g "$region" -f "$output" 9>&- &
pid=$!
printf '%s\n' "$pid" > "$session.pid"

if wait "$pid" && [[ -s $output ]]; then
    notify-send "Screen recording saved" "$output" 9>&-
else
    notify-send "Screen recording failed" 9>&-
    exit 1
fi
