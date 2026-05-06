echo "Running clear_alfalfa.sh" >> /var/log/clear_alfalfa.log  2>&1
cd /data-sender
/usr/bin/python3 clear_alfalfa_runs.py > /var/log/clear_alfalfa.log 2>&1 &
echo "Finished clear_alfalfa.sh" >> /var/log/clear_alfalfa.log  2>&1
