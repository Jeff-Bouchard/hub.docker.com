# Privateness Full-OSI Stack: Docker Container Orchestration & Service Health Checks

## 1. Overview

This codemap documents how the Privateness Full‑OSI stack is deployed and validated end‑to‑end:

- **Shell entrypoints** orchestrating Docker Compose and Portainer.
- **Docker Compose files** defining service dependencies and health checks.
- **Service containers** that perform initialization (entropy, DNS, blockchain, IPFS).
- An **interactive management menu** that runs cross‑layer health checks.

Each trace below corresponds to a logical flow through the stack, with concrete file and line references.

### Global OSI Stack Coverage (Mermaid)

```mermaid
flowchart TB
    subgraph L1["Foundation / Data Layer"]
        EMC[Emercoin Core\n(blockchain + NVS)]
        RNG[pyuheprng-privatenesstools\n(entropy + tools)]
        IPFS[IPFS Node]
    end

    subgraph L2["Network / Overlay Layer"]
        YGG[Yggdrasil Mesh]
        I2P[I2P-Yggdrasil\n(anonymity)]
        SKY[Skywire\n(MPLS routing)]
        DNS[DNS Reverse Proxy\n(EmerDNS)]
    end

    subgraph L3["Application Layer"]
        PRIV[Privateness Core]
        PTOOLS[privatenesstools]
        PNUM[privatenumer]
        MENU[ness-menu.sh\n(health & control)]
        PORT[Portainer Stack\n(portainer-stack.yml)]
    end

    EMC --> RNG
    EMC --> DNS
    EMC --> PRIV
    EMC --> PTOOLS
    EMC --> PNUM

    YGG --> I2P
    YGG --> DNS
    YGG --> SKY
    YGG --> PRIV

    RNG --> PRIV
    RNG --> PNUM

    IPFS --> PRIV

    PRIV --> PTOOLS

    MENU --> PRIV
    MENU --> EMC
    MENU --> DNS

    PORT --> EMC
    PORT --> PRIV
```

---

## 2. Trace 1 – Essential Stack Deployment Flow

**Title:** Essential Stack Deployment Flow  
**Entry:** `deploy-ness.sh`

```mermaid
flowchart TD
    A[deploy-ness.sh] --> B[Check Docker daemon\n(1a)]
    B --> C[Check docker-compose installed]
    C --> D[Check entropy configuration\n(1b)]
    D --> E[User confirmation\nif protections missing]
    E --> F[docker-compose.ness.yml up -d\n(1c)]
    F --> G[emercoin-core]
    F --> H[pyuheprng-privatenesstools]
    F --> I[dns-reverse-proxy]
    F --> J[privateness]
    J --> K[Show running services & health status\n(1d)]
```

```text
Essential Stack Deployment Flow (deploy-ness.sh)
├── Prerequisite Validation
│   ├── Check Docker daemon running <-- 1a
│   ├── Check docker-compose installed <-- deploy-ness.sh:22
│   └── Validate entropy configuration
│       └── grep /proc/cmdline for GRUB params <-- 1b
├── User Confirmation
│   └── Prompt if entropy protections missing <-- deploy-ness.sh:47
├── Docker Compose Orchestration
│   └── docker-compose up -d <-- 1c
│       ├── Pulls nessnetwork/* images <-- docker-compose.ness.yml:5
│       ├── Creates ness-network bridge <-- docker-compose.ness.yml:103
│       ├── Starts emercoin-core (foundation) <-- docker-compose.ness.yml:4
│       ├── Waits for healthcheck <-- docker-compose.ness.yml:43
│       ├── Starts pyuheprng-privatenesstools <-- docker-compose.ness.yml:23
│       ├── Starts dns-reverse-proxy <-- docker-compose.ness.yml:48
│       └── Starts privateness <-- docker-compose.ness.yml:67
└── Post-Deployment Status
    ├── Show running services <-- 1d
    └── Display health check endpoints <-- deploy-ness.sh:67
```

**Key Locations**

- **1a – Docker Runtime Check**  
  `deploy-ness.sh:16` – Validates Docker daemon is running before deployment.

- **1b – Entropy Security Validation**  
  `deploy-ness.sh:29` – Checks GRUB `/proc/cmdline` for entropy protections.

