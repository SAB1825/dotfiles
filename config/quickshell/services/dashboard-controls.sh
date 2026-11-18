#!/usr/bin/env bash
export LC_ALL=C

case "$1" in
    status)
        brightness=$(brightnessctl --class=backlight --machine-readable info 2>/dev/null |
            cut -d, -f4 | tr -d '%')
        night_light=unavailable
        if command -v wlsunset >/dev/null; then
            night_light=available
        fi
        printf '%s\n' "$brightness" "$night_light"
        ;;
    brightness) exec brightnessctl --class=backlight --quiet set "$2%" ;;
    *) exit 2 ;;
esac
