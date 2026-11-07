# input File yng akan diinput untuk di arsip
read -p "Masukkan Pilihan Nomor Angka: 1. Mengarsip Folder/File | 2. Melihat Isi File | 3. Keluarkan File/Folder dari arsip: " pilihan

case "$pilihan" in

# Mengarsip File/Folder
 1)
   read -p "Masukkan Nama File atau Folder yang ingin diarsip: " file
   found=$(find "$HOME/Documents" -type f -name "$file" -print -quit)
   read -p "Masukkan Nama File gzip seperti document.tar.gz: " gzip

   if [ -n "$found" ]; then
    tar -czf "$gzip" "$found"
  else
    echo "File tidak ditemukan"
  fi
   

   echo "File telah berhasil diarsip, dengan nama backup-document.tar.gz";;

 2) 
   read -p "Masukkan Nama file gzip yang ingin di lihat isinya: " gzip

    tar -tzf "$gzip"

   echo "------------------------------------------------------------"
   echo "File telah terbuka";;

 3) 
   read -p "Masukkan Nama file gzip yang ingin di keluarkan semua isi filenya: " gzip

    tar -xzf "$gzip"

   echo "------------------------------------------------------------"
   echo "File telah dikeluarkan";;

 *) 
   echo "Pilihan anda tidak sesuai panduan"
    ;;
esac