- **1c – Launch Essential Services**  
  `deploy-ness.sh:57` – Runs `docker-compose -f docker-compose.ness.yml up -d` to start core services.

- **1d – Display Service Status**  
  `deploy-ness.sh:65` – Shows running containers and health status after deployment.

---

## 3. Trace 2 – Docker Compose Service Dependency Chain

**Title:** Docker Compose Service Dependency Chain  
**Entry:** `docker-compose.ness.yml`

```mermaid
flowchart TD
    EMC[emercoin-core\n(foundation)] --> RNG[pyuheprng-privatenesstools\n(entropy)]
    EMC --> DNS[dns-reverse-proxy\n(DNS/NVS)]
    EMC --> PRIV[privateness\n(core app)]

    RNG --> PRIV
    DNS --> PRIV

    classDef foundation fill=#1f2937,stroke=#000,color=#fff;
    classDef service fill=#0f766e,stroke=#000,color=#fff;

    class EMC foundation;
    class RNG,DNS,PRIV service;
```

```text
docker-compose.ness.yml Stack Definition
├── emercoin-core service <-- 2a
│   ├── image: nessnetwork/emercoin-core:latest <-- docker-compose.ness.yml:5
│   ├── volumes: emercoin-data:/data <-- docker-compose.ness.yml:8
│   ├── ports: 6661, 6662 <-- docker-compose.ness.yml:10
│   └── healthcheck <-- docker-compose.ness.yml:13
│       └── test: kill -0 1 <-- 2b
│           └── interval: 30s, retries: 3 <-- docker-compose.ness.yml:16
├── pyuheprng-privatenesstools service <-- docker-compose.ness.yml:23
│   ├── image: nessnetwork/pyuheprng-...:latest <-- docker-compose.ness.yml:24
│   ├── privileged: true <-- 2d
│   ├── devices: /dev/random <-- docker-compose.ness.yml:28
│   ├── ports: 5000, 8888 <-- docker-compose.ness.yml:32
│   ├── environment: EMERCOIN_HOST, MIN_ENTROPY <-- docker-compose.ness.yml:36
│   └── depends_on <-- docker-compose.ness.yml:42
│       └── emercoin-core <-- docker-compose.ness.yml:43
│           └── condition: service_healthy <-- 2c
├── dns-reverse-proxy service <-- docker-compose.ness.yml:48
│   ├── image: nessnetwork/dns-reverse-proxy <-- docker-compose.ness.yml:49
│   ├── ports: 53/udp, 53/tcp, 8053 <-- docker-compose.ness.yml:52
│   ├── environment: EMERCOIN_HOST, DNS_NVS_KEY <-- docker-compose.ness.yml:56
│   └── depends_on: emercoin-core <-- docker-compose.ness.yml:62
└── privateness service <-- docker-compose.ness.yml:67
    ├── image: nessnetwork/privateness:latest <-- docker-compose.ness.yml:68
    ├── ports: 6006, 6660 <-- docker-compose.ness.yml:70
    └── depends_on <-- 2e
        ├── emercoin-core <-- docker-compose.ness.yml:75
        ├── dns-reverse-proxy <-- docker-compose.ness.yml:76
        └── pyuheprng-privatenesstools <-- docker-compose.ness.yml:77
```

**Key Locations**

- **2a – Foundation Service Definition**  
  `docker-compose.ness.yml:4` – Emercoin Core as foundation service.

- **2b – Emercoin Health Check**  
  `docker-compose.ness.yml:15` – Liveness via `kill -0 1` on PID 1.

- **2c – Dependency Wait Condition**  
  `docker-compose.ness.yml:44` – `pyuheprng-privatenesstools` waits on Emercoin health.

- **2d – Privileged Entropy Service**  
  `docker-compose.ness.yml:26` – Entropy service requires `privileged: true` and `/dev/random` access.

- **2e – Privateness Dependencies**  
  `docker-compose.ness.yml:77` – Privateness depends on Emercoin, DNS proxy, and entropy service.

---

## 4. Trace 3 – Entropy Service Initialization with Emercoin Connection

**Title:** Entropy Service Initialization with Emercoin Connection  
**Entry:** `pyuheprng-privatenesstools/entrypoint.sh`, `supervisord.conf`

