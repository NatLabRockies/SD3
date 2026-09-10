# SD3 Co-Simulation Tools

## Project Overview

The Secure-by-Design DER Deployment (SD3) research effort focused on advanced distribution systems with distributed energy resources (DERs), emphasizing how aggregated cyber events can affect grid conditions. This detrimental behavior can arise from cyberattacks in which a threat actor gains control of many connected devices. SD3 Tools examines these potential impacts at the grid edge using a high-fidelity emulation platform that co-simulates the physics of buildings and equipment with distribution-grid behavior in a cyber-physical environment. The platform identifies realistic configurations and demonstrates how cyberattacks on behind-the-meter battery systems may be mitigated through common distribution system operations.

The simulation environment was deployed on Sandia's Phenix Minimega platform to support repeatable, high-fidelity cyber-physical experimentation. The purpose of this repository is to document the study workflow, system configuration, and toolchain used in that effort. This repository is not intended to be an out-of-the-box turnkey solution, because several components used in the study were developed in-house at the National Lab of the Rockies (NLR) and are not publicly available. Even with those limitations, the configuration files, parameter values, and integration notes provided here are represented as accurately as possible so others can understand the setup and reproduce the overall methodology.

**SD3 Tools**  This repository includes the configuration files and README notes used to build this co-simulation environment for advanced distribution systems with DERs. This repository outlines the tools that enable real-time synchronous simulation of:

- **OpenDSS Power Distribution Simulator** - Models the electrical distribution grid and power flow
- **PACER Building Energy Models** - Simulates building thermal dynamics and HVAC systems  
- **Distributed Battery Energy Storage Systems (BESS)** - Includes multiple battery systems across service areas that are part of the PACER Building Energy model.
- **Aggregator Service** - Central battery management and control system

The simulators operate in real-time synchronization using **HELICS** (Hierarchical Engine for Large-scale Integrated Co-simulation), enabling realistic analysis of demand response, grid-interactive batteries, and smart building-grid integration.



## Key Capabilities

- **Real-Time Co-Simulation**: Synchronized power flow, building, and battery simulations
- **Distributed Energy Management**: Aggregator-coordinated battery dispatch and charging optimization
- **Demand Response Integration**: Building controls responsive to grid signals and electricity prices
- **Data-Rich Analysis**: Comprehensive collection and post-processing of grid, building, and battery metrics
- **Production-Grade Deployment**: Runs on Sandia's Phenix experiment platform with automated CI/CD

## Project Structure

```
sd3-tools/
├── README.md                          # This file
├── services/
│   └── aggregator/                    # Battery management service
│       ├── aggregator.py
│       ├── battery.py
│       ├── requirements.txt
│       └── scripts/
├── phenix-experiments/
│   └── baseline/                      # Baseline co-simulation experiment
│       ├── .phenix.yml                # Phenix configuration
│       ├── phenix-configs/            # Scenario, topology, SCORCH configs
│       ├── phenix-injects/            # Model files, service configs, scripts
│       └── [DOCUMENTATION FILES - See Below]
└── [Additional experimental variants]
```

## Documentation

The `phenix-experiments/baseline/` directory contains detailed documentation for the co-simulation experiment:

### 📋 [co_simulation_overview.md](docs/co_simulation_overview.md)
**Start here** for a high-level understanding of the system.
- Ssummary of the co-simulation architecture
- System data flow diagrams
- Description of all major components
- Experiment execution phases
- HELICS synchronization overview

### 🏗️ [architecture.md](docs/architecture.md)
In-depth technical architecture and component design.
- **OpenDSS Power Simulator** - Power flow calculations, model structure, HELICS interface
- **PACER Building Service** - EnergyPlus models, building controls, API endpoints
- **Battery Energy Storage Systems** - Monitoring, RTU communication, state tracking
- **Aggregator Service** - API design, battery dispatch, MongoDB schema
- **OT-Sim Agents** - HELICS federates, Modbus RTU communication, fault detection
- **Data Collection System** - Kafka streaming, post-processing, analysis tools
- Communication protocols and performance metrics

### 🚀 [deployment.md](docs/deployment.md)
Complete deployment and operational guide.
- Prerequisites and pre-deployment checklist
- Step-by-step experiment deployment via Phenix
- Real-time monitoring during simulation
- Troubleshooting common issues with solutions
- Post-simulation data analysis with Python examples
- Configuration reference for all YAML files
- Advanced options and debug modes

### 🔧 [components.md](docs/components.md)
Detailed technical specifications for each subsystem.
- **OpenDSS** - Installation, circuit models, load injection configuration
- **PACER** - Building thermal properties, HVAC systems, control strategies
- **Aggregator** - Docker setup, BatteryEMS class, database schema, API examples
- **OT-Sim** - Modbus registers, polling sequences, health monitoring
- **Data Collection** - Kafka topics, CSV conversion, result processing

## Quick Start

### For New Users
1. Start with [co_simulation_overview.md](docs/co_simulation_overview.md) to understand the system
2. Read [architecture.md](docs/architecture.md) for technical depth
3. Use [deployment.md](docs/deployment.md) to deploy your first experiment

### For Deployment
1. Follow the deployment checklist in [deployment.md](docs/deployment.md)
2. Create a feature branch and push to trigger CI/CD
3. Monitor the experiment via Phenix GUI
4. Download and analyze results

### For Troubleshooting
Refer to the troubleshooting sections in [deployment.md](docs/deployment.md) or dive into [components.md](docs/components.md) for specific subsystem details.

## Key Technologies

- **HELICS** - Time-synchronized co-simulation broker
- **OpenDSS** - Power distribution simulator
- **PACER** - Formely called "Alfalfa" is a virtual building simluation platform providing industry standard building control interfaces for interacting with models in realtime.
- **EnergyPlus** - Building energy simulation physics engine
- **MongoDB** - Battery state and configuration database
- **Aggregator** - RESTful API framework to represent an Aggregator
- **Kafka** - Real-time data streaming
- **Phenix** - Experiment orchestration platform

## Getting Help

- **Documentation**: See the detailed guides linked above
- **Issues**: Submit questions or bugs to the project issue tracker
- **Phenix Docs**: https://phenix.sceptre.dev/
- **HELICS Docs**: https://helics.readthedocs.io/

## License

See [LICENSE.md](LICENSE.md)

---

**Last Updated**: May 6, 2026
