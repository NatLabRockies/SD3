#!/bin/bash 

sleep 10
echo "Running clear_alfalfa.sh" >> /var/log/clear_alfalfa.log  2>&1
cd /usr/src/app
. .venv/bin/activate
pip3 install alfalfa_client
python3 clear_alfalfa_runs.py > /var/log/clear_alfalfa.log 2>&1 &
echo "Finished clear_alfalfa.sh for aggregator flask app" >> /var/log/clear_alfalfa.log  2>&1



