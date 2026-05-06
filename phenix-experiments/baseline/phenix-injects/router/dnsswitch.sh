#!/bin/bash
set -euo pipefail

CONF="${1:-/etc/dnsmasq.conf}"

# Backup with timestamp
cp -a "$CONF" "${CONF}.bak.$(date +%Y%m%d%H%M%S)"

# Replace only lines like: address=/anything.sunshine.lab/<IPv4>
# Keep any trailing comments/whitespace unchanged.
sed -E -i \
  's|^(address=/[^/]+\.sunshine\.lab/)[0-9]{1,3}(\.[0-9]{1,3}){3}(\s*(#.*)?)$|\1127.0.0.1\3|' \
  "$CONF"

# Optional: sanity-check config before restart
if command -v dnsmasq >/dev/null 2>&1; then
  dnsmasq --test
fi

# Restart service
if command -v systemctl >/dev/null 2>&1; then
  systemctl restart dnsmasq
else
  service dnsmasq restart
fi

echo "Replaced sunshine.lab address targets with 127.0.0.1 in $CONF"
