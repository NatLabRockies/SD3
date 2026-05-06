#!/bin/bash
# Example: add 5% packet loss and 200ms delay to all traffic on eth0

###Purple team Scorch
tc qdisc add dev eth0 root netem delay 200ms loss 99%
####Scorch Run 1
tc qdisc add dev eth0 root netem delay 200ms loss 5%
####Scorch Run 2
tc qdisc add dev eth0 root netem delay 100ms 20ms distribution normal
####Scorch Run 3
tc qdisc del dev eth0 root

