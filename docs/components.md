# Detailed Component Specifications

## OpenDSS Power Distribution Simulator

### Overview
OpenDSS (Open Distribution System Simulator) is the core power flow simulator. It models the electrical distribution network and calculates steady-state power flow, voltage profiles, and losses in real-time.

### Host Configuration
- **VM Name**: `opendss`
- **OS**: Linux (CentOS/Ubuntu)
- **CPU**: 4 cores
- **RAM**: 8 GB
- **Network**: eth0 (experiment network), eth1 (control network)

### Installation & Startup
```bash
# Inside opendss VM
apt-get install opendss python3-opendss

# Create symlink for HELICS
ln -s /opt/helics/lib/libhelics.so.3 /usr/lib/

# Start OpenDSS agent
python3 /opt/opendss/agent.py &
```

### Model Structure

#### Circuit Definition
```
Primary Substation (138 kV → 12 kV)
  ├─ Distribution Feeder 1
  │  ├─ Zone A: Service areas 1-7
  │  └─ Zone B: Service areas 8-14
  └─ Distribution Feeder 2
     ├─ Zone C: Service areas 15-20
     └─ Zone D: Service areas 21+
```

#### Load Injection Points
- **Count**: 20+ injection points (one per service area)
- **Location**: Secondary substation buses (12 kV)
- **Aggregation**: Total Alfalfa load + Battery power

#### Battery Integration
- **Bus Connection**: Direct to distribution feeder (12 kV level)
- **Power Flow**: Modeled as controllable current injection
- **Control Signal**: Charge/discharge rate from Aggregator
- **Constraints**:
  - Max charge rate: Battery power rating
  - Max discharge rate: Battery power rating
  - Voltage support: Reactive power capability (if enabled)

### HELICS Configuration

#### Subscriptions (Receives)
```yaml
# Building loads from Alfalfa
- topic: "alfalfa/building_load"
  type: "double"
  unit: "kW"

# Battery power setpoints
- topic: "battery/setpoint"
  type: "double"  
  unit: "kW"

# Demand response signals
- topic: "control/dr_signal"
  type: "double"
  unit: "0-1 (fraction)"
```

#### Publications (Sends)
```yaml
# Nodal voltages
- name: "voltage"
  type: "complex"
  unit: "kV"

# Electricity prices
- name: "lmp"
  type: "double"
  unit: "$/MWh"

# Frequency
- name: "frequency"
  type: "double"
  unit: "Hz"
```

### Power Flow Calculations

**Iterative Sequence Each Time Step**:
1. Receive building load from Alfalfa
2. Receive battery setpoints from OT-Sim
3. Run Newton-Raphson power flow:
   - Update admittance matrix with battery injection
   - Iterate until voltage convergence
   - Calculate line flows and losses
4. Publish voltages and prices to HELICS
5. Advance time by 1 second

### Output Files
- **Circuit File**: `/phenix/injects/{experiment}/ot-sim/model.dss`
- **Loadshape File**: `/phenix/injects/{experiment}/ot-sim/loads.dss`
- **Monitors**: Voltage, current, power loss monitoring at key nodes
- **Log File**: `/var/log/power.log`

### Common Parameters

| Parameter | Value | Notes |
|-----------|-------|-------|
| Base Voltage | 12 kV | Distribution primary |
| Number of Nodes | 200+ | Detailed distribution model |
| Accuracy | 0.0001 | Voltage convergence tolerance |
| Max Iterations | 25 | Power flow convergence limit |
| Time Step | 1 second | Real-time sync |

---

## Alfalfa Building Simulation Service

### Overview
Alfalfa is a web-based platform for real-time co-simulation of building energy systems. It runs EnergyPlus simulations synchronized with external systems via HELICS.

### Architecture

```
┌─────────────────────────────────────────┐
│     Alfalfa Web Server (Python/Flask)   │
├─────────────────────────────────────────┤
│  Port 5000: RESTful API                 │
│  Port 6379: Redis (state cache)         │
│  Port 27017: MongoDB (results storage)  │
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│   EnergyPlus Simulation Engine           │
│   - One instance per building            │
│   - ~2-5x wall clock (depending on model)│
└─────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────┐
│   HELICS Interface                       │
│   - Time synchronization                │
│   - Load export                         │
│   - Signal import                       │
└─────────────────────────────────────────┘
```

