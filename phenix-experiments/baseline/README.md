# Phenix Documentation 

For branches configured with the CI CD pipeline, a branch represents an experiment in phenix. The branch's name is used for the experiment's name. Note that [issues](https://gitlab.range.nrel.gov/cyber-dac1/experiment/-/issues) should be created first and branches should be created from these issues. Branch names should clearly relate to the issue they're resolving.

Important note: Branch names cannot be longer than 15 characters in length.

Updates to files / folders on a branch will be automatically uploaded and loaded into phenix and started.

### Experiment Structure & Configuration
When using the CICD pipeline, use to the following structure:
```
.
|-- .phenix.yml
|-- phenix-config
|   |-- scenario.yml
|   `-- topology.yml
`-- phenix-injects
    |-- opendss
    |   |-- model
    |   |   `-- <opendss model files>
    |   `-- config
    |       |-- obj_config.json
    |       `-- comms_config.json
    `-- commercial
        |-- inputs
        |   `-- <alfalfa model files>
        `-- config
            |-- obj_config.json
            |-- comms_config.json
            `-- load_id_config.json
```
For file and folder injects, use `/phenix/injects/{{BRANCH_NAME}}/phenix-injects/path/in/branch`

For configuring phenix experiments, follow instructions & examples here: https://phenix.sceptre.dev/latest/configuration/

### Logs & Troubleshooting

For federate VMs (configured with the `federate` app), logs can be found at `/var/log/federate-type.log`. For example, power federate logs are located at `/var/log/power.log`

For ot-sim hosts, logs can be found at `journalctl -fu ot-sim`

For troubleshooting phenix, refer to the following:
* phenix app logs: `/var/log/phenix/phenix.log` and `/var/log/phenix/error.log`
* Container logs: `docker logs phenix`
* minimega logs: `/var/log/phenix/minimega.log` and `docker logs minimega`
* experiment files: `/phenix/experiments`
* phenix injects: `/phenix/injects`


### SCORCH setup / troubleshooting
For more SCORCH information see: https://phenix.sceptre.dev/latest/scorch/

#### Running SCORCH
* Click on the `Scorch` tab on the phenix GUI. From there in the `Experiment` table, click on the experiment name you want to interact with.
* Once the experiment is selected, you can either start, stop, interact with or monitor the run. To start / stop a run, click on the red or green `started` or `stopped` button on the right corner of the run.
* To monitor a component, click on that componet and a context window should appear with that component's output (if configured)

#### Extracting  Files
* For components that collect / generate output, output can be found & downloaded by going to `Experiments` then clicking on `experiment name` and clicking on the `Files` tab which lists individual output files and zipped output folders for a run. Both can be downloaded.

#### Common issues
* A component fails (red circle with white X)
    - Click on the component to see if there's any output
    - If the component executes a command or receives a file, ensure the binary is present and all files exist
    - Check the VMs logs under 


* A component freezes
    - Ensure the miniccc executable is present and running
        - On Linux, run `systemctl status miniccc.service`
        - On Windows, go to Start Menu and type `Services`. For the list of Services, ensure the `minimega Agent` is running. If not, right click on service and select `Start`. The status should update to `Running`

### Common app issues
#### Tap: 
For issues related to routing traffic through the tap (ex: reaching the internet or another resource external to the experiment), see the following

* Ensure there's no overlapping tap ip addresses. Check this on the phenix host with `ip a | grep tapapp`
    - If a duplicate ip address is found, try the following:
        - Turn off all experiments
        - Run `docker exec -it minimega bash` to execute commands in the minimega container (where tap infrastructure lives)
        - Run `ip link show` to list all active links (infrastructure the tap creates)
        - The veth pair the tap creates is represented by a link. To clear the link (which will clear the veth pair) use `ip link delete <ip link name>` (given from the earlier command)
* If trying to reach the internet, ensure the `dns` key is configured for the VM's interface (in the topology file) and ensure the DNS IP is correct. For igor 1 nodes, dns should be `192.168.98.25`, for igor 2 dns should be `10.10.100.1` (10.10.100.2, & 10.10.100.3 are also valid IPs)
* Ensure the tap is using the same bridge as the experiment. On the host, verify with `mm tap` & `mm bridge`
#### Mirror: 
If an experiment terminates shortly after starting, see the following
* Check the app logs `tail -f /var/log/phenix/phenix.log` and container logs `docker logs -f phenix` to see if there's any messages that are mirror related
    -  If so, check the `mirrorNet` IP and ensure it's not the same as other experiments mirror's `mirrorNet` IP. Also consider removeing the `mirrorNet` configuration which tells the mirror app to choose its own unique IP address.

Also note that the mirror (as of writing this) uses the `phenix` bridge by default. This may cause issues for experiment networking if using a different bridge for the experiment (i.e. a experiment bridge in the .phenix.yml)

__NOTE: these issues have been resolved, see steps below for updating phenix__

### Updating phenix to use custom user apps

1. Run `cd /opt/phenix; make clean` to stop existing containers
2. Delete or move the `/opt/phenix` directory
3. Run `git clone --recurse-submodules https://gitlab.range.nrel.gov/cyber-dac1/apps phenix` in /opt
4. Run `cd /opt/phenix; make up` to rebuild containers

### Updating phenix to use custom core apps
Follow these steps to use mirror app fixes or to test other custom core phenix apps.

##### Using the prebuilt custom phenix image

In `/opt/phenix/docker/Dockerfile` change line 9 to `FROM harbor.range.nrel.gov/sd3/phenix-jit:latest AS phenix`, then run `cd /opt/phenix; make clean; make up`

##### Rebuilding core phenix from scratch
1. Bring down & remove old containers with cd `/opt/phenix; make clean`
2. Modify /opt/phenix/Dockerfile and replace line 9 with FROM phenix-jit:latest AS phenix to replace the remote image reference with your local image.
3. Clone https://github.com/activeshadow/sceptre-phenix to /opt
4. In /opt/sceptre-phenix/docker/Dockerfile change lines 75, 76 & 157, 158 with your gitlab / github URL to your fork & branch of the sceptre-phenix-apps repo https://github.com/activeshadow/phenix-apps
5. In /opt/sceptre-phenix create build.sh with the following:
```
#!/bin/bash
docker build -t phenix -f docker/Dockerfile --build-arg INSTALL_CERTS=https://raw.github.nrel.gov/Operations-Support/Trust-NREL-CA/master/NREL-CA/nrel-ca.pem .
cd docker/jit/
docker build -t phenix-jit -f Dockerfile --build-arg INSTALL_CERTS=https://raw.github.nrel.gov/Operations-Support/Trust-NREL-CA/master/NREL-CA/nrel-ca.pem .
```
 
6. Run `bash ./build.sh` to build local phenix & phenix-jit images.
7. Once script completes, run `docker rmi phenix` to remove the phenix images. We'll only need the phenix-jit image.
8. Run `cd /opt/phenix; make up` to build & start the container stack