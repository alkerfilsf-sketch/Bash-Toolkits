#INPUT NAMA FILE YANG INGIN DI SCAN
read -p "Masukkan nama file log: " File
echo "File sedang Dicari, Harap Tunggu..."
# PERINTAH MENCARI FILE YANG DIINPUT
found=$(find ~ -name "$File" -type f -print -quit)

# KONDISI KEPUTUSAN
if [ -n "$found" ]; then
	echo " "
	echo "File anda telah ditemukan, Proses..."
	echo " "
	echo " "
	echo "-------- Silahkan Masukkan kata yang ingin dicari (Contoh: ERROR, WARNING, dan INFO) ----------------"
       # KONDISI PENGULANGAN UNTUK INPUT SEBUAH KATA YANG INGIN DICARI SEPERTI WARNING, INFO, DAN ERROR
	i=0
	while true
	do
    		read -p "Masukkan kata: " input[$i]

    		read -p "Mau lanjut? (ya/tidak): " lanjut

    		if [ "$lanjut" = "tidak" ]; then
        		break
    		fi

    		((i++))
	done

       # VARIABEL UNTUK MENCARI KATA YANG MEMBUTUHKAN KONDISI PENGULANGAN
	for ((i=0; i<${#input[@]}; i++))
	do
    		hasil[$i]=$(grep -c "${input[$i]}" "$found")
	done

       # MENAMPILKAN NAMA KATA DAN ISINYA
	echo "==================== LOG ANALYZER ======================"
	echo "File        : ($found)"

     #KONDISI PENGULANGAN UNTUK MENAMPILKAN KATA SEBANYAK YANG DIMASUKKAN
      for ((i=0; i<${#input[@]}; i++))
      do
    	echo "${input[$i]} : (${hasil[$i]})"
      done
	echo "========================================================"
else
	echo "File anda tidak ditemukan"
fi
