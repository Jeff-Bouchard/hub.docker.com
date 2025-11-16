# Privateness Network - Docker Hub Repositories

Hypersimple Docker images for Umbrel app store integration.

[Français](README-FR.md)

## ⚠️ CRITICAL SECURITY WARNING

**This system will BLOCK rather than perform an unsecure cryptographic operation.**

Entropy deprivation possibility is **ELIMINATED** by our `pyuheprng` service feeding `/dev/random` directly, mixed with:

- **RC4OK from Emercoin Core** (blockchain-derived randomness)
- **Original hardware bits** (direct hardware entropy)
- **UHEP Protocol** (Universal Hardware Entropy Protocol)

**For non-Windows machines**: GRUB configuration **MUST** disable `/dev/urandom` in production.

See [CRYPTOGRAPHIC-SECURITY.md](CRYPTOGRAPHIC-SECURITY.md) for complete details.

## ⚠️ BINARY EQUIVALENCE REQUIREMENT

**All nodes MUST be binary equivalent, otherwise it's bullshit.**

True decentralization requires every node to run **identical binaries** that can be verified. Without binary equivalence:

- Cannot verify node integrity
- Cannot detect compromised nodes
- Cannot trust network consensus
- **Decentralization is fake**

See [REPRODUCIBLE-BUILDS.md](REPRODUCIBLE-BUILDS.md) for implementation details.

## Documentation

### Core Documentation

- **[SERVICES.md](SERVICES.md)** - Complete service list, dependencies, ports, use cases
- **[DEPLOY.md](DEPLOY.md)** - Docker Hub deployment instructions (nessnetwork)
- **[PORTAINER.md](PORTAINER.md)** - Portainer deployment guide, stack management

### Security Architecture

- **[CRYPTOGRAPHIC-SECURITY.md](CRYPTOGRAPHIC-SECURITY.md)** - Entropy architecture, pyuheprng, GRUB configuration
- **[REPRODUCIBLE-BUILDS.md](REPRODUCIBLE-BUILDS.md)** - Binary equivalence, deterministic builds, verification
- **[INCENTIVE-SECURITY.md](INCENTIVE-SECURITY.md)** - Trustless payment to hostile nodes, game theory

### Network Architecture Overview

- **[NETWORK-ARCHITECTURE.md](NETWORK-ARCHITECTURE.md)** - Protocol hopping, MPLS routing, untraceability
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Multi-architecture build details

### Service-Specific

- **[ipfs/README.md](ipfs/README.md)** - IPFS daemon, Emercoin integration
- **[pyuheprng/README.md](pyuheprng/README.md)** - Entropy service documentation
- **[amneziawg/README.md](amneziawg/README.md)** - Stealth VPN configuration
- **[skywire-amneziawg/README.md](skywire-amneziawg/README.md)** - Access layer integration
- **[CONCEPT.md](CONCEPT.md)** - Perception/Reality architecture notes

## Perception → Reality Concept

1. **EmerDNS + EmerNVS** (`dpo:PrivateNESS.Network`, `ness:dns-reverse-proxy-config`) are the only sources of truth for identities, bootstrap info, DNS policy, and service URLs. Anything not reachable from those records is treated as untrusted by default.
2. **DNS enforcement** happens through `dns-reverse-proxy` on `127.0.0.1:53/udp`, which uses EmerDNS (127.0.0.1:5335) for owned TLDs and optionally forwards other TLDs only through trusted upstreams.
3. **Clearnet existence toggle** reverses or restores access to non-Emer TLDs; OFF means unknown names are NXDOMAIN/blackholed and the node only perceives EmerDNS, ON adds controlled clearnet forwarders.
4. **Transport graph**: WG-in → Skywire → Yggdrasil → (optional i2pd Ygg-only) → WG/XRAY-out → clearnet. All visor-to-visor traffic stays on Ygg; optional i2p runs strictly inside Ygg-only mode.
5. **Identity-to-config pipeline**: an external orchestrator reads Emercoin entries, derives `wg.conf`, `xray config.json`, Skywire/Ygg config, DNS policy, and writes them into each container, which never contacts untrusted infrastructure directly.
6. **Amnezia exits** are the only clearnet-visible surfaces. The new `amnezia-exit` image builds `amnezia-xray-core`, installs `amneziawg-tools`, and expects `wg.conf` + `config.json` from these EmerDNS identities.

