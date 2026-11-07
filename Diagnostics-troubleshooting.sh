
# ==========================================
# DNS & NETWORK TROUBLESHOOTING FUNCTIONS
# ==========================================


check_dns() {
    local dns_servers dns_server

    if ! command -v dig >/dev/null 2>&1; then
        echo "[GAGAL] Perintah dig belum tersedia."
        return 1
    fi

    dns_servers="$(resolvectl dns wlo1 2>/dev/null |
        sed 's/^[^:]*: *//')"

    if [[ -z "$dns_servers" ]]; then
        echo "[GAGAL] DNS pada interface wlo1 tidak ditemukan."
        return 1
    fi

    for dns_server in $dns_servers; do
        # DNS server lokal stub bukan server upstream.
        [[ "$dns_server" == "127.0.0.53" ||
           "$dns_server" == "::1" ]] && continue

        echo "[INFO] Menguji DNS: $dns_server"

        if dig @"$dns_server" example.com A \
            +time=3 +tries=1 +noall +comments |
            grep -q 'status: NOERROR'; then
            echo "[INFO] DNS $dns_server merespons."
            return 0
        fi

        echo "[PERINGATAN] DNS $dns_server tidak memberikan respons valid."
    done

    echo "[GAGAL] Semua DNS upstream yang diuji gagal."
    return 1
}


check_internet_ip() {
    ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1 ||
    ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1
}

repair_gateway() {
    local gateway
    gateway="$(ip -4 route show default | awk 'NR==1 {print $3}')"

    if [[ -z "$gateway" ]]; then
        echo "[GAGAL] Gateway tidak ditemukan."
        echo "[INFO] Memeriksa koneksi NetworkManager..."

        if command -v nmcli >/dev/null 2>&1; then
            nmcli device status
        fi

        return 1
    fi

    echo "[INFO] Gateway ditemukan: $gateway"

    if ping -c 2 -W 2 "$gateway"; then
        echo "[BERHASIL] Gateway dapat dijangkau."
        return 0
    fi

    echo "[INFO] Gateway tidak merespons."
    echo "[INFO] Mencoba mengaktifkan kembali profil koneksi..."

    local iface conn
    iface="$(ip -o route get 1.1.1.1 2>/dev/null |
        awk '{for (i=1; i<=NF; i++) if ($i=="dev") {print $(i+1); exit}}')"

    if [[ -n "$iface" ]] && command -v nmcli >/dev/null 2>&1; then
        conn="$(nmcli -g GENERAL.CONNECTION device show "$iface" 2>/dev/null)"

        if [[ -n "$conn" && "$conn" != "--" ]]; then
            if nmcli connection up "$conn"; then
                sleep 2

                if ping -c 2 -W 2 "$gateway"; then
                    echo "[BERHASIL] Gateway kembali merespons."
                    return 0
                fi
            fi
        fi
    fi

    echo "[GAGAL] Gateway belum berhasil dipulihkan."
    return 1
}



