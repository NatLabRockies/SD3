# config.py
import logging
import sys

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler('/var/log/service_area_schedule.log')
    ]
)

# Configure a CSV file for outputting time series data
CSV_FILE = open("/usr/src/app/service_area_schedule.csv", "ab")

AGGREGATOR_URL = "http://127.0.0.1"

ALFALFA_URL = "http://10.10.100.31/api/v2/runs"