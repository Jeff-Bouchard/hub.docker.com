# Privateness Network - Docker Hub Repositories

Hypersimple Docker images for Umbrel app store integration.

## Images

### 1. emercoin-core
Emercoin blockchain node

```bash
docker build -t ness-network/emercoin-core ./emercoin-core
docker run -v emercoin-data:/data -p 6661:6661 ness-network/emercoin-core
```

### 2. privateness
Privateness network core

```bash
docker build -t ness-network/privateness ./privateness
docker run -p 8080:8080 ness-network/privateness
```

### 3. skywire
Skycoin Skywire mesh network

```bash
docker build -t ness-network/skywire ./skywire
docker run -p 8000:8000 ness-network/skywire
```

### 4. pyuheprng
Python UHEP RNG service

```bash
docker build -t ness-network/pyuheprng ./pyuheprng
docker run -p 5000:5000 ness-network/pyuheprng
```

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

### 10. amneziawg
AmneziaWG (stealth WireGuard with obfuscation)

```bash
docker build -t ness-network/amneziawg ./amneziawg
docker run --cap-add=NET_ADMIN --cap-add=SYS_MODULE --device /dev/net/tun \
  -p 51820:51820/udp -v awg-config:/etc/amneziawg \
  ness-network/amneziawg
```

### 11. skywire-amneziawg
**Access Layer**: AmneziaWG stealth VPN → Skywire mesh routing
```bash
docker build -t ness-network/skywire-amneziawg ./skywire-amneziawg
docker run --cap-add=NET_ADMIN --cap-add=SYS_MODULE --device /dev/net/tun \
  -p 8001:8000 -p 51821:51820/udp \
  ness-network/skywire-amneziawg
```
Clients connect via AmneziaWG, traffic routes through Skywire mesh.

### 12. ness-unified
**All services combined in one container**

```bash
docker build -t ness-network/ness-unified ./ness-unified
docker run -v ness-data:/data \
  -p 6661:6661 -p 6662:6662 -p 8775:8775 \
  -p 9001:9001 -p 7657:7657 -p 4444:4444 -p 6668:6668 \
  -p 8000:8000 -p 53:53/udp -p 53:53/tcp -p 8053:8053 \
  -p 8080:8080 -p 5000:5000 -p 3000:3000 -p 8888:8888 \
  ness-network/ness-unified
```

## Deployment Options

### Portainer (Recommended for Production)

```bash
# Deploy via Portainer UI
# Stacks → Add Stack → Upload portainer-stack.yml
```

See [PORTAINER.md](PORTAINER.md) for complete guide.

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
6. **i2p-yggdrasil** (waits for yggdrasil)
7. **privatenumer** (waits for pyuheprng)
8. **privateness** (waits for emercoin + yggdrasil + dns)
9. **privatenesstools** (waits for privateness + emercoin)

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
