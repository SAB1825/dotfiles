#!/usr/bin/env bash
set -euo pipefail

case "$1" in
    store)
        case "${CLIPBOARD_STATE:-data}" in
            data) exec cliphist store ;;
        esac
        ;;
    list)
        exec cliphist list
        ;;
    copy)
        [[ "$2" =~ ^[0-9]+$ ]]
        entry=$(mktemp)
        trap 'rm -f -- "$entry"' EXIT
        cliphist decode "$2" > "$entry"
        if [[ -n "$3" ]]; then
            wl-copy --type "$3" < "$entry"
        else
            wl-copy < "$entry"
        fi
        ;;
    thumbnail)
        [[ "$2" =~ ^[0-9]+$ ]]
        case "$3" in
            png|jpeg|gif|webp|bmp|tiff) ;;
            *) exit 1 ;;
        esac
        cliphist decode "$2" |
            magick -limit memory 64MiB -limit map 128MiB -limit disk 0 "$3:-[0]" \
                -auto-orient -thumbnail '120x68^' -gravity center -extent 120x68 png:- |
            base64 -w0
        ;;
    *) exit 2 ;;
esac