```mermaid
flowchart TD
    A[entrypoint.sh] --> B[Check /dev/random writable\n(3a)]
    B --> C[Wait for Emercoin RPC\n(3b)]
    C --> D[Read entropy_avail\n(3c)]
    D --> E[Start supervisord]
    E --> F[pyuheprng program\n(3d)]
    E --> G[privatenesstools program\n(3e)]
```

```text
pyuheprng-privatenesstools Container Startup
├── entrypoint.sh execution <-- entrypoint.sh:1
│   ├── Validate privileged access <-- 3a
│   │   └── Check /dev/random writable <-- entrypoint.sh:15
│   ├── Wait for Emercoin Core RPC <-- 3b
│   │   └── Loop: curl getinfo until success <-- entrypoint.sh:25
│   ├── Read system entropy pool <-- 3c
│   │   └── cat /proc/sys/kernel/random/... <-- entrypoint.sh:41
│   └── exec supervisord <-- entrypoint.sh:61
│       └── supervisord.conf processing <-- supervisord.conf:1
│           ├── [program:pyuheprng] <-- 3d
│           │   └── python server.py --feed-dev-random
│           │       --emercoin-rc4ok
│           │       --min-entropy-rate 1000
│           │       --block-on-low-entropy true
│           └── [program:privatenesstools] <-- 3e
               └── python server.py (port 8888)
```

**Key Locations**

- **3a – Validate `/dev/random` Access**  
  `pyuheprng-privatenesstools/entrypoint.sh:14` – Ensures container can write to `/dev/random`.

- **3b – Wait for Emercoin RPC**  
  `pyuheprng-privatenesstools/entrypoint.sh:22` – Loops on Emercoin `getinfo` RPC until available.

- **3c – Check Current Entropy Level**  
  `pyuheprng-privatenesstools/entrypoint.sh:40` – Reads `/proc/sys/kernel/random/entropy_avail`.

- **3d – Start pyuheprng with RC4OK**  
  `pyuheprng-privatenesstools/supervisord.conf:9` – Starts entropy service with Emercoin RC4OK and blocking on low entropy.

- **3e – Start privatenesstools**  
  `pyuheprng-privatenesstools/supervisord.conf:18` – Launches supporting tools (port 8888).

---

## 5. Trace 4 – Interactive Management Menu with Health Checks

**Title:** Interactive Management Menu with Health Checks  
**Entry:** `ness-menu.sh`

```mermaid
flowchart TD
    M[ness-menu.sh menu()] --> S[start_stack()\n-> deploy-ness.sh]
    M --> H[health_check()]
    M --> T[stack_status()]

    H --> HD[Docker services check\ncompose ps]
    H --> HE[Privateness sync\nexplorer vs privateness-cli]
    H --> HF[Emercoin sync\nexplorer vs emercoin-cli]
    H --> DNS[DNS tests\nname_show + ping private.ness]
```

```text
ness-menu.sh Interactive Management
├── Menu System
│   ├── menu() loop <-- 4a
│   │   └── start_stack() calls deploy-ness.sh <-- ness-menu.sh:141
├── Stack Status Display
│   ├── stack_status() function <-- ness-menu.sh:71
│   │   └── compose ps | awk parse <-- 4b
│   └── print_info() shows system state <-- ness-menu.sh:90
└── Health Check Function
    ├── health_check() orchestrator <-- ness-menu.sh:173
    │   ├── Docker Services Check
    │   │   └── compose ps <-- 4c
    │   ├── Privateness Sync Validation
    │   │   ├── curl explorer API <-- 4d
    │   │   ├── docker exec privateness-cli <-- 4e
    │   │   └── compare seq/block_hash <-- 4f
    │   ├── Emercoin Sync Validation
    │   │   ├── curl explorer height/hash <-- ness-menu.sh:232
    │   │   └── emercoin-cli getblockchaininfo <-- ness-menu.sh:239
    │   └── DNS Resolution Tests
    │       ├── emercoin-cli name_show <-- 4g
    │       └── ping_host private.ness <-- 4h
```

**Key Locations**

- **4a – Menu Invokes Deployment**  
  `ness-menu.sh:144` – Menu option calls `deploy-ness.sh` to start stack.