## Images

### 1. emercoin-core

Emercoin blockchain node

```bash
docker build -t nessnetwork/emercoin-core ./emercoin-core
docker run -v emercoin-data:/data -p 6661:6661 nessnetwork/emercoin-core
```

### 2. ness-blockchain

**Privateness native blockchain** (github.com/ness-network/ness)

```bash
docker build -t nessnetwork/ness-blockchain ./ness-blockchain
docker run -v ness-data:/data/ness -p 6006:6006 -p 6660:6660 nessnetwork/ness-blockchain
```

Dual-chain architecture with Emercoin for enhanced security.

### 3. privateness

Privateness network core

```bash
docker build -t ness-network/privateness ./privateness
docker run -p 6006:6006 -p 6660:6660 ness-network/privateness
```

### 3. skywire

Skycoin Skywire mesh network

```bash
docker build -t ness-network/skywire ./skywire
docker run -p 8000:8000 ness-network/skywire
```

### 4. pyuheprng

Cryptographic Entropy Service - Feeds `/dev/random` with RC4OK + Hardware + UHEP

```bash
docker build -t ness-network/pyuheprng ./pyuheprng
docker run --privileged --device /dev/random -v /dev:/dev \
  -p 5000:5000 \
  -e EMERCOIN_HOST=emercoin-core \
  -e EMERCOIN_PORT=6662 \
  ness-network/pyuheprng
```

CRITICAL: Requires privileged mode to feed `/dev/random` directly. This service eliminates entropy deprivation and ensures all cryptographic operations use secure randomness.

### 5. privatenumer

Private number generation service

```bash
docker build -t ness-network/privatenumer ./privatenumer
docker run -p 3000:3000 ness-network/privatenumer
```

### 6. privatenesstools

Privateness network tools

```bash
docker build -t ness-network/privatenesstools ./privatenesstools
docker run -p 8888:8888 ness-network/privatenesstools
```

### 7. yggdrasil

Yggdrasil mesh network

```bash
docker build -t ness-network/yggdrasil ./yggdrasil
docker run -p 9001:9001 ness-network/yggdrasil
```

### 8. i2p-yggdrasil

I2P routing through Yggdrasil mesh network (IPv6)

```bash
docker build -t ness-network/i2p-yggdrasil ./i2p-yggdrasil
docker run --cap-add=NET_ADMIN --device /dev/net/tun \
  -p 7657:7657 -p 4444:4444 -p 6668:6668 -p 9001:9001 -p 9002:9002 \
  ness-network/i2p-yggdrasil
```

### 9. dns-reverse-proxy

DNS reverse proxy

```bash
docker build -t ness-network/dns-reverse-proxy ./dns-reverse-proxy
docker run -p 53:53/udp -p 53:53/tcp -p 8053:8053 ness-network/dns-reverse-proxy
```

### 10. ipfs

IPFS Daemon - Decentralized content-addressed storage

```bash
docker build -t nessnetwork/ipfs ./ipfs
docker run -d \
  -v ipfs-data:/data/ipfs \
  -p 4001:4001 -p 5001:5001 -p 8082:8080 -p 8081:8081 \
  nessnetwork/ipfs
```

Integrates with Emercoin for decentralized naming (IPFS hashes stored in blockchain).

### 11. amneziawg

AmneziaWG (stealth WireGuard with obfuscation)

