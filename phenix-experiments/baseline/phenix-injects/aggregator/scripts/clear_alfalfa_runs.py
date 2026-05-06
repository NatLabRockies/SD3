import requests
import json
from datetime import datetime
from datetime import timedelta
import time as t
from alfalfa_client.alfalfa_client import AlfalfaClient
from alfalfa_client.lib import AlfalfaAPIException, AlfalfaClientException

alfalfa_url = "http://10.10.100.31"

def get_run_ids():
    print(f"Getting runs from API {alfalfa_url}")

    runs = requests.get(f"{alfalfa_url}/api/v2/runs").json()

    runs_ids = []
    if runs['payload']:
        for run in  runs['payload']:
              print(f"Adding id {run['id']}")
              runs_ids.append(run['id'])

    return runs_ids


print("Getting runs from API {alfalfa_url}")
run_ids = get_run_ids()

print("Stopping runs from API {alfalfa_url}")
alfalfa = AlfalfaClient(host=alfalfa_url)

alfalfa.stop(run_ids, wait_for_status=True)

print("Delete runs from API {alfalfa_url}")

for run_id in run_ids:

     status = requests.delete(f"{alfalfa_url}/api/v2/runs/{run_id}")
     print(status)