- **4b – Count Running Services**  
  `ness-menu.sh:82` – Parses `compose ps` output to determine stack status.

- **4c – Display Service Status**  
  `ness-menu.sh:182` – Shows container states for Ness Essential stack.

- **4d – Query Explorer API**  
  `ness-menu.sh:196` – Fetches canonical blockchain state from public explorer.

- **4e – Query Local Node Status**  
  `ness-menu.sh:203` – Runs `privateness-cli status` inside container.

- **4f – Validate Blockchain Sync**  
  `ness-menu.sh:207` – Compares local `seq/block_hash` with explorer.

- **4g – Test EmerNVS Resolution**  
  `ness-menu.sh:274` – Uses `emercoin-cli name_show dns:private.ness`.

- **4h – Test DNS Resolution**  
  `ness-menu.sh:283` – Pings `private.ness` to confirm DNS proxy works.

---

## 6. Trace 5 – DNS Reverse Proxy Initialization with NVS Config

**Title:** DNS Reverse Proxy Initialization with NVS Config  
**Entry:** `dns-reverse-proxy/entrypoint.sh`

```mermaid
flowchart TD
    A[entrypoint.sh] --> B[wait_for_rpc()\n(getinfo)\n(5a)]
    B --> C[fetch_nvs_config()\nname_show\n(5b)]
    C --> D[Unescape JSON value\n(5c)]
    D --> E[Start dns-reverse-proxy\nwith NVS args\n(5d)]
```

```text
DNS Reverse Proxy Initialization Flow
├── Container Startup
│   └── entrypoint.sh execution <-- Dockerfile:25
│       ├── wait_for_rpc() function <-- entrypoint.sh:18
│       │   └── Loop until RPC available <-- entrypoint.sh:20
│       │       └── rpc_call getinfo <-- 5a
│       ├── fetch_nvs_config() function <-- entrypoint.sh:29
│       │   ├── Call name_show RPC <-- 5b
│       │   ├── Parse JSON response <-- entrypoint.sh:32
│       │   └── Unescape config value <-- 5c
│       └── exec dns-reverse-proxy $ARGS <-- 5d
└── Emercoin Core (dependency) <-- docker-compose.ness.yml:4
    └── RPC endpoint :6662 <-- docker-compose.ness.yml:11
        └── Provides NVS records
```

**Key Locations**

- **5a – Poll Emercoin RPC**  
  `dns-reverse-proxy/entrypoint.sh:21` – Loops until Emercoin RPC responds.

- **5b – Fetch NVS Configuration**  
  `dns-reverse-proxy/entrypoint.sh:31` – Retrieves DNS proxy config via `name_show`.

- **5c – Parse JSON-Escaped Config**  
  `dns-reverse-proxy/entrypoint.sh:40` – Unescapes JSON value for runtime use.

- **5d – Start DNS Proxy with NVS Args**  
  `dns-reverse-proxy/entrypoint.sh:48` – Launches `dns-reverse-proxy` with blockchain-sourced args.

---

## 7. Trace 6 – Multi-Architecture Image Build Pipeline

**Title:** Multi-Architecture Image Build Pipeline  
**Entry:** `build-all.sh`, `build-multiarch.sh`

```mermaid
flowchart TD
    A[build-all.sh] --> B[Define IMAGES order\n(6a)]
    B --> C[Check context dirs\n(6b)]
    C --> D[docker build per image\n(6c)]

    E[build-multiarch.sh] --> F[Setup buildx builder\n(6d)]
    F --> G[buildx build\namd64/arm64/armv7\n(6e)]
```

```text
Multi-Architecture Image Build Pipeline
├── build-all.sh orchestration <-- build-all.sh:1
│   ├── Define build order array <-- 6a
│   ├── For each image in order <-- build-all.sh:30
│   │   ├── Validate context directory exists <-- 6b
│   │   └── docker build with namespace tag <-- 6c
│   └── Sequential single-arch builds
│
└── build-multiarch.sh orchestration <-- build-multiarch.sh:1
    ├── Setup/reuse buildx builder <-- 6d
    ├── For each service
    │   └── docker buildx build multi-platform <-- 6e
    │       ├── Platform: linux/amd64 <-- build-multiarch.sh:13
    │       ├── Platform: linux/arm64 <-- build-multiarch.sh:13
    │       └── Platform: linux/arm/v7 <-- build-multiarch.sh:13
    └── Auto-push to registry <-- build-multiarch.sh:15
```

