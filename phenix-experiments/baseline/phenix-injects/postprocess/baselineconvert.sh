#!/bin/bash

# Loop through each baseline directory
for baseline_dir in baseline_shoulder baseline_summer baseline_winter; do
    echo "[*] Entering $baseline_dir"

    cd "$baseline_dir" || continue

    # Find all .pcap or .pcapng files
    for pcap in *.pcap *.pcapng; do
        [ -e "$pcap" ] || continue  # Skip if no files found
        echo "  [→] Processing $pcap"

        # Run Zeek with BACnet analyzer, suppress warnings
        zeek -C -w -r "$pcap" icsnpp/bacnet

        # Convert all .log files to .csv (overwrite behavior)
        for log_file in *.log; do
            csv_file="${log_file%.log}.csv"
            echo "    [✓] Converting $log_file → $csv_file"
            cat "$log_file" | sed 's/\t/,/g' > "$csv_file"
        done
    done

    cd ..
done

echo "[✓] All baselines processed."