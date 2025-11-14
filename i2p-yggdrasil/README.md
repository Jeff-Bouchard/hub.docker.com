# I2P with Yggdrasil Routing

This container runs I2P (Invisible Internet Project) with all traffic routed through the Yggdrasil mesh network.

## How It Works

1. **Yggdrasil** starts first and creates a TUN interface with IPv6 addressing
2. **I2P** is configured to bind to the Yggdrasil IPv6 address
3. All I2P traffic flows through the encrypted Yggdrasil mesh network
4. Provides **double-layer privacy**: Yggdrasil mesh + I2P anonymity

## Architecture

```
I2P Traffic → Yggdrasil IPv6 → Yggdrasil Mesh Network → Internet
```

## Configuration

### Yggdrasil Settings
- **Interface**: Auto-detected TUN device
- **Listen Port**: 9001
- **Admin Port**: 9002
- **Multicast**: Enabled for peer discovery

### I2P Settings
- **NTCP Host**: Yggdrasil IPv6 address
- **UDP Host**: Yggdrasil IPv6 address
- **Auto-IP**: Disabled (uses Yggdrasil address)
- **IPv6**: Preferred

## Ports

- **7657**: I2P Router Console (HTTP)
- **4444**: I2P HTTP Proxy
- **6668**: I2P IRC Tunnel
- **9001**: Yggdrasil Peer Connections
- **9002**: Yggdrasil Admin API

## Requirements

- `NET_ADMIN` capability for TUN device
- `/dev/net/tun` device access
- IPv6 forwarding enabled

## Usage

### Docker Run
```bash
docker run -d \
  --name i2p-yggdrasil \
  --cap-add=NET_ADMIN \
  --device /dev/net/tun \
  --sysctl net.ipv6.conf.all.forwarding=1 \
  -p 7657:7657 \
  -p 4444:4444 \
  -p 6668:6668 \
  -p 9001:9001 \
  -p 9002:9002 \
  -v i2p-data:/var/lib/i2p \
  ness-network/i2p-yggdrasil
```

### Docker Compose
```yaml
i2p-yggdrasil:
  image: ness-network/i2p-yggdrasil
  cap_add:
    - NET_ADMIN
  devices:
    - /dev/net/tun
  sysctls:
    - net.ipv6.conf.all.forwarding=1
  ports:
    - "7657:7657"
    - "4444:4444"
    - "6668:6668"
    - "9001:9001"
    - "9002:9002"
  volumes:
    - i2p-data:/var/lib/i2p
```

## Access

- **I2P Console**: http://localhost:7657
- **HTTP Proxy**: Configure browser to use `localhost:4444`
- **Yggdrasil Admin**: `yggdrasilctl -endpoint=localhost:9002 getPeers`

## Benefits

1. **Enhanced Privacy**: Double encryption (Yggdrasil + I2P)
2. **Mesh Routing**: Traffic routes through decentralized mesh
3. **IPv6 Native**: Modern networking stack
4. **Peer Discovery**: Automatic mesh network joining
5. **Censorship Resistant**: No central points of failure

## Verification

Check Yggdrasil routing:
```bash
docker exec i2p-yggdrasil ip -6 addr show tun0
docker exec i2p-yggdrasil yggdrasilctl -endpoint=localhost:9002 getSelf
```

Check I2P configuration:
```bash
docker exec i2p-yggdrasil cat /var/lib/i2p/config/router.config
```
