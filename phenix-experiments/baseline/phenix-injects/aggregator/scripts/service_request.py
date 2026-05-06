import requests
import json
from datetime import datetime
import logging
from config import AGGREGATOR_URL, CSV_FILE

logger = logging.getLogger(__name__)

def make_service_request(action, battery_name="Tesla", battery_description="Tesla Power Wall"):
    """
    Make a service request to the aggregator for the specified action.
    
    Args:
        action (str): The action to perform (Charge, Discharge, or Idle)
        battery_name (str): Name of the battery
        battery_description (str): Description of the battery
    
    Returns:
        dict: Response JSON if successful, None if failed
    """
    current_time = datetime.now().isoformat()
    
    # Determine URL based on action
    if action.lower() == "charge":
        url = f"{AGGREGATOR_URL}/123456/Charge"
    elif action.lower() == "discharge":
        url = f"{AGGREGATOR_URL}/123456/Discharge"
    elif action.lower() == "idle":
        url = f"{AGGREGATOR_URL}/123456/Idle"
    else:
        logger.error(f"Invalid action: {action}")
        return None
    
    payload = json.dumps({
        "name": battery_name,
        "description": battery_description
    })
    headers = {
        'Content-Type': 'application/json'
    }
    
    try:
        response = requests.request("POST", url, headers=headers, data=payload)
        
        if response.status_code == 200:
            # Loop through the response json and log each key-value pair to CSV
            response_json = response.json()
            logger.info(f"Response JSON: {response_json}")
            for id in response_json:
                logger.info(f"Response JSON: {id}")
                CSV_FILE.write(f"{current_time},{id['battery_id']},{action}\n".encode())
            logger.info(f"Successfully executed {action} action")
            return response_json
        else:
            logger.error(f"Status Code: {response.status_code}")
            logger.error(f"Response Text: {response.text}")
            return None
            
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed for {action}: {e}")
        return None
    

