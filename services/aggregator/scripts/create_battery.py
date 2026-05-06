import requests
import json
import yaml
import argparse

url = "http://127.0.0.1/battery"

def parse_topology(topology_filepath):
    """Parses the topology file to find all the ems device names and IP addresses. 
    The naming of the topology file attributes need to remain the same pattern or this 
    function will need to be updated. 

    Arguments:  A phenix topology file with ems devices. e.g. below.  

    general: 
      hostname: ems-p1rlv5418_1
      vm_type: kvm
      snapshot: true
    ...
    network: 
      interfaces:
      - name: eth0
        vlan: load1_lan
    

    Returns:
        Dict of load_ids and ips addresses 
        e.g. { p1rlv5418_1: 40.1.0.3 }
    """

    with open(topology_filepath) as stream:        
        try:
            data = stream.read().replace('{{BRANCH_NAME}}', 'main')
            data = yaml.safe_load(data)
        except yaml.YAMLError as e:
            raise yaml.YAMLError(f"Unable to open topology file {topology_filepath}. Error message {e}")
    ems_loads = {}
    for node in data["spec"]["nodes"]:
        hostname = node["general"]["hostname"]
        # e.g. hostname: ems-p1rlv5418_1
        if "ems" in hostname:
            for interface in node["network"]["interfaces"]:
                # .e.g vlan: load1_lan
                if "load" in interface["vlan"]:
                    # p1rlv5418_1 vs ems-p1rlv5418_1
                    hostname = hostname.strip("ems-")
                    ems_loads[hostname] = interface["address"]
    return ems_loads


parser = argparse.ArgumentParser(description='Register Batteries')

parser.add_argument('topology_filepath', type=str,
                    help='The path and filename to the topology.yml file')

args = parser.parse_args()

batteries = parse_topology(args.topology_filepath)

#batteries = {
#    
#    "p1rlv5418_1": "40.1.0.3",
#    "p1rlv5418_2": "40.2.0.3",
#    "p1rlv5419_1": "40.3.0.3",
#    "p1rlv5419_2": "40.4.0.3",
#    "p1rlv5420":   "40.5.0.3",#
#}

headers = {
  'Content-Type': 'application/json'
}

for load_id, ems_ip in batteries.items(): 

  print(f"Registering battery {load_id} with ip {ems_ip}")

  payload = json.dumps({
    "name": "Tesla",
    "battery_id": "75f979e0-5b2b-11ef-bd01-3d969afd56ae",
    "description": "Tesla Power Wall 12kw",
    "ems_ipaddress": ems_ip,
    "service_area_id": "123456", 
    "ems_load_id": load_id

  })

  response = requests.request("POST", url, headers=headers, data=payload)

  if response.status_code == 200 or response.status_code == 201: 
      print(f"Succesfully registering battery {load_id} with ip {ems_ip}")
  else: 
      print(f"Failed registering battery {load_id} with ip {ems_ip}")
      print(response.text)
      

  

