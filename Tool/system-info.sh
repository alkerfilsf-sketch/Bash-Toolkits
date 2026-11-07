
#!/usr/bin/env bash

# ============================================================
# DEVOPS CLINGY - SYSTEM INFORMATION
# Linux, hardware, memory, storage, network, and runtime details
# ============================================================

# ---------- Helper ----------
# Sebagai sebuah Function
read_dmi() {
    local value
    value=$(cat "$1" 2>/dev/null)

    if [[ -n "$value" ]]; then
        printf '%s' "$value"
    else
        printf 'Tidak tersedia'
    fi
}

# ---------- Operating System ----------
. /etc/os-release

os_name=${PRETTY_NAME:-"Linux (unknown distribution)"}
kernel=$(uname -r)
architecture=$(uname -m)
hostname_value=$(hostname)
username=${USER:-$(id -un)}
home_directory=${HOME:-"$PWD"}
uptime_value=$(uptime -p 2>/dev/null || printf 'Tidak tersedia')
load_average=$(awk '{printf "%s, %s, %s", $1, $2, $3}' /proc/loadavg)

# ---------- Laptop / Firmware ----------
manufacturer=$(read_dmi /sys/class/dmi/id/sys_vendor)
model=$(read_dmi /sys/class/dmi/id/product_name)
product_version=$(read_dmi /sys/class/dmi/id/product_version)
bios_version=$(read_dmi /sys/class/dmi/id/bios_version)
bios_date=$(read_dmi /sys/class/dmi/id/bios_date)

# ---------- CPU ----------
cpu_model=$(awk -F: '
    /^model name[[:space:]]*:/ {
        sub(/^[[:space:]]+/, "", $2)
        print $2
        exit
    }
' /proc/cpuinfo)

logical_cpus=$(nproc 2>/dev/null || printf 'Tidak tersedia')

# Approximate model introduction year; not the laptop manufacturing date.
case "$model" in
    *8440p*) model_year=2010 ;;
    *)       model_year="" ;;
esac

if [[ -n "$model_year" ]]; then
    model_age="~$(( $(date +%Y) - model_year )) tahun (perkiraan usia model)"
else
    model_age="Tidak dapat dipastikan otomatis"
fi

# ---------- Memory ----------
memory_info=$(free -h | awk '/^Mem:/ {
    printf "%s total | %s used | %s free | %s available", $2, $3, $4, $7
}')

swap_info=$(free -h | awk '/^Swap:/ {
    printf "%s total | %s used | %s free", $2, $3, $4
}')

# ---------- Storage ----------
disk_info=$(df -hP / | awk 'NR == 2 {
    printf "%s total | %s used | %s available | %s used", $2, $3, $4, $5
}')

# ---------- Network ----------
local_ip=$(hostname -I 2>/dev/null | xargs)
gateway=$(ip route show default 2>/dev/null | awk 'NR == 1 {print $3}')

[[ -n "$local_ip" ]] || local_ip="Tidak tersedia"
[[ -n "$gateway" ]] || gateway="Tidak tersedia"

# ---------- Runtime ----------
process_count=$(ps -e --no-headers 2>/dev/null | wc -l | tr -d ' ')
check_time=$(date '+%d-%m-%Y %H:%M:%S %Z')

# ---------- Display ----------
line="================================================================"

printf '%s\n' "$line"
printf '                    DEVOPS CLINGY\n'
printf '                     SYSTEM INFO\n'
printf '%s\n' "$line"

printf '\n[ SYSTEM INFORMATION ]\n'
printf '  %-20s : %s\n' "Username" "$username"
printf '  %-20s : %s\n' "Hostname" "$hostname_value"
printf '  %-20s : %s\n' "Operating System" "$os_name"
printf '  %-20s : %s\n' "Version ID" "${VERSION_ID:-Tidak tersedia}"
printf '  %-20s : %s\n' "Kernel" "$kernel"
printf '  %-20s : %s\n' "Architecture" "$architecture"
printf '  %-20s : %s\n' "Home Directory" "$home_directory"
printf '  %-20s : %s\n' "Uptime" "$uptime_value"
printf '  %-20s : %s\n' "Load Average (1/5/15m)" "$load_average"

printf '\n[ LAPTOP INFORMATION ]\n'
printf '  %-20s : %s\n' "Manufacturer" "$manufacturer"
printf '  %-20s : %s\n' "Model" "$model"
printf '  %-20s : %s\n' "Product Version" "$product_version"
printf '  %-20s : %s\n' "CPU Model" "${cpu_model:-Tidak tersedia}"
printf '  %-20s : %s\n' "Logical CPUs" "$logical_cpus"
printf '  %-20s : %s\n' "BIOS Version" "$bios_version"
printf '  %-20s : %s\n' "BIOS Date" "$bios_date"
printf '  %-20s : %s\n' "Model Age" "$model_age"

printf '\n[ MEMORY ]\n'
printf '  %-20s : %s\n' "RAM" "$memory_info"
printf '  %-20s : %s\n' "Swap" "$swap_info"

printf '\n[ STORAGE ]\n'
printf '  %-20s : %s\n' "Root Filesystem (/)" "$disk_info"

printf '\n[ NETWORK ]\n'
printf '  %-20s : %s\n' "Local IP" "$local_ip"
printf '  %-20s : %s\n' "Default Gateway" "$gateway"

printf '\n[ SYSTEM SUMMARY ]\n'
printf '  %-20s : %s\n' "Process Count" "$process_count"
printf '  %-20s : %s\n' "Check Time" "$check_time"

printf '\n%s\n' "$line"
