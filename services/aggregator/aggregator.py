import os
from flask import Flask, jsonify, request
from flask_pymongo import PyMongo
from battery import BatteryEMS
from dotenv import load_dotenv

app = Flask(__name__)

API_NAME    = "Aggregator"
API_VERSION = "0.1.0"

load_dotenv() 

MONGO_USERNAME = os.environ['MONGO_USERNAME']
MONGO_PASSWORD = os.environ['MONGO_PASSWORD'] 
MONGO_DATABASE = os.environ['MONGO_DATABASE']
MONGO_HOSTNAME = os.environ['MONGO_HOSTNAME']
MONGO_PORT     = os.environ['MONGO_PORT']

# MongoDB config
app.config["MONGO_URI"] = f"mongodb://{MONGO_USERNAME}:{MONGO_PASSWORD}@{MONGO_HOSTNAME}:{MONGO_PORT}/{MONGO_DATABASE}?authSource=admin"
mongo = PyMongo(app)

print(app.config)

# Check connection
print(mongo.db.client.server_info())

# collections
batteries_db = mongo.db.batteries
service_areas_db = mongo.db.service_areas_db

# Return all batterry info
@app.route('/batteries', methods=['GET'])
def get_all_batteries():
    batteries = batteries_db.find()
    result = []
    for battery in batteries:
        result.append({
            '_id': str(battery['_id']), 
            'battery_id': battery['battery_id'], 
            'ems_ipaddress': battery['ems_ipaddress'], 
            'ems_load_id': battery['ems_load_id'],
            'name': battery['name'], 
            'description': battery['description'], 
            'service_area_id': battery['service_area_id']
        })
        
    return jsonify(result)

# Return battery info by id
@app.route('/battery/<id>', methods=['GET'])
def get_battery(id):
    battery = batteries_db.find_one({'battery_id': id})
    if battery:
        result = {
            '_id': str(battery['_id']), 
            'battery_id': battery['battery_id'], 
            'ems_ipaddress': battery['ems_ipaddress'], 
            'ems_load_id': battery['ems_load_id'],
            'name': battery['name'], 
            'description': battery['description'], 
            'service_area_id': battery['service_area_id']
        }
        return jsonify(result)
    else:
        return jsonify({"error": "battery not found"}), 404
    
# Add a new battery to DB
@app.route('/battery', methods=['POST'])
def add_battery():
    data = request.get_json()
    attributes = ['name', 'description', 'battery_id', 'service_area_id']
    if 'name' in data and 'description' in data and 'battery_id' in data and 'service_area_id' in data:
        battery_id = batteries_db.insert_one({
            'name': data['name'], 
            'battery_id': data['battery_id'], 
            'ems_ipaddress': data['ems_ipaddress'], 
            'ems_load_id': data['ems_load_id'],
            'description': data['description'],
            'service_area_id': data['service_area_id'],
        }).inserted_id

        new_battery = batteries_db.find_one({'battery_id': data['battery_id']})

        result = {
            '_id': str(new_battery['_id']), 
            'battery_id': new_battery['battery_id'],
            'ems_ipaddress': new_battery['ems_ipaddress'], 
            'ems_load_id': new_battery['ems_load_id'],
            'name': new_battery['name'], 
            'description': new_battery['description'],
            'service_area_id': new_battery['service_area_id']
        }
        return jsonify(result), 201
    else:
        return jsonify({"error": "Missing data"}), 400

# Update a battery in the DB. 
@app.route('/battery/<id>', methods=['PUT'])
def update_battery(id):
    data = request.get_json()
    updated_battery = batteries_db.find_one_and_update(
        {'battery_id': id},
        {'$set': data},
        return_document=True
    )
    if updated_battery:
        result = {
            '_id': str(updated_battery['_id']), 
            'battery_id': updated_battery['battery_id'],
            'ems_ipaddress': updated_battery['ems_ipaddress'], 
            'ems_load_id': updated_battery['ems_load_id'],
            'name': updated_battery['name'], 
            'description': updated_battery['description'],
            'service_area_id': updated_battery['service_area_id']
        }
        return jsonify(result)
    else:
        return jsonify({"error": "battery not found"}), 404

# Delete a battery in the DB
@app.route('/battery/<id>', methods=['DELETE'])
def delete_battery(id):
    result = batteries_db.delete_one({'battery_id': id})
    if result.deleted_count == 1:
        return jsonify({"message": "battery deleted successfully"}), 200
    else:
        return jsonify({"error": "battery not found"}), 404


# The EMS/BMS modbus only supports integers so send value from -100 to 100 to represent %
@app.route('/<ServiceAreaID>/Charge', methods=['POST'])
def charge_service_area(ServiceAreaID):
    batteries = batteries_db.find({'service_area_id': ServiceAreaID})
    results = []
    for battery in batteries:
        battery_ems = BatteryEMS(battery['battery_id'], battery['ems_load_id'], battery['ems_ipaddress']  )
        if battery_ems.set_charge_discharge_rate(100):
            result = {
            'battery_id': battery['battery_id'],
            'charge_sucess': 'True'
            }
        else: 
            result = {
            'battery_id': battery['battery_id'],
            'charge_sucess': 'False'
            }
        results.append(result)
    return jsonify(results)
        

@app.route('/<ServiceAreaID>/Discharge', methods=['POST'])
def discharge_service_area(ServiceAreaID):
    batteries = batteries_db.find({'service_area_id': ServiceAreaID})
    results = []
    for battery in batteries:
        battery_ems =  BatteryEMS(battery['battery_id'], battery['ems_load_id'], battery['ems_ipaddress']  )
        if battery_ems.set_charge_discharge_rate(-90):
            result = {
            'battery_id': battery['battery_id'],
            'discharge_sucess': 'True'
            }
        else: 
            result = {
            'battery_id': battery['battery_id'],
            'discharge_sucess': 'False'
            }
        results.append(result)
    return jsonify(results)

@app.route('/<ServiceAreaID>/Idle', methods=['POST'])
def idle_service_area(ServiceAreaID):
    batteries = batteries_db.find({'service_area_id': ServiceAreaID})
    results = []
    for battery in batteries:
        battery_ems =  BatteryEMS(battery['battery_id'], battery['ems_load_id'], battery['ems_ipaddress']  )
        if battery_ems.set_charge_discharge_rate(0):
            result = {
            'battery_id': battery['battery_id'],
            'discharge_sucess': 'True'
            }
        else: 
            result = {
            'battery_id': battery['battery_id'],
            'discharge_sucess': 'False'
            }
        results.append(result)
    return jsonify(results)


@app.route("/", methods=['GET'])
def index():
    return f"{API_NAME} Version {API_VERSION}"

@app.route("/version", methods=['GET'])
def version():
    return f"{API_NAME} Version {API_VERSION}"

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=80)



