# AmneziaWG - Stealth WireGuard VPN

AmneziaWG is a modified WireGuard protocol with advanced obfuscation to bypass DPI (Deep Packet Inspection) and censorship.

## Features

- **Stealth Mode**: Obfuscates WireGuard traffic to look like random data
- **DPI Bypass**: Evades deep packet inspection systems
- **Junk Packets**: Adds random junk packets (Jc, Jmin, Jmax)
- **Header Obfuscation**: Randomizes packet headers (H1-H4)
- **Size Obfuscation**: Randomizes packet sizes (S1, S2)
- **WireGuard Compatible**: Based on WireGuard protocol

## Obfuscation Parameters

- **Jc**: Junk packet count (3-10)
- **Jmin**: Minimum junk size (50-1000 bytes)
- **Jmax**: Maximum junk size (1000-2000 bytes)
- **S1, S2**: Packet size randomization (20-100 bytes)
- **H1-H4**: Header obfuscation values

## Usage

### Generate Config
```bash
docker run --rm ness-network/amneziawg cat /etc/amneziawg/awg0.conf
```

### Run Server
```bash
docker run -d \
  --name amneziawg \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  --device /dev/net/tun \
  -p 51820:51820/udp \
  -v awg-config:/etc/amneziawg \
  ness-network/amneziawg
```

### Add Peer
Edit `/etc/amneziawg/awg0.conf`:
```ini
[Peer]
PublicKey = <peer_public_key>
AllowedIPs = 10.8.0.2/32
```

Restart container:
```bash
docker restart amneziawg
```

## Client Configuration

Generate client config with same obfuscation parameters:
```ini
[Interface]
PrivateKey = <client_private_key>
Address = 10.8.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = <server_public_key>
Endpoint = <server_ip>:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
# Must match server obfuscation
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

## Benefits vs Standard WireGuard

1. **Censorship Resistant**: Bypasses GFW, DPI systems
2. **Undetectable**: Traffic looks random, not VPN
3. **Same Performance**: Minimal overhead vs WireGuard
4. **Compatible**: Works with WireGuard clients (with obfuscation support)

## Use Cases

- Bypass censorship in restrictive countries
- Evade corporate DPI/firewall
- Hide VPN usage from ISP
- Combine with Skywire for mesh routing
