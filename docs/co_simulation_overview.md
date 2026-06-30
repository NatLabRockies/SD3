# Co-Simulation Experiment Overview

## Executive Summary

This phenix experiment implements a **hardware-in-the-loop co-simulation** that couples:

1. **OpenDSS Power Distribution Model** - Simulates the electrical distribution grid and power flow
2. **PACER Building Simulation Web Service** - Simulates building energy models and loads
3. **Battery Energy Storage Systems (BESS)** - Distributed batteries managed by an Aggregator
4. **Aggregator Service** - Central control system managing battery charging/discharging via Energy Management Systems (EMS)

These simulators run in real-time synchronization using **HELICS (Hierarchical Engine for Large-scale Integrated Co-simulation)**, enabling realistic power flow analysis with demand response and battery storage optimization.

---

## System Architecture

### High-Level Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Phenix Experiment                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         HELICS Broker (Time Synchronization)          │  │
│  │         Broker IP: broker|eth0                        │  │
│  └──────────────────────────────────────────────────────┘  │
│                          ▲                                   │
│          ┌───────────────┼───────────────┐                  │
│          │               │               │                  │
│          ▼               ▼               ▼                  │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐        │
│  │   OpenDSS   │  │  PACER    │  │ OT-Sim Agent │        │
│  │   (Power    │  │  (Building  │  │ (EMS Control)│        │
│  │  Simulator) │  │ Simulation) │  │              │        │
│  └─────────────┘  └─────────────┘  └──────────────┘        │
│       OpenDSS           PACER VM         ot-sim VMs         │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Aggregator Service (Battery Management)             │  │
│  │  - Manages battery charging/discharging              │  │
│  │  - Communicates with EMS systems                     │  │
│  │  - Stores battery state in MongoDB                   │  │
│  └──────────────────────────────────────────────────────┘  │
│       aggregator VM                                         │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Data Collection & Processing                        │  │
│  │  - Kafka streams power metrics                        │  │
│  │  - Collects building/battery data                     │  │
│  │  - Post-processes results                             │  │
│  └──────────────────────────────────────────────────────┘  │
│       data-sender VM                                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Key Components

#### 1. **OpenDSS Power Distribution Model**
- **Host VM**: `opendss`
- **Role**: Simulates electrical grid, power flow, and distribution
- **HELICS Federate**: `sd3` (endpoint: `updates`)
- **Time Control**: End time = 9000 seconds
- **Inputs**: Battery charge/discharge commands from EMS
- **Outputs**: Voltage, frequency, power flow to PACER

#### 2. **{PACER} Building Simulation**
- **Web Service**: PACER co-simulation platform
- **Role**: Simulates building energy models and thermal dynamics
- **Models**: Multiple commercial buildings with energy management
- **Inputs**: Electricity prices, grid signals from OpenDSS
- **Outputs**: Building loads, battery power requests to Aggregator

#### 3. **Battery Energy Storage Systems (BESS)**
- **Count**: Multiple batteries (one per building service area)
- **Host VMs**: EMS federates (ems-{building_id}_1)
- **RTU Communication**: Connected to BMS (Battery Management System)
- **Managed By**: Aggregator service
- **Data Monitored**:
  - Battery voltage, current
  - Active/reactive power
  - State of charge (SOC)
  - Charge/discharge commands

#### 4. **Aggregator Service**
- **Host VM**: `aggregator`
- **Database**: MongoDB
- **Role**: Central control system for batteries
- **API Endpoints**: RESTful interface for battery management
- **Functions**:
  - Track battery status per service area
  - Receive charging signals from PACER
  - Send discharge commands to EMS systems
  - Manage service area scheduling

#### 5. **OT-Sim Agent**
- **Host VMs**: Multiple ot-sim hosts
- **Role**: Bridge between OpenDSS and EMS
- **Responsibilities**:
  - Client connections to RTUs (BMS)
  - Sensor data collection
  - Command execution on physical/simulated equipment

