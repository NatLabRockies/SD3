#!/bin/bash

# Iterate over scenario* directories
for scenario_dir in scenario*/; do
    echo "[*] Entering $scenario_dir"

    cd "$scenario_dir" || continue

    # Find all .pcap or .pcapng files
    for pcap in *.pcap *.pcapng; do
        [ -e "$pcap" ] || continue  # Skip if no files found
        echo "  [→] Processing $pcap"

        # Run Zeek with BACnet analyzer
        zeek -C -w -r "$pcap" icsnpp/bacnet

        # Convert all .log files to .csv
        for log_file in *.log; do
            csv_file="${log_file%.log}.csv"
            echo "    [✓] Converting $log_file → $csv_file"
            cat "$log_file" | sed 's/\t/,/g' > "$csv_file"
        done
    done

    cd ..
done

echo "[✓] All scenarios processed."