**Key Locations**

- **6a – Define Build Order**  
  `build-all.sh:9` – Explicit image order to respect dependencies.

- **6b – Validate Build Context**  
  `build-all.sh:33` – Ensures each service directory exists before building.

- **6c – Build Service Image**  
  `build-all.sh:39` – Executes `docker build` with `${DOCKER_USER}/${image}:latest` tags.

- **6d – Setup Multi-Arch Builder**  
  `build-multiarch.sh:9` – Creates or reuses `ness-builder` buildx builder.

- **6e – Build for Multiple Platforms**  
  `build-multiarch.sh:15` – Builds and pushes images for `linux/amd64`, `linux/arm64`, `linux/arm/v7`.

---

## 8. Trace 7 – Privateness Blockchain Node Initialization

**Title:** Privateness Blockchain Node Initialization  
**Entry:** `privateness/Dockerfile`, `privateness/entrypoint.sh`

```mermaid
flowchart TD
    A[Privateness Dockerfile] --> B[Clone ness repo\n(7a)]
    B --> C[Build privateness binary\n(7b)]
    B --> D[Build privateness-cli]
    C --> E[Copy binaries & set healthcheck\n(7c)]

    E --> F[entrypoint.sh]
    F --> G[Show config banner]
    G --> H[Start privateness daemon\n(7d)]

    EMC[emercoin-core] --> H
    DNS[dns-reverse-proxy] --> H
    RNG[pyuheprng-privatenesstools] --> H
```

```text
Privateness Blockchain Node Build & Initialization
├── Dockerfile Build Stage <-- Dockerfile:1
│   ├── Clone ness repository <-- 7a
│   ├── Cross-compile privateness binary <-- 7b
│   ├── Cross-compile privateness-cli binary <-- Dockerfile:23
│   ├── Copy binaries to final image <-- Dockerfile:34
│   └── Configure healthcheck <-- 7c
│       └── privateness-cli status command <-- Dockerfile:57
├── Container Runtime
│   └── entrypoint.sh execution <-- Dockerfile:61
│       ├── Display configuration banner <-- entrypoint.sh:5
│       ├── Show data directory & ports <-- entrypoint.sh:10
│       └── Launch privateness daemon <-- 7d
│           ├── -data-dir=.privateness/data <-- entrypoint.sh:19
│           ├── -web-interface-addr=0.0.0.0:6006 <-- entrypoint.sh:20
│           └── -rpc-interface-addr=0.0.0.0:6660 <-- entrypoint.sh:21
└── Docker Compose Integration
    └── Service starts after dependencies <-- docker-compose.ness.yml:74
        ├── emercoin-core (blockchain) <-- docker-compose.ness.yml:75
        ├── dns-reverse-proxy (naming) <-- docker-compose.ness.yml:76
        └── pyuheprng-privatenesstools (entropy) <-- docker-compose.ness.yml:77
```

**Key Locations**

- **7a – Clone Ness Blockchain Source**  
  `privateness/Dockerfile:18` – Clones `https://github.com/ness-network/ness.git`.

- **7b – Cross-Compile Blockchain Binary**  
  `privateness/Dockerfile:22` – Builds static Go binary with `GOOS/GOARCH` from buildx.

- **7c – Configure Health Check**  
  `privateness/Dockerfile:56` – Healthcheck uses `privateness-cli status`.

- **7d – Launch Blockchain Daemon**  
  `privateness/entrypoint.sh:18` – Starts Privateness node with data dir and web/RPC interfaces.

---

## 9. Trace 8 – IPFS Daemon Initialization with Auto-Configuration

**Title:** IPFS Daemon Initialization with Auto-Configuration  
**Entry:** `ipfs/entrypoint.sh`

```mermaid
flowchart TD
    A[entrypoint.sh] --> B[Check $IPFS_PATH/config\n(8a)]
    B --> C[ipfs init --profile=server\n(8b)]
    C --> D[Configure API/Gateway]
    D --> E[Enable experimental features\n(8c)]
    E --> F[Set StorageMax\n(8d)]
    F --> G[Configure GC period]
    G --> H[ipfs id]
    H --> I[Start ipfs daemon\n--migrate --enable-gc\n(8e)]
```