### Building Models

#### Typical Model Characteristics
```
Building Type: Commercial Office/Retail
- Stories: 2-10
- Floor Area: 10,000-100,000 sq ft
- Thermal Zones: 20-50 zones
- HVAC System: Variable Air Volume (VAV)
- Lighting: Occupancy-scheduled
- Equipment: Office/retail loads
- Construction: Standard (pre-1990 to 2020)
```

#### Standard Zones
- **Perimeter Zones**: 4 (North, South, East, West)
- **Core Zones**: 1-2 (interior offices)
- **Common Areas**: Hallways, restrooms, stairwells
- **Mechanical Room**: HVAC equipment space

### Building Energy Model Parameters

#### Thermal Properties
| Property | Typical Range | Unit |
|----------|---------------|------|
| Wall U-value | 0.08-0.15 | Btu/(h·ft²·°F) |
| Window U-value | 0.25-0.4 | Btu/(h·ft²·°F) |
| Window SHGC | 0.25-0.6 | dimensionless |
| Roof U-value | 0.04-0.08 | Btu/(h·ft²·°F) |
| Air Change Rate | 0.5-1.5 | ACH |

#### HVAC System Configuration
```yaml
Cooling System:
  - Chiller: Centrifugal/screw compressor
  - Capacity: 50-500 tons
  - COP: 2.5-3.5 (typical)
  - Control: Setpoint 72°F
  
Heating System:
  - Boiler: Gas or electric
  - Capacity: 500-2000 kBtu/h
  - Efficiency: 0.8-0.95
  - Control: Setpoint 68°F
  
Distribution:
  - VAV boxes with reheat dampers
  - Supply air: 55°F (cooling), 95°F (heating)
  - Return air: Mix of zone air + outdoor air (20% minimum)
```

#### Occupancy Profiles
```
Weekday Schedule (Office Buildings):
  6:00 AM:  Building unlock, minimal load
  7:00 AM:  HVAC ramp-up
  9:00 AM:  Full occupancy (peak load begins)
  12:00 PM: Lunch period (slight load dip)
  1:00 PM:  Peak occupancy
  5:00 PM:  Occupancy starts declining
  7:00 PM:  Building unoccupied
  
Weekend/Holiday:
  All times: Minimal loads (security, lighting only)
```

#### Electric Loads
| Load Type | Fraction | Occupancy | Time-of-Use |
|-----------|----------|-----------|-------------|
| Lighting | 15-25% | Varies | Peak 9am-5pm |
| HVAC | 30-50% | Varies | Peak 2pm-6pm |
| Equipment | 20-40% | Varies | Continuous base load |
| Plug Loads | 10-20% | Occupancy | Peak 10am-4pm |

### HELICS Interface

#### Inputs (Subscriptions)
```python
# Real-time electricity price
alfalfa.subscribe("control/electricity_price")  # $/kWh

# Grid frequency (for demand response)
alfalfa.subscribe("control/grid_frequency")      # Hz

# Temperature setpoint override
alfalfa.subscribe("control/setpoint_override")   # °F

# Battery discharge signal (for peak shaving)
alfalfa.subscribe("control/battery_power")       # kW

# Demand response event
alfalfa.subscribe("control/dr_signal")           # 0-1 (magnitude)
```

#### Outputs (Publications)
```python
# Total electrical load
alfalfa.publish("building/total_load", kW)              # kW

# HVAC power breakdown
alfalfa.publish("building/hvac_power", kW)              # kW

# Lighting power
alfalfa.publish("building/lighting_power", kW)          # kW

# Equipment (plug) loads
alfalfa.publish("building/equipment_power", kW)         # kW

# Indoor temperature (weighted average)
alfalfa.publish("building/zone_temperature", °F)        # °F

# Zone humidity
alfalfa.publish("building/zone_humidity", %)            # %

# Battery charge/discharge requirement
alfalfa.publish("battery/power_request", kW)            # kW (+ = charge, - = discharge)
```

