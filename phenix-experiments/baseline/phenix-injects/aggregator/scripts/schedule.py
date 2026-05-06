import requests
import json
import argparse
from datetime import datetime
from datetime import timedelta
import time as t
from config import AGGREGATOR_URL, ALFALFA_URL
from service_request import make_service_request

import logging
logger = logging.getLogger(__name__)

DATE_FORMAT = "%Y-%m-%d %H:%M:%S"

# Schedule for charging
# The current battery model has a capacity of 1400kw. 
# The charge is rate is around 5.2kw / hour. 
# The battery is initilized with 5km. 
# We need at least 2 hours to charge the battery fully. 

short_schedule = {
        datetime.strptime("2018-06-24 13:00:00", DATE_FORMAT): "Charge",
        datetime.strptime("2018-06-24 13:05:00", DATE_FORMAT): "Discharge",
        datetime.strptime("2018-06-24 13:10:00", DATE_FORMAT): "Idle",
        datetime.strptime("2018-06-24 13:12:00", DATE_FORMAT): "Discharge",
        datetime.strptime("2018-06-24 13:15:00", DATE_FORMAT): "Charge",
        datetime.strptime("2018-06-24 13:20:00", DATE_FORMAT): "Discharge",
        datetime.strptime("2018-06-24 13:25:00", DATE_FORMAT): "Idle",

}

baseline_schedule = {
    datetime.strptime("2018-06-24 14:00:00", DATE_FORMAT): "Discharge",
    datetime.strptime("2018-06-24 16:00:00", DATE_FORMAT): "Idle",
}

attack_schedule = {
    datetime.strptime("2018-06-24 14:30:00", DATE_FORMAT): "Charge",
    datetime.strptime("2018-06-24 15:45:00", DATE_FORMAT): "Idle",
}

parser = argparse.ArgumentParser()
parser.add_argument(
    "--schedule",
    help="Schedule type, either default or attack"
)
schedule = {}

args = parser.parse_args()
print(args)
if args.schedule == "baseline": 
    schedule = baseline_schedule
elif args.schedule == "attack":
    schedule = attack_schedule
elif args.schedule == "short": 
    schedule = short_schedule

NUM_OF_CHECKS = 10 
check_attempt = 0
while True: 
    logger.info(f"Getting runs from API {ALFALFA_URL}")
    runs = requests.get(ALFALFA_URL).json()

    run_datetimes = []
    date_objs = []
    timedeltas = []
    
    if runs['payload']:
        for run in  runs['payload']:
            if run['status'] == "RUNNING":
                logger.info(f"Model id {run['id']} is Running. Model time is curretly {run['datetime']}")
                run_datetimes.append(run['datetime'])
            
    if not run_datetimes:
        check_attempt += 1
        if check_attempt <= NUM_OF_CHECKS:
            logger.info(f"No models are currently running. Attempt {check_attempt}/{NUM_OF_CHECKS}")
            t.sleep(30)
            continue
        else:
            logger.info(f"No models are currently running. Final Attempt {check_attempt}/{NUM_OF_CHECKS}. Exiting program") 
            raise Exception
             
          
    date_objs = [datetime.strptime(d, DATE_FORMAT) for d in run_datetimes]

    timedeltas = [date_objs[i].timestamp() - date_objs[i-1].timestamp() for i in range(1, len(date_objs))]

    times = 0
    for time in timedeltas: 
        times += time

    # Allow for small time difference in models. Should be zero
    if abs(times) <= 300: 
        simulation_time = date_objs[0]
    else: 
        logger.error(f"Simulation times {times} differ between model runs. Check running models")
        raise Exception

    if simulation_time in schedule.keys(): 
        if schedule[simulation_time] == "Charge": 
            logger.info(f"The time is now {simulation_time}. Sending Charge request")
            make_service_request("Charge")
        elif schedule[simulation_time] == "Discharge": 
            logger.info(f"The time is now {simulation_time}. Sending Discharge request")
            make_service_request("Discharge")
        elif schedule[simulation_time] == "Idle": 
            logger.info(f"The time is now {simulation_time}. Sending Idle request")
            make_service_request("Idle")
    else:
        logger.info(f"Current simulation time {simulation_time} has no event scheduled")

    t.sleep(2)


    



