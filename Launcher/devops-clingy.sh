echo " "
echo "========================================================================================================================================================================"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~===| DEVOPS OPTION |===~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "========================================================================================================================================================================"
echo " "
echo " "
echo "|=-~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-=|"
echo "|=-~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-=|"

read -r -p $'						Opsi Dashboard:\n\n	1. System Informasi		2. Process Monitor		3. Service Health\n	4. Network Diagnostics 		5. Disk Usage Analyzer		6. File Organizer\n	7. File TAR			8. Diagnosics Troubleshooting\n\n					Pilihan anda: ' pilihan
echo "Proses, Harap Tunggu.... "
echo "|=-~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-=|"
echo "|=-~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-=|"
echo " "
echo " "

case "$pilihan" in
    "1")
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~=== SYSTEM INFORMASI ===~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo " "
        bash "$HOME/Folder-Bash-TOOLS/system-info.sh"
        ;;
    "2")
        bash "$HOME/Folder-Bash-TOOLS/process-monitor.sh"
        ;;
    "3")
        bash "$HOME/Folder-Bash-TOOLS/service-monitor.sh" 2>&1 | tee "$HOME/Folder-Bash-TOOLS/service-monitor-output.txt"
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
                # LOG ANALYZER
                i=0
                while true
                 do
                        read -p "Silahkan beritahu apa yang ingin anda cari  (Misal, Status Utama, Sub Status, atau Nama Service): " input[$i]

                        read -p "Mau lanjut? (ya/tidak): " lanjut

                        if [ "$lanjut" = "tidak" ]; then
                        break
                        fi

                        ((i++))
                done
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 

                # VARIABEL UNTUK MENCARI KATA YANG MEMBUTUHKAN KONDISI PENGULANGAN
                for ((i=0; i<${#input[@]}; i++))
                do
                        hasil[$i]=$(grep -c "${input[$i]}" "$HOME/Folder-Bash-TOOLS/service-monitor-output.txt")
                done

                # MENAMPILKAN NAMA KATA DAN ISINYA
                echo "==================== LOG ANALYZER ======================"
                echo "NAMA OPSI        : (Service Health)"

                #KONDISI PENGULANGAN UNTUK MENAMPILKAN KATA SEBANYAK YANG DIMASUKKAN
                for ((i=0; i<${#input[@]}; i++))
                do
                        echo "${input[$i]} : (${hasil[$i]})"
                done
                echo "========================================================"
		#Menghapus file txt yangbaru dibuay
		rm "$HOME/Folder-Bash-TOOLS/service-monitor-output.txt"
        ;;
    "4")
	bash "$HOME/Folder-Bash-TOOLS/Network-diagnostics.sh"
	;;
    "5")
	bash "$HOME/Folder-Bash-TOOLS/Diusage-analyzer.sh"
	;;
    "6")
	bash "$HOME/Folder-Bash-TOOLS/file-organizer.sh"
	;;
    "7")
        bash "$HOME/Folder-Bash-TOOLS/file-tar.sh"
	;;
    "8")
	bash "$HOME/Folder-Bash-TOOLS/Diagnostics-troubleshooting.sh"
	;;
    *)
        echo "Pilihan tidak valid"
        ;;
esac
