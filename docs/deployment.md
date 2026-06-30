# Setup and Running the Co-Simulation Experiment

## Prerequisites

### Hardware Requirements
- **Host Machine**: Phenix Node in cluster (Phenix deployment environment)
- **CPU**: 16+ cores recommended
- **RAM**: 64+ GB recommended
- **Storage**: 500+ GB for simulation outputs
- **Network**: 1 Gbps Ethernet connection to Phenix host

### Software Requirements
- **Phenix**: v0.15+ with HELICS support
- **Docker**: Latest version with compose
- **Git**: For cloning repository
- **HELICS**: Pre-installed on Phenix host
- **MongoDB**: Docker image available
- **Python**: 3.8+ (in VMs)

### Access Requirements
- SSH access to Phenix host
- Write access to `/phenix/injects/` directory
- Ability to manage Docker containers
- Access to Phenix GUI (typically via web browser)

---

## Pre-Deployment Checklist

### 1. Verify Phenix Installation
```bash
# SSH to Phenix host
ssh user@phenix-host

# Check Phenix status
systemctl status phenix
docker ps | grep phenix

# Verify HELICS
which helics_broker
```

### 2. Clone Repository
```bash
cd /tmp
git clone https://gitlab.range.nrel.gov/cyber-dac1/sd3-tools.git
cd sd3-tools/phenix-experiments/baseline
```

### 3. Validate Configuration Files
```bash
# Check YAML syntax
python3 -c "import yaml; yaml.safe_load(open('.phenix.yml'))"
python3 -c "import yaml; yaml.safe_load(open('phenix-configs/scenario.yml'))"
python3 -c "import yaml; yaml.safe_load(open('phenix-configs/topology.yml'))"
python3 -c "import yaml; yaml.safe_load(open('phenix-configs/scorch.yml'))"
```

### 4. Verify Model Files Exist
```bash
# Check for required model files
ls -la phenix-injects/models/*/
ls -la phenix-injects/commercial-*/configs/

# Verify OpenDSS model
ls -la phenix-injects/ot-sim/
```

---

## Deployment Process

### Step 1: Branch Creation (CI/CD Pipeline)

The experiment is deployed via GitLab CI/CD. Create a feature branch:

```bash
# Create issue first (get issue number)
# Example: Issue #42 "Run baseline co-simulation"

# Create branch (max 15 characters)
git checkout -b run-baseline-42
git push origin run-baseline-42
```

**Note**: Once pushed, the CI pipeline automatically:
- Detects the branch
- Creates experiment in Phenix with name `run-baseline-42`
- Injects files from `/phenix-injects/` directory
- Applies topology and scenario configurations

### Step 2: Monitor Deployment (Phenix GUI)

1. Open Phenix web interface: `http://phenix-host:8080`
2. Navigate to **Experiments** tab
3. Look for experiment named `run-baseline-42`
4. Watch status progress:
   - ⚪ **Creating** → Building VMs
   - 🟡 **Running** → VMs booted, apps starting
   - 🟢 **Ready** → Ready to start SCORCH

### Step 3: Verify VM Startup

Wait for all VMs to boot. Check specific hosts:

```bash
# SSH to Phenix host
ssh user@phenix-host

# List running VMs (via minimega)
docker exec minimega mm vm info

# Expected VMs:
# - opendss (OpenDSS)
# - alfalfa (Building simulation)
# - aggregator (Battery service)
# - data-sender (Data collection)
# - broker (HELICS broker)
# - ems-{building}_1 (OT-Sim agents, ~20+ instances)
# - Various router/network VMs
```

### Step 4: Start SCORCH Workflow

In Phenix GUI:

1. Click **Scorch** tab
2. Select experiment `run-baseline-42`
3. Click the **green play button** to start
4. Monitor component execution:
   - 🟡 Components show as executing
   - 🟢 Components turn green when complete
   - ❌ Red indicates failure

---

## During Simulation

### Real-Time Monitoring

#### Via Phenix GUI
1. **Scorch** tab shows component status
2. Click any component to view live output
3. Progress bar shows overall experiment completion

#### Via SSH Terminal
```bash
# Watch main Phenix logs
tail -f /var/log/phenix/phenix.log

# Watch power simulator logs
tail -f /var/log/power.log

# Monitor OT-Sim
docker exec -it ot-sim journalctl -fu ot-sim -n 100

# Check MongoDB logs
docker logs -f mongodb

# Check Aggregator logs (from within aggregator VM)
docker exec -it aggregator tail -f /var/log/aggregator.log
```

### Common Issues During Run

#### Issue: OT-Sim Federate Timeouts
**Symptoms**: Red 'X' on ems-* components in SCORCH