repair_dns_with_nm() {
    local iface conn old_dns old_ignore
    local backup_dir backup_file resolv_backup
    local resolv_target="/run/systemd/resolve/stub-resolv.conf"

    echo "========================================"
    echo "       PERBAIKAN DNS OTOMATIS"
    echo "========================================"

    # 1. Periksa dependensi
    if ! command -v nmcli >/dev/null 2>&1; then
        echo "[GAGAL] NetworkManager tidak tersedia."
        return 1
    fi

    if ! command -v resolvectl >/dev/null 2>&1; then
        echo "[GAGAL] resolvectl tidak tersedia."
        return 1
    fi

    if ! command -v sudo >/dev/null 2>&1; then
        echo "[GAGAL] sudo tidak tersedia."
        return 1
    fi

    # 2. Temukan interface dan profil aktif
    iface="$(ip -o route get 1.1.1.1 2>/dev/null |
        awk '{for (i=1; i<=NF; i++) if ($i=="dev") {
            print $(i+1); exit
        }}')"

    if [[ -z "$iface" ]]; then
        echo "[GAGAL] Interface jaringan aktif tidak ditemukan."
        return 1
    fi

    conn="$(nmcli -g GENERAL.CONNECTION device show "$iface" 2>/dev/null)"

    if [[ -z "$conn" || "$conn" == "--" ]]; then
        echo "[GAGAL] Profil NetworkManager tidak ditemukan."
        return 1
    fi

    echo "[INFO] Interface : $iface"
    echo "[INFO] Profil    : $conn"

    # Jangan mengubah DNS jika VPN aktif
    if nmcli -t -f TYPE,STATE connection show --active 2>/dev/null |
        grep -qi 'vpn:activated'; then
        echo "[DIBATALKAN] VPN aktif. DNS tidak diubah."
        return 1
    fi

    # 3. Simpan konfigurasi DNS profil saat ini
    old_dns="$(nmcli -g ipv4.dns connection show "$conn" 2>/dev/null)"
    old_ignore="$(nmcli -g ipv4.ignore-auto-dns connection show "$conn" 2>/dev/null)"

    backup_dir="$HOME/.cache/diagnostics-troubleshooting"
    mkdir -p "$backup_dir" || return 1
    chmod 700 "$backup_dir"

    backup_file="$backup_dir/dns-backup-$(date +%Y%m%d-%H%M%S).txt"

    {
        printf 'CONNECTION=%q\n' "$conn"
        printf 'IPV4_DNS=%q\n' "$old_dns"
        printf 'IPV4_IGNORE_AUTO_DNS=%q\n' "$old_ignore"
    } > "$backup_file" || {
        echo "[GAGAL] Tidak bisa menyimpan backup DNS."
        return 1
    }

    chmod 600 "$backup_file"

    echo "[INFO] Backup profil DNS: $backup_file"

    # 4. Pastikan systemd-resolved tersedia
    if ! systemctl list-unit-files systemd-resolved.service \
        --no-legend 2>/dev/null | grep -q systemd-resolved; then
        echo "[GAGAL] Layanan systemd-resolved tidak tersedia."
        return 1
    fi

    if ! sudo systemctl enable --now systemd-resolved; then
        echo "[GAGAL] systemd-resolved gagal diaktifkan."
        return 1
    fi

    # Pastikan layanan benar-benar aktif sebelum mengubah symlink
    if ! systemctl is-active --quiet systemd-resolved; then
        echo "[GAGAL] systemd-resolved belum aktif."
        return 1
    fi

    if [[ ! -e "$resolv_target" ]]; then
        echo "[GAGAL] Target resolver tidak ditemukan: $resolv_target"
        return 1
    fi

    # 5. Backup /etc/resolv.conf sebelum mengganti file atau symlink
    if [[ "$(readlink -f /etc/resolv.conf 2>/dev/null)" != \
          "$(readlink -f "$resolv_target" 2>/dev/null)" ]]; then

        resolv_backup="/etc/resolv.conf.backup.$(date +%Y%m%d-%H%M%S)"

        if ! sudo cp -a --no-clobber /etc/resolv.conf "$resolv_backup"; then
            echo "[GAGAL] Backup /etc/resolv.conf gagal."
            echo "[INFO] File asli tidak sengaja ditimpa."
            return 1
        fi

        echo "[INFO] Backup resolv.conf: $resolv_backup"

        if ! sudo ln -sfn "$resolv_target" /etc/resolv.conf; then
            echo "[GAGAL] Symlink resolv.conf gagal dibuat."
            return 1
        fi
    else
        echo "[INFO] Symlink resolv.conf sudah benar."
    fi

    # 6. Atur DNS alternatif pada profil NetworkManager
    echo "[INFO] Mengatur DNS alternatif..."

    if ! sudo nmcli connection modify "$conn" \
        ipv4.dns "1.1.1.1 8.8.8.8" \
        ipv4.ignore-auto-dns yes; then
        echo "[GAGAL] Konfigurasi DNS profil gagal diubah."
        return 1
    fi

    # 7. Aktifkan ulang profil agar konfigurasi diterapkan
    if ! sudo nmcli connection up "$conn"; then
        echo "[GAGAL] Profil gagal diaktifkan kembali."
        echo "[INFO] Backup profil: $backup_file"
        return 1
    fi

    sleep 2

    # 8. Periksa hasil perbaikan
    echo "[INFO] DNS yang aktif:"
    resolvectl status "$iface" 2>/dev/null

    if getent ahosts example.com >/dev/null 2>&1; then
        echo "[BERHASIL] DNS berfungsi dan example.com berhasil di-resolve."
        return 0
    fi

    echo "[BELUM BERHASIL] DNS masih gagal me-resolve domain."
    echo "[INFO] Backup profil tersimpan di: $backup_file"
    echo "[INFO] Periksa koneksi, VPN, dan status resolver."
    return 1
}




echo "|@$=============================================================================================================================================================================================$@|"
echo "|=============================================================================={ DIAGNOSTICS TROUBLESHOOTING }==================================================================================|"
echo "|@$=============================================================================================================================================================================================$@|"

echo " "
echo " "

