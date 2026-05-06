#!/bin/bash 

sleep 30
echo "Running 99-run.sh for aggregator flask app" >> /var/log/99-run.log  2>&1
cd /usr/src/app
. .venv/bin/activate

python3 inject-scripts/create_battery.py configs/topology.yml >> /var/log/99-run.log  2>&1
python3 inject-scripts/schedule.py --schedule baseline >> /var/log/99-run.log  2>&1 &
echo "Finished 99-run.sh for aggregator flask app" >> /var/log/99-run.log  2>&1

# Set custom DNS server
echo "nameserver 172.0.10.5" > /etc/resolv.conf