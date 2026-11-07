# Input File yang diinginkan
read -p "Masukkan file: " file

#Mencari Lokasi File berada
found=$(find . -type f -name "$file" -print -quit)

#Logika Kondisi untuk membuat keputusan
if [ -n "$found" ]; then
    echo "File ditemukan di: $found"

   #Case sebagai Pilihan
    case "$file" in
     #Folder Document
    *.txt|*.html|*.css|*.sh|*.zip)
        echo "Mencari Folder Documents"
        find . -type d -name "Documents"

        mv "$found" Documents/;;
     #Folder Picture
    *.jpeg|*.png)
        echo "Mencari Folder Pictures"
        find . -type d -name "Pictures"

        mv "$found" Pictures/;;
     #Folder Video
    *.mp4|*.mkv)
        echo "Mencari Folder Videos"
        find . -type d -name "Videos"

        mv "$found" Videos/;;
     #Delete atau Folder Download
    *)
        read -p "Nama file anda memiliki format yang tidak diketahui, Apakah anda ingin menghapusnya atau diletakkan di folder Downloads saja? " pilihan

	#Folder Download
         case "$pilihan" in Downloads|downloads|download|Download)
         echo "Mencari Folder Downloads"
         find . -type d -name "Downloads"

         mv "$found" Downloads/
         ;;

         #Delete
       *)
         echo "File akan dihapus: $file"
         rm -- "$found"
        ;;
    esac
    ;;
esac

 else
    echo "File tidak ditemukan"
fi
