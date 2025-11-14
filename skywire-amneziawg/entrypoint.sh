#!/bin/bash

set -e

echo "Starting AmneziaWG Access Layer → Skywire Mesh..."

# Generate AmneziaWG config if not exists
if [ ! -f /etc/amneziawg/awg0.conf ]; then
    echo "Generating AmneziaWG configuration..."
    
    PRIVATE_KEY=$(awg genkey)
    PUBLIC_KEY=$(echo "$PRIVATE_KEY" | awg pubkey)
    
    # Stealth obfuscation parameters
    JC=$(shuf -i 3-10 -n 1)
    JMIN=$(shuf -i 50-1000 -n 1)
    JMAX=$(shuf -i 1000-2000 -n 1)
    S1=$(shuf -i 20-100 -n 1)
    S2=$(shuf -i 20-100 -n 1)
    H1=$(shuf -i 1-4294967295 -n 1)
    H2=$(shuf -i 1-4294967295 -n 1)
    H3=$(shuf -i 1-4294967295 -n 1)
    H4=$(shuf -i 1-4294967295 -n 1)
    
    cat > /etc/amneziawg/awg0.conf <<EOF
[Interface]
PrivateKey = $PRIVATE_KEY
Address = 10.8.0.1/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i awg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i awg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
Jc = $JC
Jmin = $JMIN
Jmax = $JMAX
S1 = $S1
S2 = $S2
H1 = $H1
H2 = $H2
H3 = $H3
H4 = $H4
EOF

    echo "=========================================="
    echo "AmneziaWG Access Layer Configuration"
    echo "=========================================="
    echo "Public Key: $PUBLIC_KEY"
    echo "Network: 10.8.0.0/24"
    echo "Obfuscation: Jc=$JC Jmin=$JMIN Jmax=$JMAX"
    echo "=========================================="
fi

# Load kernel module
modprobe amneziawg || echo "Warning: amneziawg module not loaded"

# Start AmneziaWG access layer
echo "Starting AmneziaWG access layer..."
awg-quick up awg0

# Wait for interface
sleep 3

# Get AmneziaWG interface details
AWG_IP=$(ip -4 addr show awg0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
echo "AmneziaWG Access Layer IP: $AWG_IP"

# Configure routing: All traffic from AmneziaWG → Skywire
echo "Configuring routing: AmneziaWG → Skywire mesh..."

# Set up routing table for Skywire
ip route add default via $AWG_IP dev awg0 table 100 || true
ip rule add from 10.8.0.0/24 table 100 || true

# Configure Skywire to bind to AmneziaWG interface
export SKYWIRE_INTERFACE=awg0
export SKYWIRE_BIND_ADDR=$AWG_IP

# Start Skywire visor (all traffic comes through AmneziaWG)
echo "Starting Skywire mesh node..."
echo "Traffic flow: Client → AmneziaWG (stealth) → Skywire (mesh) → Internet"

exec skywire-visor -i awg0
