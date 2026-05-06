#!/usr/bin/env bash
set -euo pipefail
modprobe ip_gre
ip link add mirror0 type gretap local 10.248.171.254 remote 10.248.171.1 ttl 255 || true
ip link set mirror0 up
ethtool -K mirror0 gro off lro off gso off tso off