```text
IPFS Daemon Initialization Flow
├── Container Startup
│   └── entrypoint.sh execution <-- entrypoint.sh:1
│       ├── Check if initialized <-- 8a
│       │   └── test -f $IPFS_PATH/config
│       ├── First-time setup (if needed)
│       │   ├── ipfs init --profile=server <-- 8b
│       │   ├── Configure API/Gateway addresses <-- entrypoint.sh:15
│       │   ├── Enable experimental features <-- 8c
│       │   │   ├── FilestoreEnabled <-- entrypoint.sh:19
│       │   │   ├── UrlstoreEnabled <-- entrypoint.sh:20
│       │   │   └── P2pHttpProxy <-- entrypoint.sh:22
│       │   ├── Set storage limits <-- 8d
│       │   │   └── StorageMax=${IPFS_STORAGE_MAX}
│       │   └── Configure GC period <-- entrypoint.sh:36
│       ├── Display node info
│       │   └── ipfs id <-- entrypoint.sh:46
│       └── Start daemon <-- 8e
│           └── exec ipfs daemon --migrate --enable-gc
└── Docker healthcheck (periodic) <-- Dockerfile:60
    └── ipfs id || exit 1 <-- Dockerfile:61
```

**Key Locations**

- **8a – Check Repository Exists**  
  `ipfs/entrypoint.sh:10` – Determines if IPFS needs initialization.

- **8b – Initialize IPFS Repository**  
  `ipfs/entrypoint.sh:12` – `ipfs init --profile=server` for server profile.

- **8c – Enable Experimental Features**  
  `ipfs/entrypoint.sh:19` – Enables filestore, urlstore, and Libp2p stream mounting.

- **8d – Configure Storage Limits**  
  `ipfs/entrypoint.sh:33` – Sets `Datastore.StorageMax` from `IPFS_STORAGE_MAX`.

- **8e – Start IPFS Daemon**  
  `ipfs/entrypoint.sh:51` – Runs `ipfs daemon --migrate --enable-gc`.

---

## 10. Trace 9 – Portainer API-Based Stack Deployment

**Title:** Portainer API-Based Stack Deployment  
**Entry:** `portainer-deploy.sh`, `portainer-stack.yml`

```mermaid
flowchart TD
    A[portainer-deploy.sh] --> B[Check API status\n(9a)]
    B --> C[Query existing stacks\n(9b)]
    C -->|exists| D[Update stack\nPUT /api/stacks/{id}\n(9c)]
    C -->|missing| E[Create stack\nPOST /api/stacks\n(9d)]
    D --> F[Wait & verify deployment]
    E --> F
```

```text
Portainer API Stack Deployment Flow
├── portainer-deploy.sh script execution <-- portainer-deploy.sh:21
│   ├── Validate API connectivity <-- 9a
│   ├── Query for existing stack <-- 9b
│   ├── Decision: Stack exists? <-- portainer-deploy.sh:48
│   │   ├── YES: Update existing stack <-- portainer-deploy.sh:53
│   │   │   └── PUT /api/stacks/{id} <-- 9c
│   │   └── NO: Create new stack <-- portainer-deploy.sh:78
│   │       └── POST /api/stacks <-- 9d
│   └── Wait and verify deployment <-- portainer-deploy.sh:102
└── portainer-stack.yml configuration <-- portainer-stack.yml:6
    ├── Service definitions with labels <-- 9e
    ├── Volume definitions <-- portainer-stack.yml:217
    ├── Network configuration <-- portainer-stack.yml:234
    └── Health check specifications <-- portainer-stack.yml:17
```

**Key Locations**

- **9a – Validate Portainer Connection**  
  `portainer-deploy.sh:37` – Checks Portainer API `/api/status` with API key.

- **9b – Query Existing Stack**  
  `portainer-deploy.sh:44` – Searches for existing `privateness-network` stack.

- **9c – Update Existing Stack**  
  `portainer-deploy.sh:55` – `PUT /api/stacks/{id}` to update existing stack.

- **9d – Create New Stack**  
  `portainer-deploy.sh:80` – `POST /api/stacks` if stack doesn’t exist.