### Control Strategies

#### 1. Price-Responsive Control
```python
def price_responsive_control(price_signal, baseline_setpoint):
    if price_signal > $0.20/kWh:
        # High price: Reduce HVAC load
        setpoint = baseline_setpoint - 2°F  # 70°F → 68°F
    elif price_signal > $0.15/kWh:
        # Medium price: Slight reduction
        setpoint = baseline_setpoint - 1°F
    else:
        # Low price: Normal operation
        setpoint = baseline_setpoint
    return setpoint
```

#### 2. Demand Response Event Response
```python
def demand_response_control(dr_signal, baseline_setpoint):
    # dr_signal: 0-1 (0=no event, 1=full event)
    if dr_signal > 0.5:
        # Activate demand response
        # Pre-cool building to allow load shedding
        setpoint = baseline_setpoint - 3°F
        dim_lighting_to(50%)  # Dim non-critical lights
    else:
        # Return to normal
        setpoint = baseline_setpoint
    return setpoint
```

#### 3. Battery Coordination
```python
def battery_coordination(battery_discharge_power):
    # If battery discharging, building can maintain higher load
    # by leveraging battery power instead of grid
    if battery_discharge_power > 50:  # kW
        # Battery powering building: relax HVAC constraints
        setpoint = baseline_setpoint + 1°F
    else:
        # No battery discharge: maintain normal setpoint
        setpoint = baseline_setpoint
```

### API Endpoints

#### Configuration
```
POST   /alfalfa/create_simulation         # Create new sim
GET    /alfalfa/status/{sim_id}           # Get simulation status
DELETE /alfalfa/delete/{sim_id}           # Stop simulation
```

#### Real-Time Data
```
GET    /alfalfa/building/{sim_id}/load    # Current building load (kW)
GET    /alfalfa/building/{sim_id}/temp    # Zone temperature (°F)
POST   /alfalfa/building/{sim_id}/setpoint # Update setpoint (°F)
```

---

## Aggregator Service

### Deployment

#### Docker Container
```dockerfile
FROM python:3.9-slim

WORKDIR /usr/src/app

# Copy dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy application
COPY aggregator.py battery.py .
COPY scripts/ scripts/

# Expose API port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s CMD curl -f http://localhost:5000/version

# Start service
CMD ["python", "aggregator.py"]
```

#### Environment Setup
```bash
# Inside aggregator container
export MONGO_URI="mongodb://admin:password@mongodb:27017/batteries?authSource=admin"
export FLASK_ENV=production
export FLASK_DEBUG=0
export API_HOST=0.0.0.0
export API_PORT=5000

python aggregator.py
```

### Core Classes

#### BatteryEMS
```python
class BatteryEMS:
    """Energy Management System for battery control"""
    
    def __init__(self, battery_id, ems_address, soc_init=0.5):
        self.battery_id = battery_id
        self.ems_address = ems_address  # IP:port of EMS
        self.soc = soc_init  # State of charge 0-1
        
    def get_status(self):
        """Query EMS for real-time battery status"""
        # Connect to EMS via Modbus/DNP3
        # Read: voltage, current, SOC, temperature
        return {
            'voltage': 400,  # VDC
            'current': 25,   # A (positive = charging)
            'soc': 0.75,     # 0-1
            'temp': 28       # °C
        }
    
    def set_charge_rate(self, rate_kw):
        """Command battery to charge at specified rate"""
        # Convert rate to current setpoint
        # Send command to EMS
        # Set: setChargeDischargeRate analog point
        pass
    
    def set_discharge_rate(self, rate_kw):
        """Command battery to discharge at specified rate"""
        # Convert rate to current setpoint (negative)
        # Send command to EMS
        pass
```

### API Request/Response Examples

#### Get All Batteries
```bash
curl http://aggregator:5000/batteries
```

**Response**:
```json
[
  {
    "_id": "507f1f77bcf86cd799439011",
    "battery_id": "bess-197295_1",
    "name": "Building 197295 Main Battery",
    "service_area_id": "sa-001",
    "ems_ipaddress": "192.168.1.50:502",
    "ems_load_id": "load-197295",
    "capacity_kwh": 100,
    "power_rating_kw": 50
  },
  ...
]
```

