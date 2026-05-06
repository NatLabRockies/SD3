#!/bin/bash 

sleep 60
echo "Running 98-run.sh for aggregator flask app" >> /var/log/98-run.log  2>&1
cd /usr/src/app
. .venv/bin/activate
python3 aggregator.py > /var/log/aggregator.log 2>&1 &
echo "Finished 98-run.sh for aggregator flask app" >> /var/log/98-run.log  2>&1



