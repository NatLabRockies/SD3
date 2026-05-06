from enum import Enum
import random
import requests


class BatteryEMS():
    """A client to call Battery EMS OT-Sim device."""

    ems_port = 9101
    ems_ip  = "127.0.0.1"

    ems_port = 9101
    def __init__(self, battery_id: str, load_id: str, ems_url="127.0.0.1", ems_port=9101):

        self.battery_id = battery_id
        self.load_id = load_id
        self.ems_url = f"http://{ems_url}:{ems_port}"
        
        
    def state_of_charge(self) -> bool:

        return self._request_to_ems(f"{self.load_id}.stateOfChargeStatus")

    def active_power(self) -> float:

        return self._request_to_ems(f"{self.load_id}.activePowerStatusBattery")

    def reactive_power(self) -> float:

        return self._request_to_ems(f"{self.load_id}.reactivePowerStatusBattery")

    def current(self) -> float:

        return self._request_to_ems(f"{self.load_id}.batteryCurrent")  

    def voltage(self) -> float:

        return self._request_to_ems(f"{self.load_id}.batteryVoltage")    
    
    def charge_discharge_rate(self) -> float:

        return self._request_to_ems(f"{self.load_id}.setChargeDischargeRate")    

    def set_state_of_charge(self, value) -> bool:

        return self._post_to_ems(f"{self.load_id}.stateOfChargeStatus", value )
    
    def set_charge_discharge_rate(self, value) -> bool:

        return self._post_to_ems(f"{self.load_id}.setChargeDischargeRate", value )
    
    def set_active_power(self, value) -> bool:

        return self._post_to_ems(f"{self.load_id}.activePowerStatusBattery", value )

    def set_reactive_power(self, value) -> bool:

        return self._post_to_ems(f"{self.load_id}.reactivePowerStatusBattery", value )

    def set_current(self, value) -> bool:

        return self._post_to_ems(f"{self.load_id}.batteryCurrent", value ) 

    def set_voltage(self, value) -> bool:

        return self._post_to_ems(f"{self.load_id}.batteryVoltage", value ) 
    
    def _request_to_ems(self, tag_name):
         
        url_endpoint = f"{self.ems_url}/api/v1/query/{tag_name}"
        result = requests.get(url_endpoint)

        if result:
            return result
        else: 
            raise requests.exceptions.HTTPError(f"Error shecking {url_endpoint} Status Code: {result.status_code}") 

    def _post_to_ems(self, tag_name, value) -> bool:
         
        url_endpoint = f"{self.ems_url}/api/v1/write/{tag_name}/{value}"
        result = requests.post(url_endpoint)
    
        if result:
            return True 
        else: 
            raise requests.exceptions.HTTPError(f"Error shecking {url_endpoint} Status Code: {result.status_code}") 
    

    #NOT NEEDED. MOVE TO BUILDING FEDERATE
    def register_battery_with_aggregator(self):

        aggregator_url = 'http://127.0.0.1:5000/battery'
        battery = {
            "name": "Tesla",
            "batteryid": "",
            "description": "Tesla Power Wall"
        }

        result = requests.post(aggregator_url, json = battery)
        requests.codes

        data = result.json()
        if '_id' in data: 
            print(data['_id'])
   
        if result.status_code == requests.codes.ok or result.status_code == requests.codes.created:
            data = result.json()
            if '_id' in data: 
                return data['_id']
            else:
                raise requests.exceptions.HTTPError("Register Battery Failed") 
        else: 
            raise requests.exceptions.HTTPError("Register Battery Failed") 
        