#### Register New Battery
```bash
curl -X POST http://aggregator:5000/battery \
  -H "Content-Type: application/json" \
  -d '{
    "battery_id": "bess-new_1",
    "name": "New Building Battery",
    "description": "200 kWh lithium-ion",
    "service_area_id": "sa-002",
    "ems_ipaddress": "192.168.1.51:502",
    "ems_load_id": "load-new",
    "capacity_kwh": 200,
    "power_rating_kw": 100
  }'
```

#### Charge Service Area
```bash
curl -X POST http://aggregator:5000/service_area/sa-001/charge \
  -H "Content-Type: application/json" \
  -d '{
    "power_kw": 100,
    "duration_seconds": 1800
  }'
```

**Response**:
```json
{
  "service_area_id": "sa-001",
  "action": "charge",
  "total_power_kw": 100,
  "batteries_commanded": 3,
  "success": true,
  "timestamp": "2024-05-06T14:30:00Z"
}
```

---

## OT-Sim Agent (Federate Client)

### Architecture

```
┌─────────────────────────────────────┐
│  Linux VM (ems-{building}_1)         │
├─────────────────────────────────────┤
│                                     │
│  ┌──────────────────────────────┐  │
│  │  fd-client Service           │  │
│  │  (OT-Sim Federate Client)    │  │
│  └──────────────────────────────┘  │
│          ↓            ↓             │
│    ┌─────────┐  ┌──────────┐       │
│    │ Modbus  │  │ HELICS   │       │
│    │ Client  │  │ Endpoint │       │
│    └─────────┘  └──────────┘       │
│        ↓            ↓               │
│    RTU (BMS)   HELICS Broker        │
│                                     │
└─────────────────────────────────────┘
```

### Modbus RTU Communication

#### RTU Address Map (Battery)
```
Register Range | Description        | Type | Unit
0x0000-0x0001  | Battery Voltage    | UINT | 0.1V
0x0002-0x0003  | Battery Current    | INT  | 1A
0x0004-0x0005  | Battery SOC        | UINT | 0.1%
0x0006-0x0007  | Battery Temp       | INT  | 1°C
0x0008-0x0009  | Power Setpoint     | INT  | 1kW (coil)
0x000A         | Status             | COIL | 0=offline, 1=online
```

#### Polling Sequence
```python
def poll_battery_status():
    """Read RTU status every 1 second"""
    holding_regs = modbus_client.read_holding_registers(
        starting_address=0,
        quantity=10,
        unit_id=BATTERY_RTU_ID
    )
    
    return {
        'voltage_v': holding_regs[0] * 0.1,
        'current_a': holding_regs[1],
        'soc_percent': holding_regs[2] * 0.1,
        'temp_c': holding_regs[3],
        'status': 'online' if holding_regs[5] else 'offline'
    }
```

### HELICS Publications

#### Battery Data Publication
```python
# Publish battery state at each time step
federate.publish("battery/voltage", voltage_v)
federate.publish("battery/current", current_a)
federate.publish("battery/soc", soc_percent)
federate.publish("battery/power", power_kw)

# Publish to HELICS
federate.request_next_time(current_time + 1.0)
```

#### Control Subscription
```python
# Subscribe to charge/discharge setpoint from Aggregator
setpoint_kw = federate.get_value("battery/setpoint")

# Convert setpoint to Modbus command
if setpoint_kw > 0:
    # Charging
    current_setpoint = (setpoint_kw * 1000) / voltage_v
else:
    # Discharging
    current_setpoint = (setpoint_kw * 1000) / voltage_v

# Write to RTU
modbus_client.write_register(0x0008, int(current_setpoint), unit_id=BATTERY_RTU_ID)
```

### Fault Detection

#### Watchdog Timer
```python
def monitor_rtu_health():
    """Detect RTU communication loss"""
    last_successful_read = time.time()
    
    while True:
        try:
            data = poll_battery_status()
            last_successful_read = time.time()
            
            # Normal operation
            send_status_ok()
            
        except ModbusException:
            elapsed = time.time() - last_successful_read
            
            if elapsed > 10:  # No comms for 10 seconds
                # RTU offline
                logger.error(f"RTU {BATTERY_RTU_ID} offline")
                send_status_offline()
                
                # Set safe default
                set_battery_idle()
```

