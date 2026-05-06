# Co-Simulation Architecture Details

## System Components

### 1. OpenDSS Power Distribution Simulator

**Location**: VM `soco`  
**Type**: OpenDSS power flow simulator  
**Role**: Backbone of the co-simulation, models the electrical distribution system

#### Responsibilities
- Calculate power flow in the distribution network
- Track voltage profiles across all nodes
- Simulate line losses and transformer behavior
- Receive battery power injections from storage systems
- Receive building loads from Alfalfa
- Broadcast electricity price signals

#### HELICS Configuration
```yaml
federate: sd3
endpoint: updates
end-time: 9000 seconds
log-level: debug
```

#### Data Interfaces
**Inputs**:
- Building loads from Alfalfa (aggregated per zone)
- Battery charge/discharge power from EMS systems
- User-defined demand response events

**Outputs**:
- Nodal voltage magnitudes and angles
- Grid frequency
- Line loading percentages
- Electricity prices (locational marginal pricing if enabled)

#### Model Structure
- **Distribution Network**: Multi-zone grid with substations
- **Nodes**: Hundreds of load points and generation points
- **Voltage Levels**: Typically 12-35 kV distribution
- **Load Injection Points**: One per building service area

---

### 2. Alfalfa Building Simulation Web Service

**Type**: Building energy simulation platform  
**Role**: Co-simulate building thermal dynamics and HVAC systems

#### Architecture
```
┌──────────────────────────────────────────┐
│         Alfalfa Web Service               │
├──────────────────────────────────────────┤
│  ┌─────────────────────────────────────┐ │
│  │   Building Energy Models (EnergyPlus) │ │
│  │   - Multiple commercial buildings      │ │
│  │   - Thermal dynamics                   │ │
│  │   - HVAC systems                       │ │
│  │   - Occupancy schedules                │ │
│  └─────────────────────────────────────┘ │
│                                          │
│  ┌─────────────────────────────────────┐ │
│  │   Control Layer                      │ │
│  │   - Demand response signals           │ │
│  │   - Battery dispatch commands         │ │
│  │   - Temperature setpoints             │ │
│  └─────────────────────────────────────┘ │
│                                          │
│  ┌─────────────────────────────────────┐ │
│  │   HELICS Interface                   │ │
│  │   - Time synchronization              │ │
│  │   - Load export                       │ │
│  │   - Signal import                     │ │
│  └─────────────────────────────────────┘ │
└──────────────────────────────────────────┘
```

#### Data Interfaces
**Inputs**:
- Real-time electricity prices from OpenDSS
- Grid frequency (for demand response triggering)
- Building setpoint adjustments from Aggregator
- External weather data (temperature, solar irradiance)

**Outputs**:
- Electrical load profiles (per building, per time step)
- HVAC power consumption
- Real-time power demand signals
- Building comfort metrics

#### Building Models
- **Count**: 20+ commercial buildings
- **Types**: Office, retail, mixed-use
- **Features**:
  - EnergyPlus thermal simulation
  - HVAC systems with variable capacity
  - Occupancy-driven schedules
  - Solar thermal models

#### Control Scenarios
- **Price-Responsive**: Loads vary with electricity price
- **Demand Response**: Shed load when grid signals spike
- **Battery-Coordinated**: Batteries discharge during peak periods

---

### 3. Battery Energy Storage Systems (BESS)

**Count**: One battery per major building service area (~20 systems)  
**Physical Location**: Distributed across network nodes  
**Monitoring**: Via Federate Devices (FD) and RTU connections

#### Battery Specifications
**Typical Configuration**:
- **Capacity**: 100-500 kWh (building-scale)
- **Power Rating**: 50-250 kW
- **Chemistry**: Lithium-ion (modeled)
- **Efficiency**: 85-95% round-trip

