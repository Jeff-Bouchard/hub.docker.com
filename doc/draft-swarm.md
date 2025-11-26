Running multiple threaded executables across several Single Board Computers (SBCs) like Raspberry Pis requires **distributed computing or clustering**, not traditional hypervisors. Hypervisors (e.g., KVM, Xen) virtualize operating systems on a single machine, but to run workloads _across multiple SBCs_, you need **cluster management tools** that coordinate tasks over a network. For a Free and Open Source Software (FOSS) approach, use lightweight containerization (e.g., Docker with Swarm) or orchestration tools (e.g., Kubernetes via K3s) to distribute and manage multi-threaded applications across your SBC fleet.

## **Tools and Setup**

**SBCs**: Raspberry Pi or other compatible boards (RPi 4/5 recommended for performance)

**OS**: Raspberry Pi OS (64-bit) or Ubuntu Server for ARM

**Network**: Stable Ethernet or Wi-Fi connection for all nodes

**Software**:

Docker

K3s (lightweight Kubernetes)

SSH access across all nodes

Optional: `pdsh` or `clusterssh` for running commands on multiple nodes

## **Step-by-step instructions**

**Prepare all SBCs**

Install Raspberry Pi OS (64-bit) on each board.

Update the system:  
`sudo apt update && sudo apt upgrade -y`

Enable SSH and set static IPs or use DHCP reservations for consistency.

**Install Docker on each node**

Run:  
`curl -sSL https://get.docker.com | sh`

Add the `pi` user to the docker group:  
`sudo usermod -aG docker pi`

Reboot or restart the Docker service:  
`sudo systemctl restart docker`

**Choose a coordination method**

**Option A: Docker Swarm (simple clustering)**

On one Pi (manager node), initialize the swarm:  
`docker swarm init --advertise-addr <this-node-ip>`

On other Pis (worker nodes), join using the command output from the manager.

Deploy a multi-threaded service:  
`docker service create --name myapp --replicas 3 your-multi-threaded-image`

On the server node:  
`curl -sfL https://get.k3s.io | sh -`

On agent nodes:  
`curl -sfL https://get.k3s.io | K3S_URL=https://<server-ip>:6443 K3S_TOKEN=<token> sh -`

Deploy your app as a Kubernetes pod with CPU limits/requests to leverage multi-threading.

**Run multi-threaded executables**

Package your application in a Docker image with threading support (e.g., Python with `multiprocessing`, C++ with `std::thread`).

Ensure the container requests adequate CPU resources in deployment specs.

Monitor performance using `docker stats` or `kubectl top pods`.

**Optional: Use pdsh to run commands across nodes**

Install `pdsh`:  
`sudo apt install pdsh`

Add all node IPs to `~/.pdsh/machines`:  
`node1 pi@192.168.1.101`  
`node2 pi@192.168.1.102`

Run a command on all:  
`pdsh -w ^machines "uptime"`