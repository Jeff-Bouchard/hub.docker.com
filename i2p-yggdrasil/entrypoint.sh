#!/bin/bash

set -e

# Generate Yggdrasil config with routing enabled
cat > /etc/yggdrasil.conf <<EOF
{
  "Listen": ["tcp://[::]:9001"],
  "AdminListen": "tcp://localhost:9002",
  "Peers": [],
  "InterfacePeers": {},
  "AllowedPublicKeys": [],
  "MulticastInterfaces": [
    {
      "Regex": ".*",
      "Beacon": true,
      "Listen": true,
      "Port": 0
    }
  ],
  "IfName": "auto",
  "IfMTU": 65535,
  "NodeInfoPrivacy": false,
  "NodeInfo": {
    "name": "i2pd-yggdrasil-node"
  }
}
EOF

# Start Yggdrasil with config
yggdrasil -useconffile /etc/yggdrasil.conf &
YGGDRASIL_PID=$!

# Wait for Yggdrasil to initialize and get interface
sleep 5

# Get Yggdrasil interface name
YGG_IFACE=$(ip -o link show | grep -oP 'tun\d+' | head -n1)
if [ -z "$YGG_IFACE" ]; then
    YGG_IFACE="tun0"
fi

echo "Yggdrasil interface: $YGG_IFACE"

# Get Yggdrasil IPv6 address (Yggdrasil addresses start with '2')
YGG_ADDR=$(ip -6 addr show "$YGG_IFACE" | grep -oP '(?<=inet6 )[0-9a-f:]+' | grep '^2' | head -n1)
echo "Yggdrasil IPv6: $YGG_ADDR"

# Configure i2pd for Yggdrasil-only mode
mkdir -p /etc/i2pd

cat > /etc/i2pd/i2pd.conf <<EOF
daemon=false
ipv4=false
ipv6=false
ssu=false
ntcp2.enabled=false
ssu2.enabled=false
meshnets.yggdrasil=true
meshnets.yggaddress=$YGG_ADDR
EOF

echo "i2pd configured for Yggdrasil-only mode"
echo "Yggdrasil Address: $YGG_ADDR"

trap 'kill "$YGGDRASIL_PID" || true' EXIT

exec i2pd --conf=/etc/i2pd/i2pd.conf