```bash
docker build -t nessnetwork/amneziawg ./amneziawg
docker run --cap-add=NET_ADMIN --cap-add=SYS_MODULE --device /dev/net/tun \
  -p 51820:51820/udp -v awg-config:/etc/amneziawg \
  nessnetwork/amneziawg
```

### 12. skywire-amneziawg

Access Layer: AmneziaWG stealth VPN → Skywire mesh routing

```bash
docker build -t ness-network/skywire-amneziawg ./skywire-amneziawg
docker run --cap-add=NET_ADMIN --cap-add=SYS_MODULE --device /dev/net/tun \
  -p 8001:8000 -p 51821:51820/udp \
  ness-network/skywire-amneziawg
```

Clients connect via AmneziaWG, traffic routes through Skywire mesh.

### 13. ness-unified

All services combined in one container

```bash
docker build -t ness-network/ness-unified ./ness-unified
docker run -v ness-data:/data \
  -p 6661:6661 -p 6662:6662 -p 8775:8775 \
  -p 6006:6006 -p 6660:6660 \
  -p 9001:9001 -p 7657:7657 -p 4444:4444 -p 6668:6668 \
  -p 8000:8000 -p 53:53/udp -p 53:53/tcp -p 8053:8053 \
  -p 5000:5000 -p 3000:3000 -p 8888:8888 \
  ness-network/ness-unified
```

## Deployment Options

### Portainer (Recommended for Production)

```bash
# Deploy via Portainer UI
# Stacks → Add Stack → Upload portainer-stack.yml
```

See [PORTAINER.md](PORTAINER.md) for complete guide.

### Quick Deploy - Ness Essential Stack

**Minimal production-ready stack** (recommended for Pi4 and resource-constrained devices):

```bash
./deploy-ness.sh
```

This deploys:

- **Emercoin Core**: Blockchain + RC4OK entropy source
- **pyuheprng + privatenesstools**: Combined entropy + tools (saves resources)
- **DNS Reverse Proxy**: Decentralized DNS
- **Privateness**: Core application

Or manually:

```bash
docker-compose -f docker-compose.ness.yml up -d
```

### Docker Compose

#### Full Stack with Dependencies

```bash
docker-compose up -d
```

#### Minimal Stack (Core Services Only)

```bash
docker-compose -f docker-compose.minimal.yml up -d
```

### Service Startup Order

1. **emercoin-core** (starts first, healthcheck required)
2. **yggdrasil** (waits for emercoin)
3. **dns-reverse-proxy** (waits for emercoin + yggdrasil)
4. **skywire** (waits for emercoin)
5. **pyuheprng** (waits for emercoin)
6. **ipfs** (independent, can start anytime)
7. **i2p-yggdrasil** (waits for yggdrasil)
8. **privatenumer** (waits for pyuheprng)
9. **privateness** (waits for emercoin + yggdrasil + dns)
10. **privatenesstools** (waits for privateness + emercoin)

## Network Architecture

**Untraceable Protocol Hopping**: See [NETWORK-ARCHITECTURE.md](NETWORK-ARCHITECTURE.md)

Traffic flow: `AmneziaWG (obfuscated) → Skywire (MPLS) → Yggdrasil (IPv6) → I2P (garlic) → Blockchain DNS`

- **No IP routing in core**: Skywire uses MPLS label switching
- **5+ encryption layers**: Each protocol adds encryption
- **Dynamic path selection**: Routes change per packet
- **Impossible to trace**: Protocol hopping defeats all tracking

## Multi-Architecture Support

All images support:

- **linux/amd64** (x86_64)
- **linux/arm64** (aarch64)
- **linux/arm/v7** (armhf)

### Build Multi-Arch Images

```bash
./build-multiarch.sh
```

## Push to Docker Hub

### Single Architecture

```bash
docker login
./build-all.sh
./push-all.sh
```

### Multi-Architecture (Recommended)

```bash
docker login
./build-multiarch.sh
