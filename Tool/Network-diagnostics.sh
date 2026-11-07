
#!/usr/bin/env bash

# ==========================================
# DEVOPS CLINGY - NETWORK DIAGNOSTICS
# ==========================================

line="========================================================================================================================================================================"

# Mengambil gateway dan interface dari default route
gateway=$(ip route show default 2>/dev/null | awk 'NR==1 {print $3}')

interface=$(ip route show default 2>/dev/null |
    awk 'NR==1 {
        for (i=1; i<=NF; i++)
            if ($i=="dev") {
                print $(i+1)
                exit
            }
    }')

# Mengambil IP IPv4 dari interface utama
local_ip=""

if [[ -n "$interface" ]]; then
    local_ip=$(ip -4 -o addr show dev "$interface" 2>/dev/null |
        awk 'NR==1 {
            split($4, ip, "/")
            print ip[1]
        }')
fi

[[ -n "$local_ip" ]] || local_ip="Tidak tersedia"
[[ -n "$gateway" ]] || gateway="Tidak tersedia"
[[ -n "$interface" ]] || interface="Tidak tersedia"

# Memeriksa koneksi ke gateway
gateway_status="WARN"

if [[ "$gateway" != "Tidak tersedia" ]]; then
    if ping -c 2 -W 2 "$gateway" >/dev/null 2>&1; then
        gateway_status="PASS"
    fi
fi

# Memeriksa keterjangkauan IP eksternal
ip_status="WARN"

if ping -c 2 -W 2 1.1.1.1 >/dev/null 2>&1; then
    ip_status="PASS"
fi

# Memeriksa DNS
dns_result=$(getent hosts google.com 2>/dev/null)
dns_status="WARN"
dns_ip="Tidak tersedia"

if [[ -n "$dns_result" ]]; then
    dns_status="PASS"
    dns_ip=$(printf '%s\n' "$dns_result" |
        awk 'NR==1 {print $1}')
fi

# Menampilkan hasil
echo " "
printf '%s\n' "$line"
printf '      		        							DEVOPS CLINGY\n'
printf '             								     NETWORK DIAGNOSTICS\n'
printf '%s\n' "$line"

echo " "
printf '\n[ NETWORK INFORMATION ]\n'
printf '  %-24s : %s\n' "Interface" "$interface"
printf '  %-24s : %s\n' "Local IPv4" "$local_ip"
printf '  %-24s : %s\n' "Default Gateway" "$gateway"

printf '\n[ CONNECTIVITY CHECK ]\n'
printf '  %-24s : %s\n' "Gateway Reachability" "$gateway_status"
printf '  %-24s : %s\n' "External IP (1.1.1.1)" "$ip_status"

printf '\n[ DNS CHECK ]\n'
printf '  %-24s : %s\n' "DNS Resolution" "$dns_status"
printf '  %-24s : %s\n' "Resolved IP" "$dns_ip"
echo " "

printf '  \n\n%-24s : %s' "Check Time" "$(date '+%d-%m-%Y %H:%M:%S %Z')"
printf '\n%s\n' "$line"
echo " "
