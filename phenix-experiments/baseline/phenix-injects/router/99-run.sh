#!/bin/bash 
#######Enable auditor for syslogs
systemctl enable --now auditd

#######watch dnsmasqchanges
auditctl -w /etc/dnsmasq.conf -p wa -k dnsmasq_conf


#######Enable auditor for syslogs
systemctl enable --now auditd

#######watch dnsmasqchanges
auditctl -w /etc/dnsmasq.conf -p wa -k dnsmasq_conf


####Startup the mirror0 interface and strip gre packets for analysis
systemctl start mirror

####Startup the mirror0 capture pcap in root
systemctl start capture

####Start Zeek analysis to be sent to grafana
/usr/local/zeek/bin/zeekctl deploy