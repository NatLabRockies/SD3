import requests
import json
import yaml
import argparse

url = "http://127.0.0.1/battery"

def parse_topology(topology_filepath, domain_name='sunshine.lab'):
  with open(topology_filepath) as stream:        
    try:
      data = stream.read().replace('{{BRANCH_NAME}}', 'main')
      data = yaml.safe_load(data)
    except yaml.YAMLError as e:
      raise yaml.YAMLError(f"Unable to open topology file {topology_filepath}. Error message {e}")
  ems_loads = {}
  for node in data["spec"]["nodes"]:
    hostname = node["general"]["hostname"]
    #   if "ems-197295_1" in hostname:  # Debug single device 
    if "ems" in hostname:
        hostname = hostname.strip("ems-")
        dns_name = hostname + "." + domain_name
        ems_loads[hostname] = dns_name
  return ems_loads

parser = argparse.ArgumentParser(description='Register Batteries')
parser.add_argument('topology_filepath', type=str, help='The path and filename to the topology.yml file')
parser.add_argument('--domain_name', type=str, default='', help='Domain name that gets appended to the hostname for ems batteries')

args = parser.parse_args()

batteries = parse_topology(args.topology_filepath)

headers = {
  'Content-Type': 'application/json'
}

for load_id, ems_ip in batteries.items():
  full_ems_ip = ems_ip + args.domain_name if args.domain_name else ems_ip

  print(f"Registering battery {load_id} with ip {full_ems_ip}")

  payload = json.dumps({
    "name": "Tesla",
    "battery_id": "75f979e0-5b2b-11ef-bd01-3d969afd56ae",
    "description": "Tesla Power Wall 12kw",
    "ems_ipaddress": full_ems_ip,
    "service_area_id": "123456", 
    "ems_load_id": load_id,
    "ems_port": 9001, #TLS uses 9001. non-tls 9101
    "use_tls": True, 
    "verify_ssl": False
  })

  response = requests.request("POST", url, headers=headers, data=payload)

  if response.status_code == 200 or response.status_code == 201: 
    print(f"Succesfully registering battery {load_id} with ip {full_ems_ip}")
  else: 
    print(f"Failed registering battery {load_id} with ip {full_ems_ip}")
    print(response.text)