### Logging

**Log File**: `/var/log/ot-sim-{building_id}.log`

```
[2024-05-06 14:30:00] INFO: Starting OT-Sim agent for battery bms-197295_1
[2024-05-06 14:30:01] INFO: Connecting to RTU at 192.168.1.100:502
[2024-05-06 14:30:01] INFO: Connected to RTU (register count: 16)
[2024-05-06 14:30:02] INFO: HELICS broker connected
[2024-05-06 14:30:03] INFO: Battery voltage: 398.5V, SOC: 75.2%
[2024-05-06 14:30:04] INFO: Setpoint received: 25 kW charge
[2024-05-06 14:30:04] INFO: Setting charge current to 62.5 A
...
[2024-05-06 16:30:00] INFO: Simulation end time reached
[2024-05-06 16:30:01] INFO: Graceful shutdown
```

---

## Data Collection System

### Kafka Stream Architecture

#### Topic Structure
```
Kafka Cluster (1 broker in experiment)
  │
  ├─ power.voltage.sa-001
  │   └─ Voltage at primary feeder, SA-001 load point
  │
  ├─ power.line_loading.feeder1
  │   └─ Loading on Feeder 1 lines
  │
  ├─ power.frequency
  │   └─ Grid frequency (single topic, broadcast)
  │
  ├─ building.load.sa-001
  │   └─ Total load from buildings in SA-001
  │
  ├─ building.hvac.sa-001
  │   └─ HVAC power in SA-001
  │
  ├─ battery.soc.sa-001
  │   └─ Battery SOC in SA-001
  │
  └─ battery.power.sa-001
      └─ Battery charging/discharging power in SA-001
```

#### Kafka to CSV Conversion

**Binary**: `/data-sender/kafka-to-csv`

**Usage**:
```bash
kafka-to-csv \
  -e {experiment_name} \     # Phenix experiment name
  -s {scenario_name} \       # Scenario name (e.g., "baseline")
  -b {broker_address} \      # Kafka broker (e.g., "kafka:9092")
  -o {output_dir} \          # Output directory (default: ./kafka-csvs/)
  -f {format}                # Output format: csv, parquet
```

**Example**:
```bash
/usr/bin/kafka-to-csv \
  -e run-baseline-42 \
  -s baseline \
  -b kafka:9092 \
  -o /kafka-csvs
```

**Output CSV Structure**:
```csv
timestamp,service_area,metric,value,unit
2024-05-06T14:30:00Z,sa-001,voltage,11.95,kV
2024-05-06T14:30:00Z,sa-001,frequency,59.98,Hz
2024-05-06T14:30:00Z,sa-001,building_load,185.2,kW
2024-05-06T14:30:00Z,sa-001,battery_soc,75.5,%
2024-05-06T14:30:01Z,sa-001,voltage,11.94,kV
...
```

### Result Processing Pipeline

**Post-Processing Scripts** (`/data-sender/`):

1. **process-alfalfa-results.sh**
   - Collects building energy results from Alfalfa
   - Extracts building loads, temperatures, comfort metrics
   - Packages results into `building_battery_results.tgz`

2. **process-power-data.sh**
   - Runs grid analysis on Kafka CSV files
   - Generates summary statistics
   - Creates grid performance report
   - Outputs `grid_results.tgz`

#### Example: Grid Analysis Tool
```bash
python3 /grid/grid_analysis.py \
  -r kafka-csvs \                  # Input CSV directory
  -s baseline \                     # Scenario identifier
  -o results                        # Output directory
```

**Output Files**:
```
results/
├── grid_summary.txt               # Executive summary
├── voltage_report.csv             # Voltage statistics by bus
├── line_loading_report.csv        # Line loading analysis
├── loss_summary.csv               # Energy loss calculations
├── peak_analysis.csv              # Peak load events
└── demand_response_effectiveness.csv
```