**Solution**:
```bash
# Restart OT-Sim service
docker exec -it ot-sim systemctl restart ot-sim

# Increase timeout in scenario.yml
# Edit: spec.apps.ot-sim.metadata.helics.end-time
```

#### Issue: MongoDB Connection Refused
**Symptoms**: Aggregator API returns 503 errors

**Solution**:
```bash
# Check MongoDB container
docker ps | grep mongodb
docker logs mongodb | tail -20

# Restart if necessary
docker restart mongodb
```

#### Issue: Kafka Topics Not Created
**Symptoms**: kafka-to-csv gets no data

**Solution**:
```bash
# Verify Kafka is running
docker ps | grep kafka

# Check topic creation
docker exec kafka kafka-topics --list --bootstrap-server localhost:9092

# Manual topic creation if needed
docker exec kafka kafka-topics --create \
  --bootstrap-server localhost:9092 \
  --topic power_voltage \
  --partitions 1 --replication-factor 1
```

### Performance Tuning (If Simulation Lags)

If wall clock ≠ real-time:

```yaml
# In scenario.yml, reduce logging frequency:
apps:
  - name: ot-sim
    metadata:
      logging_interval: 60  # Log every 60 seconds instead of 5
      
# OR increase simulation time step:
metadata:
  helics:
    end-time: 5400  # Run 1.5 hours instead of 2.5
```

---

## Post-Simulation Analysis

### Step 1: Download Results (Phenix GUI)

In Phenix GUI:

1. Navigate to **Experiments** tab
2. Select experiment `run-baseline-42`
3. Click **Files** tab
4. Download available outputs:
   - `kafka-csvs.tgz` - Power metrics
   - `grid_results.tgz` - Grid analysis
   - `building_battery_results.tgz` - Building/battery data
   - `aggregator.log` - Service logs
   - `service_area_schedule.csv` - Scheduling log

### Step 2: Extract and Process

```bash
# Create analysis directory
mkdir -p ~/baseline-analysis
cd ~/baseline-analysis

# Extract all downloads
tar -xzf kafka-csvs.tgz
tar -xzf grid_results.tgz
tar -xzf building_battery_results.tgz

# List available CSV files
ls -la kafka-csvs/
ls -la results/

# View summary
head -20 kafka-csvs/voltage*.csv
head -20 results/grid_summary.csv
```

### Step 3: Data Analysis

#### Basic Statistics
```python
import pandas as pd
import numpy as np

# Load voltage profile data
voltage_df = pd.read_csv('kafka-csvs/voltage_profile.csv')

# Calculate statistics
print("Voltage Statistics:")
print(voltage_df['voltage_magnitude'].describe())

# Average by time window
voltage_hourly = voltage_df.set_index('timestamp').resample('1H').mean()
print(voltage_hourly)

# Find peak loading times
print("\nPeak loading:")
print(voltage_df.nlargest(10, 'line_loading')[['timestamp', 'line_id', 'line_loading']])
```

#### Battery Performance
```python
# Load battery data
battery_df = pd.read_csv('building_battery_results.csv')

# Plot state of charge over time
import matplotlib.pyplot as plt

fig, axes = plt.subplots(2, 1, figsize=(12, 8))

# SOC trend
battery_df.plot(x='timestamp', y='state_of_charge', ax=axes[0])
axes[0].set_title('Battery State of Charge Over Time')
axes[0].set_ylabel('SOC (%)')

# Power output
battery_df.plot(x='timestamp', y=['power_in', 'power_out'], ax=axes[1])
axes[1].set_title('Battery Charging/Discharging Power')
axes[1].set_ylabel('Power (kW)')

plt.tight_layout()
plt.savefig('battery_analysis.png')
print("Saved: battery_analysis.png")
```

#### Grid Performance Report
```bash
# The grid_results.tgz contains automated analysis
cd results/

# View grid summary
cat grid_summary.txt

# Peak voltage violations
grep "Voltage Violation" grid_summary.txt

# High loading events
grep "High Loading" grid_summary.txt

# Energy losses
grep "Total Loss" grid_summary.txt
```

---

## Experiment Configuration Reference

### Key Configuration Files

#### `.phenix.yml`
Controls experiment creation and auto-update:
```yaml
spec:
  auto:
    create: ${BRANCH_NAME}      # Create with branch name
    update: true                 # Auto-update on push
    restart: true                # Auto-restart if changed
```

