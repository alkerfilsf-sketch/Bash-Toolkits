#!/usr/bin/env bash

# ==================================================
# DEVOPS CLINGY - SERVICE MONITOR
# ==================================================

printf '%s\n' "======================================================================================================================================================================"
printf '%s\n' "									  SERVICE MONITOR"
printf '%s\n' "======================================================================================================================================================================"
echo " "
echo " "
echo "|=-~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-=|"
read -r -p $'						Pilih mode pemeriksaan:\n\n				1. Berdasarkan Status		2. Langsung Semua\n\n				Pilihan: ' pilihan
echo "|=-~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-=|"

echo " "

case "$pilihan" in

    1|"Berdasarkan Status")

        read -r -p \
          "Masukkan status (active, inactive, failed, activating, deactivating, reloading, maintenance): " status_filter
	echo " "
        # Menyamakan huruf input
        status_filter=${status_filter,,}

        # Memeriksa status yang diperbolehkan
        case "$status_filter" in
            active|inactive|failed|activating|deactivating|reloading|maintenance)
                ;;
            *)
                echo "Status tidak valid."
                exit 1
                ;;
        esac

        # Mengambil nama service, status ACTIVE, dan SUB
        service_rows=$(
            systemctl list-units \
                --type=service \
                --state="$status_filter" \
                --no-legend \
                --plain \
                --full \
                --no-pager |
            awk '$1 ~ /\.service$/ {
                printf "%s\t%s\t%s\n", $1, $3, $4
            }'
        )
        ;;

    2|"Langsung Semua")

        # Mengambil semua service yang dikenal dalam daftar unit systemd
        service_rows=$(
            systemctl list-units \
                --type=service \
                --all \
                --no-legend \
                --plain \
                --full \
                --no-pager |
            awk '$1 ~ /\.service$/ {
                printf "%s\t%s\t%s\n", $1, $3, $4
            }'
        )
        ;;

    *)
        echo "Pilihan tidak valid."
        exit 1
        ;;
esac

# Menangani kondisi ketika tidak ada hasil
if [[ -z "$service_rows" ]]; then
    echo
    echo "Tidak ada service yang cocok dengan pilihan tersebut."
    exit 0
fi

# Menampilkan tabel
echo "|=|~=============================================================================================================================================================~|=|"
echo "}====================================================================== HASIL PEMERIKSAAN =========================================================================={"
echo "|=|~=============================================================================================================================================================~|=|"
echo " "

printf '%-110s %20s %16s\n' "SERVICE" "ACTIVE" "SUB"
printf '\n'

while IFS=$'\t' read -r service active sub
do
    [[ -z "$service" ]] && continue
    printf '%-110s %20s %16s\n' "$service" "$active" "$sub"
done <<< "$service_rows"


echo " "
echo " "
printf 'Waktu pemeriksaan: %s\n' "$(date '+%d-%m-%Y %H:%M:%S %Z')"
echo "|=|~=============================================================================================================================================================~|=|"
echo "|=|~=============================================================================================================================================================~|=|"
echo "Pemeriksaan selesai."
echo " "
