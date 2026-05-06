#!/bin/bash 

####Startup the mirror0 interface and strip gre packets for analysis
systemctl start mirror

####Startup the mirror0 capture pcap in root
systemctl start capture

####add the route to the attacker
ip route add 40.0.0.0/8 via 172.16.0.90 dev eth0