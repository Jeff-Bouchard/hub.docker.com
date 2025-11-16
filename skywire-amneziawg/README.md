# Skywire-AmneziaWG Access Layer

[Français](README-FR.md)

AmneziaWG provides the **access layer** with stealth VPN capabilities, connecting clients directly to the Skywire mesh network.

## Architecture (experimental)

```text
Client Device (TCP/IP)
    ↓
AmneziaWG Access Layer (Obfuscated UDP)
    ↓ [Protocol Transition: UDP → MPLS]
Skywire Mesh Network (MPLS Label Switching - NOT TCP/IP)
    ↓ [Protocol Transition: MPLS → IPv6]
Yggdrasil Overlay (Encrypted IPv6 Mesh)
    ↓ [Protocol Transition: IPv6 → Garlic Routing]
I2P Anonymous Network (Layered Encryption)
    ↓
Privateness Services / Internet
```

### How this aims to hinder tracking

1. **Protocol Hopping**: TCP/IP → UDP → MPLS → IPv6 → Garlic Routing
2. **Reduced IP visibility in core**: Skywire MPLS uses label switching in the mesh core instead of ordinary IP routing
3. **Network Hopping**: Dynamic path selection, changes per packet
4. **Encryption Layers**: 5+ layers of encryption
5. **Decentralized**: No single central server for all traffic

These design choices are intended to make network activity harder to analyse across all layers at once. There are **no formal anonymity proofs**, and the actual privacy properties depend on how the system is deployed and used.

## Traffic Flow

1. **Client connects** to AmneziaWG (stealth VPN with obfuscation)
2. **AmneziaWG routes** all traffic to Skywire mesh interface
3. **Skywire distributes** traffic across decentralized mesh nodes
4. **Exit via mesh** to destination or privateness.network services

## Key Features

### AmneziaWG Access Layer

- **Stealth VPN**: DPI-resistant obfuscation
- **Client gateway**: 10.8.0.0/24 network
- **Auto-configuration**: Generates obfuscation params
- **NAT traversal**: Works behind firewalls

### Skywire Mesh Integration

- **Direct binding**: Skywire binds to AmneziaWG interface
- **Mesh routing**: Decentralized path selection
- **Load balancing**: Distributed across mesh nodes
- **Failover**: Automatic rerouting on node failure

## Configuration

### Server Setup

```bash
docker run -d \
  --name skywire-amneziawg \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  --device /dev/net/tun \
  --sysctl net.ipv4.ip_forward=1 \
  -p 8001:8000 \
  -p 51821:51820/udp \
  ness-network/skywire-amneziawg
```

### Get Server Public Key

```bash
docker exec skywire-amneziawg cat /etc/amneziawg/awg0.conf | grep -A 20 "Interface"
```

### Client Configuration

Create client config with **same obfuscation parameters**:

```ini
[Interface]
PrivateKey = <client_private_key>
Address = 10.8.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = <server_public_key>
Endpoint = <server_ip>:51821
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25

# CRITICAL: Must match server obfuscation
Jc = <server_Jc>
Jmin = <server_Jmin>
Jmax = <server_Jmax>
S1 = <server_S1>
S2 = <server_S2>
H1 = <server_H1>
H2 = <server_H2>
H3 = <server_H3>
H4 = <server_H4>
```

## Use Cases

### 1. Censorship Bypass

- Client in restricted country
- AmneziaWG bypasses DPI/firewall
- Skywire provides decentralized routing
- No single point of censorship

### 2. Privacy-First Access

- Client traffic obfuscated (AmneziaWG)
- Routing decentralized (Skywire)
- No central VPN provider
- Mesh network anonymity

### 3. Corporate Network Access

- Bypass corporate DPI
- Access privateness.network services
- Decentralized routing prevents blocking
- Stealth mode hides VPN usage

### 4. IoT Device Gateway

- IoT devices connect via AmneziaWG
- Traffic routed through Skywire mesh
- Decentralized IoT network
- No cloud dependency

## Monitoring

### Check AmneziaWG Status

```bash
docker exec skywire-amneziawg awg show awg0
```

### Check Skywire Peers

```bash
docker exec skywire-amneziawg skywire-cli visor info
```

### View Routing Table

```bash
docker exec skywire-amneziawg ip route show table 100
```

### Monitor Traffic

```bash
docker exec skywire-amneziawg iftop -i awg0
```

## Security

### Access Layer Protection

- **Obfuscated handshake**: Undetectable by DPI
- **Random packet timing**: Prevents pattern analysis
- **Header randomization**: Looks like random data
- **Size obfuscation**: Variable packet sizes

### Mesh Layer Security

- **Encrypted routing**: End-to-end encryption
- **No central authority**: Decentralized trust
- **Multi-path routing**: Traffic split across nodes
- **Onion-like routing**: Layered encryption

## Performance

- **Latency**: +10-30ms (AmneziaWG) + mesh routing
- **Throughput**: Near-native WireGuard speeds
- **Overhead**: ~5-10% for obfuscation
- **Scalability**: Mesh grows with nodes

## Troubleshooting

### AmneziaWG not starting

```bash
# Check kernel module
docker exec skywire-amneziawg lsmod | grep amneziawg

# Check interface
docker exec skywire-amneziawg ip link show awg0
```

### Skywire not routing

```bash
# Check Skywire status
docker exec skywire-amneziawg skywire-cli visor info

# Check routing
docker exec skywire-amneziawg ip route
```

### Client can't connect

1. Verify obfuscation params match server
2. Check firewall allows UDP 51821
3. Verify server public key is correct
4. Check client AllowedIPs includes 0.0.0.0/0

## Integration with Privateness Network

This access layer integrates with:

- **Emercoin**: Blockchain-based service discovery
- **Yggdrasil**: IPv6 mesh overlay
- **I2P**: Anonymous network layer
- **DNS Proxy**: Decentralized DNS resolution

Complete decentralized stack from access to application layer.

## References / Sources

- **AmneziaWG**  
  Protocol and implementation details for the obfuscated WireGuard variant used as the access layer:  
  <https://docs.amnezia.org/documentation/amnezia-wg/>

- **WireGuard**  
  Baseline VPN protocol and cryptographic design underpinning AmneziaWG:  
  <https://www.wireguard.com/protocol/>

- **Skywire**  
  Skywire node implementation and overview of the MPLS-like mesh routing used as the core mesh:  
  <https://github.com/skycoin/skywire>

- **Yggdrasil Network**  
  Encrypted IPv6 overlay network used as the underlying mesh:  
  <https://yggdrasil-network.github.io/>

- **I2P**  
  Technical introduction to I2P and garlic routing:  
  <https://geti2p.net/en/docs/how/tech-intro>

- **Central reference list**  
  See `SOURCES.md` at the repository root for a consolidated list of external documents referenced across the Privateness Network documentation.