#### `phenix-configs/scenario.yml`
Defines HELICS federation:
```yaml
spec:
  apps:
    - name: ot-sim
      metadata:
        helics:
          federate: sd3           # Federate name
          endpoint: updates       # HELICS endpoint
          end-time: 9000          # Simulation duration (seconds)
          log-level: debug        # HELICS logging
          broker:
            hostname: broker|eth0  # Broker address
```

#### `phenix-configs/scorch.yml`
Defines data collection workflow:
```yaml
spec:
  apps:
    - name: scorch
      metadata:
        components:
          - name: kafka-csvs
            type: cc             # Custom component
            metadata:
              vms:
                - hostname: data-sender
                  configure:
                    - type: background
                      args: /usr/bin/kafka-to-csv ...
```

### Environment Variables

Set in aggregator VM:
```bash
export MONGO_USERNAME=admin
export MONGO_PASSWORD=<secure-password>
export MONGO_DATABASE=batteries
export MONGO_HOSTNAME=mongodb
export MONGO_PORT=27017
```

Set in data-sender VM:
```bash
export KAFKA_BOOTSTRAP_SERVERS=kafka:9092
export GRID_ANALYSIS_TOOL=/grid/grid_analysis.py
```

---

## Troubleshooting

### Pre-Run Checks

**Problem**: Experiment doesn't appear in Phenix after branch push
```bash
# Check CI pipeline status
git push -u origin run-baseline-42
# Watch GitLab CI logs in web UI

# Manual injection if needed
phenix inject -e run-baseline-42 phenix-injects/
```

**Problem**: VMs fail to boot
```bash
# Check minimega logs
docker logs minimega | tail -100

# Check Phenix app logs
docker logs phenix | tail -100

# Restart Phenix
docker restart phenix minimega
```

### Run-Time Issues

**Problem**: HELICS broker doesn't start
```bash
# SSH to broker VM
minimega connect broker

# Check processes
ps aux | grep helics

# Manual restart
/opt/helics/bin/helics_broker -n 15 --loglevel debug
```

**Problem**: Aggregator API not responding
```bash
# Access aggregator VM
minimega connect aggregator

# Check Flask service
systemctl status aggregator
systemctl restart aggregator

# Test API
curl http://localhost:5000/version
```

**Problem**: Data not being collected (empty kafka-csvs)
```bash
# Check Kafka connectivity
minimega connect data-sender
telnet kafka 9092

# Check kafka-to-csv logs
docker logs data-sender 2>&1 | grep kafka

# Manually run converter
/usr/bin/kafka-to-csv -e run-baseline-42 -s baseline -b kafka:9092
```

### Post-Run Issues

**Problem**: Results files are incomplete
```bash
# Check SCORCH component failures
# In Phenix GUI: Scorch tab → look for red X components

# Re-run specific components
# Edit scorch.yml to add retry logic
# Redeploy: git push origin run-baseline-42
```

**Problem**: Aggregator logs missing
```bash
# SSH to aggregator VM
minimega connect aggregator

# Copy logs manually
cp /var/log/aggregator.log /downloads/
cp /var/log/service_area_schedule.log /downloads/

# Retrieve via Phenix
phenix export -e run-baseline-42 /var/log/aggregator.log
```

---

## Advanced Options

### Custom Simulation Duration
```bash
# Edit scenario.yml
sed -i 's/end-time: 9000/end-time: 5400/' phenix-configs/scenario.yml

# Push changes
git add phenix-configs/scenario.yml
git commit -m "Reduce simulation to 1.5 hours"
git push origin run-baseline-42
```

### Enable Demand Response Signals
```bash
# Edit Alfalfa control scripts in phenix-injects/
# Add demand response flags to building models

# Commit and redeploy
git push origin run-baseline-42
```

### Collect Additional Metrics
```bash
# Edit scorch.yml to add new SCORCH components
# Example: add custom analysis component

cat >> phenix-configs/scorch.yml << 'EOF'
        - name: custom-analysis
          type: cc
          metadata:
            vms:
              - hostname: data-sender
                cleanup:
                  - type: exec
                    args: python3 /custom/analysis.py
                    wait: true
EOF

# Commit and redeploy
git push origin run-baseline-42
```

### Debug Mode

Enable verbose logging:
```bash
# In scenario.yml
spec:
  apps:
    - name: ot-sim
      metadata:
        helics:
          log-level: trace    # Maximum verbosity
          
# In scorch.yml
metadata:
  filebeat:
    enabled: true            # Collect all component logs
```

---

## Support & Questions

- **Phenix Docs**: https://phenix.sceptre.dev/
- **HELICS Docs**: https://helics.readthedocs.io/
- **Project Issues**: https://gitlab.range.nrel.gov/cyber-dac1/experiment/-/issues
- **Slack Channel**: #sd3-simulation