#### Communication Stack
```
OpenDSS Grid Signal
        ↓
OT-Sim Agent (fd-client)
        ↓
BMS (Battery Management System)
        ↓
Battery Hardware/Simulation
        ↓
RTU Monitor (bms-{building_id}_1)
        ↓
EMS System
        ↓
Aggregator Service (HTTP API)
```

#### Monitored Parameters
**Via HELICS Subscription**:
```yaml
infrastructures:
  power-distribution:
    storage:
      - batteryVoltage: analog-read
      - batteryCurrent: analog-read
      - activePowerStatusBattery: analog-read
      - reactivePowerStatusBattery: analog-read
      - stateOfChargeStatus: analog-read
      - setChargeDischargeRate: analog-read-write
```

#### State Variables
- **Voltage**: DC link voltage (e.g., 400V)
- **Current**: Charging (+) or discharging (-) current
- **Power**: Active (kW) and reactive (kVAr)
- **SOC**: State of charge (0-100%)
- **Setpoint**: Requested charge/discharge rate

---

### 4. Aggregator Service

**Host VM**: `aggregator`  
**Type**: RESTful API service  
**Technology**: Flask (Python) + MongoDB  
**Port**: 5000 (default)

#### Architecture
```
┌──────────────────────────────────────────┐
│         Aggregator Service                │
├──────────────────────────────────────────┤
│  ┌──────────────────────────────────────┐ │
│  │   API Layer (Flask)                   │ │
│  │   - GET/POST battery endpoints        │ │
│  │   - Charge/discharge commands         │ │
│  │   - Service area management           │ │
│  └──────────────────────────────────────┘ │
│                                          │
│  ┌──────────────────────────────────────┐ │
│  │   Business Logic (BatteryEMS)         │ │
│  │   - Dispatch optimization             │ │
│  │   - State estimation                  │ │
│  │   - Constraint enforcement            │ │
│  └──────────────────────────────────────┘ │
│                                          │
│  ┌──────────────────────────────────────┐ │
│  │   Data Layer (MongoDB)                │ │
│  │   - Battery inventory                 │ │
│  │   - Service areas                     │ │
│  │   - State of charge history           │ │
│  │   - Charging schedules                │ │
│  └──────────────────────────────────────┘ │
└──────────────────────────────────────────┘
```

#### Core Responsibilities

**Battery Management**
- Track battery status and state of charge
- Store battery metadata (capacity, rating, location)
- Monitor health indicators (cycle count, temperature)

**Control Dispatch**
- Generate charging/discharging schedules
- Send setpoint commands to EMS systems
- Receive power feedback from batteries

**Service Area Coordination**
- Group batteries by service territory
- Aggregate power available for demand response
- Coordinate peak shaving across service areas

#### API Endpoints

| Method | Endpoint | Function |
|--------|----------|----------|
| GET | `/batteries` | List all batteries |
| GET | `/battery/<id>` | Get specific battery details |
| POST | `/battery` | Register new battery |
| PUT | `/battery/<id>` | Update battery info |
| DELETE | `/battery/<id>` | Deregister battery |
| POST | `/service_area/<id>/charge` | Charge batteries in area |
| POST | `/service_area/<id>/discharge` | Discharge batteries in area |
| GET | `/version` | API version info |

#### Database Schema
**Batteries Collection**:
```json
{
  "_id": "ObjectId",
  "battery_id": "bess-197295_1",
  "name": "Building 197295 Main Battery",
  "description": "100 kWh lithium-ion",
  "service_area_id": "sa-001",
  "ems_ipaddress": "192.168.1.50",
  "ems_load_id": "load-197295",
  "capacity_kwh": 100,
  "power_rating_kw": 50,
  "current_soc": 75.5,
  "last_update": "2024-05-06T14:30:00Z"
}
```

**Service Areas Collection**:
```json
{
  "_id": "ObjectId",
  "service_area_id": "sa-001",
  "name": "Downtown District",
  "batteries": ["bess-197295_1", "bess-464636_1"],
  "total_capacity_kwh": 500,
  "aggregate_power_kw": 250,
  "schedule": [...]
}
```

