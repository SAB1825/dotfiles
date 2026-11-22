#!/usr/bin/env bash

read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
cpu_total=$((user + nice + system + idle + iowait + irq + softirq + steal))
cpu_idle=$((idle + iowait))

mem_total=0
mem_available=-1
while read -r key value _; do
    case "$key" in
        MemTotal:) mem_total=$value ;;
        MemAvailable:) mem_available=$value; break ;;
    esac
done < /proc/meminfo

read_temperature() {
    local path=$1 millidegrees
    [[ -r $path ]] && read -r millidegrees < "$path" || return 1
    [[ $millidegrees =~ ^-?[0-9]+$ ]] || return 1
    (( millidegrees >= -50000 && millidegrees <= 150000 )) || return 1
    printf '%s' "$millidegrees"
}

cpu_temperature() {
    local sensor name label temperature
    for sensor in /sys/class/hwmon/hwmon*; do
        [[ -r $sensor/name ]] && read -r name < "$sensor/name" || continue
        case "$name" in
            k10temp|zenpower|coretemp|cpu_thermal)
                for label in "$sensor"/temp*_label; do
                    [[ -r $label ]] && read -r name < "$label" || continue
                    case "$name" in
                        Tdie|Package\ id*)
                            if temperature=$(read_temperature "${label%_label}_input"); then
                                printf '%s' "$temperature"
                                return
                            fi
                            ;;
                    esac
                done
                if temperature=$(read_temperature "$sensor/temp1_input"); then
                    printf '%s' "$temperature"
                    return
                fi
                ;;
        esac
    done

    for sensor in /sys/class/thermal/thermal_zone*; do
        [[ -r $sensor/type ]] && read -r name < "$sensor/type" || continue
        case "$name" in
            x86_pkg_temp|cpu-thermal|cpu_thermal|soc_thermal)
                if temperature=$(read_temperature "$sensor/temp"); then
                    printf '%s' "$temperature"
                    return
                fi
                ;;
        esac
    done
}

printf '%s\t%s\t%s\t%s\t%s\n' "$cpu_total" "$cpu_idle" "$mem_total" "$mem_available" "$(cpu_temperature)"
