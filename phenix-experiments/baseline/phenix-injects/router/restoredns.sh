#!/bin/bash

cat /etc/dnsmasq.conf.bak > /etc/dnsmasq.conf

##restart the dns service
systemctl restart dnsmasq