read -r -p $'Pilih masalah yang ingin diperiksa:\n1. DNS Bermasalah\n2. Gateway Tidak Terjangkau\n3. IP Address Bermasalah\nPilihan: ' jawaban
echo " "

case "$jawaban" in
   1)
	 echo "=============================================================================================================================================="
	 echo "========================================================= PANDUAN DNS PROBLEM ================================================================"
	 echo "=============================================================================================================================================="
	 echo " "
	 echo "Jenis Problem DNS"
	 echo " "
	 echo "1. DNS Resolution Failure"
	 echo " "
	 echo "Solusi: DNS Resolution Repair"
	 echo " "
	 echo "   @ Penyebab:"
	 echo "   	- Domain gagal diterjemahkan menjadi alamat IP."
	 echo "   	- Konfigurasi DNS tidak sesuai."
	 echo " "
	 echo "   @ Kelebihan:"
	 echo "   	- Membantu memulihkan resolusi domain."
	 echo "   	- Konfigurasi dikelola melalui NetworkManager."
	 echo " "
	 echo "   @ Kelemahan:"
	 echo "   	- Tidak memperbaiki koneksi internet yang terputus."
 	 echo
	 echo "2. DNS Server Tidak Merespons"
	 echo 
	 echo "Solusi: DNS Server Connectivity Check"
	 echo 
	 echo "   @ Penyebab:"
	 echo "   	- DNS server tidak merespons."
	 echo "   	- Jaringan memblokir permintaan DNS."
	 echo
	 echo "   @ Kelebihan:"
	 echo "   	- Membantu membedakan masalah DNS dan konektivitas."
	 echo
	 echo "   @ Kelemahan:"
	 echo "   	- DNS publik mungkin diblokir oleh jaringan."
	 echo
	 echo "3. Incorrect DNS Configuration"
	 echo 
	 echo "Solusi: NetworkManager DNS Configuration Repair"
	 echo 
	 echo "   @ Penyebab:"
	 echo "   	- Alamat DNS salah."
	 echo "   	- Konfigurasi DNS tidak sesuai kebutuhan."
	 echo
	 echo "   @ Kelebihan:"
	 echo "   	- Pengaturan DNS disimpan pada profil koneksi."
	 echo
	 echo "   @ Kelemahan:"
	 echo "   	- DNS publik dapat mengganggu domain internal."
	 echo
	 echo "4. DNS Cache Bermasalah"
	 echo 
	 echo "Solusi: DNS Cache Flushing"
	 echo 
	 echo "   @ Penyebab:"
	 echo "   	- Cache menyimpan hasil resolusi lama."
	 echo "   	- Hasil DNS belum diperbarui."
	 echo
	 echo "   @ Kelebihan:"
	 echo "   	- Membersihkan cache tanpa harus mengganti DNS."
	 echo
	 echo "   @ Kelemahan:"
	 echo "   	- Tidak semua sistem menggunakan systemd-resolved."
	 echo
	 echo "5. DNS Resolution Lambat"
	 echo 
	 echo "Solusi: DNS Response Time Testing"
	 echo 
	 echo "   @ Penyebab:"
	 echo "   	- DNS server merespons dengan lambat."
	 echo "   	- Koneksi jaringan tidak stabil."
	 echo
	 echo "   @ Kelebihan:"
	 echo "   	- Membantu mengukur waktu respons DNS."
	 echo
	 echo "   @ Kelemahan:"
	 echo "   	- Hasil pengujian dipengaruhi kondisi jaringan."
 	 echo


         echo "================================================================================================================================================"
         echo "						Panduan DNS Problem selesai ditampilkan."
         echo "================================================================================================================================================"
	 echo " "
	 echo " "

	 echo "===================================================================================="
 	 echo "=============================== CHOOSE DNS PROBLEM ================================="
	 echo "===================================================================================="
	 echo
	 echo "1. Domain tidak bisa diakses"
	 echo "2. DNS server tidak merespons"
	 echo "3. Konfigurasi DNS bermasalah"
	 echo "4. DNS cache bermasalah"
	 echo "5. Resolusi DNS lambat"
	 echo
	 read -r -p "Pilihan: " gejala_dns
	 echo
	 date '+%d-%m-%Y %H:%M:%S %Z'
	 echo "===================================================================================="


   	 case "$gejala_dns" in
            "1")
        	echo
        	echo "SOLUSI 1: DNS Resolution Repair"

        	if check_dns; then
            		echo "[BERHASIL] Resolusi domain sudah berfungsi."
        	elif check_internet_ip; then
            		echo "[INFO] Internet melalui IP tersedia, tetapi DNS gagal."

            		if command -v dig >/dev/null 2>&1 && { dig @1.1.1.1 example.com A +time=3 +tries=1 | grep -q 'status: NOERROR' || dig @8.8.8.8 example.com A +time=3 +tries=1 | grep -q 'status: NOERROR'; }; then
                            	repair_dns_with_nm
            		else
                		echo "[GAGAL] Resolver pembanding tidak merespons dengan baik."
            		fi
        	else
            		echo "[GAGAL] Koneksi IP juga bermasalah."
            		repair_gateway
        	fi
        	;;

    	    "2")
        	echo
        	echo "SOLUSI 2: DNS Server Connectivity Check"

        	if ! command -v dig >/dev/null 2>&1; then
            		echo "[INFO] Perintah dig tidak tersedia."
            		if ! check_dns; then
                		repair_dns_with_nm
            		else
                		echo "[BERHASIL] DNS sistem berfungsi."
            		fi
        	else
            		echo "--- Pengujian Cloudflare ---"
            		dig @1.1.1.1 example.com A +time=3 +tries=1

            		echo
            		echo "--- Pengujian Google ---"
            		dig @8.8.8.8 example.com A +time=3 +tries=1

            		if check_dns; then
                		echo "[BERHASIL] DNS sistem dapat me-resolve domain."
            		elif dig @1.1.1.1 example.com A +time=3 +tries=1 | grep -q 'status: NOERROR' || dig @8.8.8.8 example.com A +time=3 +tries=1 | grep -q 'status: NOERROR'; then
                		echo "[INFO] Resolver publik merespons; mencoba memperbaiki DNS."
                		repair_dns_with_nm
            		else
                		echo "[GAGAL] Kedua resolver pembanding belum memberikan jawaban NOERROR."
            		fi
        	fi
        	;;

 	    "3")
        	echo
        	echo "SOLUSI 3: NetworkManager DNS Configuration Repair"

        	if check_dns; then
            		echo "[INFO] DNS saat ini berfungsi; tidak ada perubahan."
        	elif check_internet_ip; then
            		repair_dns_with_nm
        	else
            		echo "[INFO] Koneksi IP gagal; memeriksa gateway."
            		repair_gateway
        	fi
        	;;

    	    "4")
        	echo
        	echo "SOLUSI 4: DNS Cache Flushing"

        	if flush_dns_cache; then
            		echo "[INFO] Cache DNS berhasil dibersihkan."
        	else
            		echo "[INFO] Cache tidak dibersihkan atau resolver tidak mendukungnya."
        	fi

        	if check_dns; then
            		echo "[BERHASIL] Resolusi DNS sekarang berfungsi."
        	else
            		echo "[INFO] DNS masih gagal setelah pemeriksaan cache."
            		if check_internet_ip; then
                		repair_dns_with_nm
            		else
                		echo "[INFO] Periksa konektivitas IP dan gateway terlebih dahulu."
                		repair_gateway
            		fi
        	fi
        	;;

    	    "5")
        	echo
        	echo "SOLUSI 5: DNS Response Time Testing"

        	if command -v dig >/dev/null 2>&1; then
            		echo "--- DNS Cloudflare ---"
            		dig @1.1.1.1 example.com A +stats +time=3 +tries=1

            		echo
            		echo "--- DNS Google ---"
            		dig @8.8.8.8 example.com A +stats +time=3 +tries=1

            		if ! check_dns && check_internet_ip; then
                		echo "[INFO] DNS sistem gagal, meskipun koneksi IP tersedia."
                		repair_dns_with_nm
            		elif check_dns; then
                		echo "[INFO] DNS sistem berfungsi. Bandingkan nilai Query time."
            		else
                		echo "[GAGAL] DNS dan konektivitas IP belum berfungsi."
                		repair_gateway
            		fi
        	else
            		echo "[INFO] Perintah dig tidak tersedia untuk mengukur waktu respons."
            			if ! check_dns && check_internet_ip; then
                			repair_dns_with_nm
            			elif check_dns; then
                			echo "[BERHASIL] DNS sistem berfungsi."
            			else
                			repair_gateway
            			fi
        	fi
        	;;

    	     *)
        	echo "[GAGAL] Pilihan gejala DNS tidak valid."
        	;;
	esac
	;;


    "2")
        echo "Jalur pemeriksaan Gateway akan dijalankan."
        ;;

    "3")
        echo "Jalur pemeriksaan IP Address akan dijalankan."
        ;;

    *)
        echo "Pilihan tidak valid."
        ;;
esac

