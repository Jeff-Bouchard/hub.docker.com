#!/bin/bash

set -e

# Generate AmneziaWG config if not exists
if [ ! -f /etc/amneziawg/awg0.conf ]; then
    echo "Generating AmneziaWG configuration..."
    
    # Generate private and public keys
    PRIVATE_KEY=$(awg genkey)
    PUBLIC_KEY=$(echo "$PRIVATE_KEY" | awg pubkey)
    
    # Generate obfuscation parameters (AmneziaWG stealth features)
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
# AmneziaWG obfuscation parameters
Jc = $JC
Jmin = $JMIN
Jmax = $JMAX
S1 = $S1
S2 = $S2
H1 = $H1
H2 = $H2
H3 = $H3
H4 = $H4

# Peers can be added here
# [Peer]
# PublicKey = <peer_public_key>
# AllowedIPs = 10.8.0.2/32
EOF

    echo "AmneziaWG Configuration Generated:"
    echo "Public Key: $PUBLIC_KEY"
    echo "Obfuscation: Jc=$JC Jmin=$JMIN Jmax=$JMAX S1=$S1 S2=$S2"
    echo "Config saved to /etc/amneziawg/awg0.conf"
fi

# Load kernel module
modprobe amneziawg || echo "Warning: Could not load amneziawg module (may need privileged mode)"

# Start AmneziaWG
echo "Starting AmneziaWG interface awg0..."
awg-quick up awg0

# Keep container running
tail -f /dev/null