---

### 5. OT-Sim Agent (Federate Clients)

**Host VMs**: Multiple `ot-sim-*` nodes  
**Role**: Bridge between HELICS simulation and physical/simulated RTUs

#### Deployment
```yaml
ot-sim hosts:
  - ems-197295_1 (type: fd-client, RTU: bms-197295_1)
  - ems-464636_1 (type: fd-client, RTU: bms-464636_1)
  - ems-357101_1 (type: fd-client, RTU: bms-357101_1)
  - ... (20+ more)
```

#### Responsibilities
1. **RTU Communication**
   - Establish connections to Battery Management Systems
   - Publish battery state via HELICS
   - Subscribe to control setpoints

2. **Data Translation**
   - Convert HELICS signal → RTU protocol command
   - Convert RTU data → HELICS subscription values
   - Handle protocol differences (Modbus, DNP3, etc.)

3. **Monitoring**
   - Log all sensor reads and commands
   - Detect RTU failures or communication loss
   - Report health status to Aggregator

#### Architecture
```
EMS Federate (ems-{building_id}_1)
    ↓
Miniccc Agent (Phenix control)
    ↓
OT-Sim Process (fd-client)
    ↓
┌─────────────────┐         ┌──────────────────┐
│ RTU Simulator   │         │ HELICS Interface │
│ (BMS data)      │         │ (Time synced)    │
└─────────────────┘         └──────────────────┘
```

---

### 6. Data Collection System

**Host VM**: `data-sender`  
**Components**:
- **Kafka Consumer**: Captures live metrics during simulation
- **CSV Generator**: Converts Kafka streams to analyzable format
- **Result Processor**: Post-processes building/battery data
- **Power Analyst**: Analyzes grid performance

#### Data Pipeline

```
┌─────────────────────────────────────────────────────┐
│  Simulation Running (Real-Time Data Streams)        │
├─────────────────────────────────────────────────────┤
│                                                     │
│  OpenDSS → Kafka Topics                           │
│    - voltage_profile                               │
│    - line_loading                                  │
│    - power_flow                                    │
│    - losses                                        │
│                                                     │
│  Alfalfa → Kafka Topics                           │
│    - building_load                                 │
│    - hvac_power                                    │
│    - thermal_comfort                               │
│                                                     │
│  BESS → Kafka Topics                              │
│    - battery_soc                                   │
│    - battery_power                                 │
│                                                     │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│  Data Processing (End of Simulation)                │
├─────────────────────────────────────────────────────┤
│                                                     │
│  kafka-to-csv                                      │
│    Converts: Kafka topics → CSV files              │
│    Output: kafka-csvs/ directory                   │
│                                                     │
│  process-alfalfa-results.sh                        │
│    Converts: Alfalfa outputs → Packaged data       │
│    Output: building_battery_results.tgz            │
│                                                     │
│  process-power-data.sh                             │
│    Runs: grid_analysis.py on metrics               │
│    Generates: Grid performance summary              │
│    Output: grid_results.tgz                        │
│                                                     │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│  SCORCH Cleanup (Download Results)                  │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Files available via Phenix GUI:                   │
│    - kafka-csvs/        (power metrics)            │
│    - grid_results.tgz   (grid analysis)            │
│    - building_*.tgz     (building data)            │
│    - aggregator.log     (service logs)             │
│                                                     │
└─────────────────────────────────────────────────────┘
```

#### Key Metrics Collected
**From OpenDSS**:
- Voltage at each bus (V, angle)
- Active/reactive power flow (kW, kVAr)
- Line loading (%)
- Transformer tap positions
- Loss calculations

**From Alfalfa**:
- Building electricity load (kW)
- HVAC power consumption
- Thermal zone temperatures
- Occupancy counts
- Equipment states

**From Batteries**:
- State of charge (%)
- Charging/discharging power (kW)
- Current (A) and voltage (V)
- Temperature

---

## Communication Protocols