- **9e – Apply Access Control Labels**  
  `portainer-stack.yml:24` – Labels for team-based RBAC and service classification.

---

## 11. Trace 10 – Full Stack Service Dependencies and Health Checks

**Title:** Full Stack Service Dependencies and Health Checks  
**Entry:** `docker-compose.yml`

```mermaid
flowchart TB
    EMC[Emercoin Core\nfoundation]:::foundation
    YGG[Yggdrasil]:::network
    DNS[DNS Reverse Proxy]:::network
    I2P[I2P-Yggdrasil]:::network
    SKY[Skywire]:::network
    RNG[pyuheprng]:::service
    PNUM[privatenumer]:::service
    PRIV[Privateness Core]:::app
    PTOOLS[privatenesstools]:::app
    NET[ness-network bridge]:::infra

    EMC --> YGG
    EMC --> DNS
    EMC --> RNG
    EMC --> PRIV

    YGG --> I2P
    YGG --> DNS
    YGG --> SKY
    YGG --> PRIV

    RNG --> PNUM
    PRIV --> PTOOLS

    EMC --> NET
    YGG --> NET
    DNS --> NET
    SKY --> NET
    RNG --> NET
    PRIV --> NET
    PTOOLS --> NET
    PNUM --> NET

    classDef foundation fill=#1f2937,color=#fff;
    classDef network fill=#1d4ed8,color=#fff;
    classDef service fill=#0f766e,color=#fff;
    classDef app fill=#7c2d12,color=#fff;
    classDef infra fill=#4b5563,color=#fff;
```

```text
Full Stack Service Dependency Tree
├── Emercoin Core (Foundation Layer) <-- docker-compose.yml:4
│   └── healthcheck: kill -0 1 <-- 10a
│       ├── Yggdrasil (Mesh Network) <-- docker-compose.yml:22
│       │   └── depends_on: service_healthy <-- 10b
│       │       ├── I2P-Yggdrasil (Anonymity) <-- docker-compose.yml:54
│       │       │   └── depends_on: yggdrasil <-- 10d
│       │       └── DNS Reverse Proxy <-- docker-compose.yml:36
│       │           └── depends_on: emc + ygg <-- 10c
│       ├── Skywire (MPLS Routing) <-- docker-compose.yml:75
│       │   └── depends_on: service_healthy <-- docker-compose.yml:85
│       └── pyuheprng (Entropy Service) <-- docker-compose.yml:133
│           └── depends_on: service_healthy <-- docker-compose.yml:141
│               └── privatenumer <-- docker-compose.yml:143
│                   └── depends_on: pyuheprng <-- docker-compose.yml:150
├── Privateness Core Application <-- docker-compose.yml:121
│   └── depends_on: emc + ygg + dns <-- 10e
│       └── privatenesstools <-- docker-compose.yml:152
│           └── depends_on: privateness + emc <-- docker-compose.yml:159
└── ness-network Bridge <-- docker-compose.yml:169
    └── driver: bridge <-- 10f
```

**Key Locations**

- **10a – Emercoin Foundation Health**  
  `docker-compose.yml:14` – Base healthcheck that gates all dependent services.

- **10b – Yggdrasil Waits for Blockchain**  
  `docker-compose.yml:33` – Mesh network depends on a healthy Emercoin core.

- **10c – DNS Proxy Multi-Dependency**  
  `docker-compose.yml:50` – DNS reverse proxy requires Emercoin and Yggdrasil.

- **10d – I2P Routes Through Yggdrasil**  
  `docker-compose.yml:73` – Anonymous overlay built on Yggdrasil mesh.

- **10e – Privateness Core Dependencies**  
  `docker-compose.yml:128` – Application layer depends on blockchain, mesh, and DNS.

- **10f – Shared Bridge Network**  
  `docker-compose.yml:170` – All services share the `ness-network` Docker bridge.

---

## 12. How to Use This Codemap

- **Architecture docs:** Link this file from `ARCHITECTURE.md`, `NETWORK-ARCHITECTURE.md`, or `SERVICES.md`.
- **Onboarding:** Use the trace sections to walk new contributors through deployments.
- **Debugging:** Start with Trace 1/4 (deploy + menu) and follow into specific services (Traces 3, 5, 7, 8).
