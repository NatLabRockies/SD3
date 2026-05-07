# SD3 Co-Simulation Tools

## Project Overview

**SD3 Tools** is a comprehensive platform for co-simulation of advanced distribution systems with distributed energy resources. This project enables real-time synchronous simulation of:

- **OpenDSS Power Distribution Simulator** - Models the electrical distribution grid and power flow
- **Alfalfa Building Energy Models** - Simulates building thermal dynamics and HVAC systems  
- **Distributed Battery Energy Storage Systems (BESS)** - Includes multiple battery systems across service areas that are part of the Alfalfa Building Energy model.
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
- **Alfalfa Building Service** - EnergyPlus models, building controls, API endpoints
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
- **Alfalfa** - Building thermal properties, HVAC systems, control strategies
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
- **Alfalfa** - Building co-simulation platform
- **EnergyPlus** - Building energy simulation engine
- **MongoDB** - Battery state and configuration database
- **Flask** - RESTful API framework
- **Kafka** - Real-time data streaming
- **Phenix** - Experiment orchestration platform

## Getting Help

- **Documentation**: See the detailed guides linked above
- **Issues**: Submit questions or bugs to the project issue tracker
- **Slack**: Reach out on the #sd3-simulation channel
- **Phenix Docs**: https://phenix.sceptre.dev/
- **HELICS Docs**: https://helics.readthedocs.io/

## License

See LICENSE files in respective component directories.

---

**Last Updated**: May 6, 2026