### HELICS (Time-Sync Federation)
- **Type**: Publish-subscribe + time-advance
- **Broker**: Central time keeper
- **Latency**: Deterministic (no network delay simulation)
- **Guarantees**: Causal message delivery, synchronized time steps

### EMS → Aggregator (HTTP/REST)
- **Protocol**: HTTP POST/GET
- **Port**: 5000 (default)
- **Format**: JSON
- **Auth**: Optional (API key or basic auth)

### RTU ↔ OT-Sim (Industrial Protocol)
- **Common Protocols**: Modbus TCP, DNP3, IEC 60870-5-104
- **Port**: Varies (e.g., 502 for Modbus, 20000 for DNP3)
- **Timeout**: Configurable per RTU
- **Redundancy**: Watchdog timers on loss of comms

### Kafka (Live Streaming)
- **Type**: Pub-sub message broker
- **Topic Convention**: `{simulator}_{metric}_{service_area}`
- **Partitions**: Per service area or per building
- **Retention**: Configurable (keep all for analysis)

---

## Simulation Timing & Synchronization

### Time Advancement Algorithm
```
Step 1: OpenDSS requests time advance to T+1s
        ├─ Publishes battery power setpoints
        └─ Waits for HELICS broker

Step 2: Alfalfa advances to T+1s
        ├─ Receives loads from OpenDSS
        ├─ Calculates new building loads
        └─ Publishes to OpenDSS

Step 3: OT-Sim federates advance
        ├─ Receive control commands
        ├─ Update battery states
        └─ Publish state changes

Step 4: Broker grants time advance
        All federates synchronized at T+1s
```

### Critical Timing
- **Simulation Duration**: 9000 seconds (2.5 hours) by default
- **Wall Clock Ratio**: 1:1 (real-time operation)
- **Minimum Time Step**: 1 second (can be configured smaller for faster-dynamics)
- **Data Logging**: Every 5-60 seconds (configurable per component)

---

## Failure Modes & Recovery

### OpenDSS Crashes
- **Detection**: HELICS broker timeout (default 60s)
- **Impact**: Entire simulation stalls
- **Recovery**: Manual restart from Phenix GUI, resume from checkpoint (if enabled)

### Battery Loses Communication
- **Detection**: EMS federate detects no data for N seconds
- **Impact**: Battery locks at last known setpoint (safe state)
- **Recovery**: Automatic re-establish when RTU comes back online

### MongoDB Connection Loss
- **Detection**: Aggregator API catches connection exception
- **Impact**: Battery registration fails, queries return 503
- **Recovery**: Wait for MongoDB restart, API requests auto-retry

### Kafka Topic Full
- **Detection**: Data-sender sees producer timeouts
- **Impact**: Real-time metrics stop being logged
- **Recovery**: Increase broker disk space or reduce retention

---

## Security Considerations

### Network Isolation
- All systems run within phenix virtual network
- No external internet access by default
- TAP interface available for controlled external communication

### Authentication
- **Aggregator API**: Optional Bearer token authentication
- **MongoDB**: Username/password (configured via environment variables)
- **HELICS**: No authentication (trusted internal network)

### Data Privacy
- All outputs compressed and archived to host
- Sensitive data (logs, configs) in signed downloads
- Option to redact building-specific details for sharing

---

## Performance Metrics

### Simulation Speed
- **Real-Time Factor**: 1.0x (wall clock matched)
- **Typical Duration**: 2.5 hours per simulation run
- **Overhead**: ~5-10% CPU for synchronization

### Data Volume
- **Metrics Per Time Step**: ~1000 data points
- **Simulation Duration**: 9000 seconds
- **Total Records**: ~9 million (before aggregation)
- **Compressed Size**: 100-500 MB per run

### API Responsiveness
- **Aggregator Latency**: <100 ms for battery queries
- **EMS Command Propagation**: <1 second to RTU
- **Sensor Update Rate**: 1-5 second intervals
