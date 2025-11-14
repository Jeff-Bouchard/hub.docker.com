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
    "name": "i2p-yggdrasil-node"
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

# Get Yggdrasil IPv6 address
YGG_ADDR=$(ip -6 addr show $YGG_IFACE | grep -oP '(?<=inet6 )[0-9a-f:]+' | grep '^2' | head -n1)
echo "Yggdrasil IPv6: $YGG_ADDR"

# Configure I2P to route through Yggdrasil
mkdir -p /var/lib/i2p/config

# Set I2P to bind to Yggdrasil interface
cat > /var/lib/i2p/config/router.config <<EOF
i2np.ntcp.hostname=$YGG_ADDR
i2np.ntcp.autoip=false
i2np.udp.host=$YGG_ADDR
i2np.udp.autoip=false
router.networkDatabase.flat=true
EOF

# Configure I2P wrapper to use IPv6
cat > /var/lib/i2p/config/wrapper.config <<EOF
wrapper.java.additional.1=-Djava.net.preferIPv6Addresses=true
wrapper.java.additional.2=-Djava.net.preferIPv4Stack=false
EOF

echo "I2P configured to route through Yggdrasil mesh network"
echo "Yggdrasil Address: $YGG_ADDR"

# Start I2P
exec i2prouter console
