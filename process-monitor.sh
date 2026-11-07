
#!/usr/bin/env bash

read -r -p $'Pilih mode:\n1. Top CPU\n2. Top Memory\n3. Semua\nJawaban: ' jawaban

case "$jawaban" in
    1|"Top CPU")
        echo "---------------------------------"
        printf "%-6s | %-6s\n" "PID" "CPU"
        echo "---------------------------------"

        ps aux |
        awk 'NR>1 && $11 != "ps" {print $2, $3}' |
        sort -k2 -nr | head -n 10 |
        while read -r pid cpu
        do
            printf "%-6s | %-6s\n" "$pid" "${cpu}%"
        done

        echo "---------------------------------"
        ;;

    2|"Top Memory")
        echo "------------------------------------------"
        printf "%-6s | %-6s | %s\n" "PID" "MEM" "COMMAND"
        echo "------------------------------------------"

        ps aux |
        awk 'NR>1 && $11 != "ps" {print $2, $4, $11}' |
        sort -k2 -nr | head -n 10 |
        while read -r pid mem command
        do
            printf "%-6s | %-6s | %s\n" "$pid" "${mem}%" "$command"
        done

        echo "------------------------------------------"
        ;;

    3|Semua)
        echo "-----------------------------------------------------------------"
        printf "%-6s | %-6s | %-6s | %s\n" "PID" "CPU" "MEM" "COMMAND"
        echo "-----------------------------------------------------------------"

        ps aux |
        awk 'NR>1 && $11 != "ps" {print $2, $3, $4, $11}' |
        sort -k2 -nr | head -n 10 |
        while read -r pid cpu mem command
        do
            printf "%-6s | %-6s | %-6s | %s\n" "$pid" "${cpu}%" "${mem}%" "$command"
        done

        echo "-----------------------------------------------------------------"
        ;;

    *)
        echo "Pilihan tidak valid."
        ;;
esac