#### 6. **Data Collection & Analysis**
- **Host VM**: `data-sender`
- **Functions**:
  - Kafka to CSV conversion (power metrics)
  - PACER result processing
  - Power system analysis
  - Output aggregation and archival

---

## Experiment Flow

### Initialization Phase
1. Phenix starts all VMs (opendss, PACER, ot-sim, aggregator, data-sender)
2. HELICS broker initializes on broker node
3. OpenDSS simulator connects to HELICS as `sd3` federate
4. PACER service starts and connects
5. MongoDB initializes on aggregator VM
6. OT-Sim clients connect to their respective BMS federates

### Co-Simulation Phase (Real-Time Synchronized)
1. **Time Step 0-9000 seconds**
   - OpenDSS calculates power flow
   - Battery states sent to OpenDSS model
   - PACER simulates building loads and demand response
   - Building loads transmitted to OpenDSS
   - Aggregator receives charging/discharging signals
   - EMS systems send commands to batteries
   - Data continuously recorded to Kafka

### Data Collection Phase
1. Kafka metrics collected as CSV files
2. PACER results (building/battery data) exported
3. Power system analysis performed on collected data
4. Results archived for download

### Cleanup Phase (End of SCORCH)
1. All results compressed and packaged
2. Aggregator logs collected
3. Service area schedule exported
4. All outputs available for download via Phenix GUI

---

## Key Files & Structure

```
baseline/
├── .phenix.yml                 # Experiment definition
├── phenix-configs/
│   ├── scenario.yml            # HELICS apps, time config
│   ├── scorch.yml              # SCORCH workflow (data collection)
│   └── topology.yml            # Network topology, VM definitions
├── phenix-injects/
│   ├── aggregator/             # Aggregator service
│   │   ├── resolv.conf         # DNS configuration
│   │   ├── topology.yml        # EMS configurations
│   │   ├── scripts/            # Python scripts
│   │   └── certs/              # SSL certificates
│   ├── ot-sim/                 # OT-Sim federate clients
│   ├── data-sender/            # Data collection & processing
│   │   ├── kafka-to-csv        # Kafka metrics processor
│   │   ├── process-*.sh        # Post-processing scripts
│   │   ├── geojson/            # Geographic data
│   │   └── models/             # Analysis tools
│   ├── models/                 # OpenDSS and PACER model files
│   ├── router/                 # Network routing configs
│   └── commercial-*/           # Individual building configs
└── README.md                   # Original phenix documentation
```

---

## Co-Simulation Synchronization (HELICS)

### Timing Configuration
- **Simulation Duration**: 9000 seconds (2.5 hours)
- **Time Step**: Real-time (wall clock matched)
- **Broker**: Manages time advancement across all federates
- **Log Level**: Debug (verbose logging for troubleshooting)

### Data Exchange
- **OpenDSS → PACER**: Grid voltage, frequency, electricity price signals
- **PACER → OpenDSS**: Building loads, solar generation
- **OpenDSS ↔ OT-Sim**: Battery state of charge, power commands
- **OT-Sim → Aggregator**: Battery status updates
- **Aggregator → OT-Sim**: Charge/discharge commands

---

## Monitoring & Debugging

### During Experiment
- **Phenix GUI**: Monitor SCORCH component status in real-time
- **VM Logs**: 
  - Power federate: `/var/log/power.log`
  - OT-Sim: `journalctl -fu ot-sim`
- **Experiment Logs**: `/var/log/phenix/phenix.log`

### After Experiment
- **SCORCH Outputs**: Download files from Phenix GUI → Files tab
- **Generated Data**:
  - `kafka-csvs/` - Power system metrics
  - `grid_results.tgz` - Power analysis results
  - `building_battery_results.tgz` - Building/battery data
  - `service_area_schedule.csv` - Aggregator scheduling log

---

## Next Steps

- See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed component descriptions
- See [SETUP_AND_RUNNING.md](SETUP_AND_RUNNING.md) for deployment instructions
- See [COMPONENTS.md](COMPONENTS.md) for technical details on each subsystem
