#!/bin/bash

set -e

echo "=========================================="
echo "Ness Blockchain Node"
echo "=========================================="

# Create config directory if it doesn't exist
mkdir -p /data/ness

# Create ness.conf if it doesn't exist
if [ ! -f /data/ness/ness.conf ]; then
    echo "Creating ness.conf..."
    cat > /data/ness/ness.conf <<EOF
# Ness Blockchain Configuration

# RPC Settings
rpcuser=${NESS_RPC_USER:-nessuser}
rpcpassword=${NESS_RPC_PASS:-nesspassword}
rpcallowip=0.0.0.0/0
rpcbind=0.0.0.0
rpcport=6660

# Network Settings
listen=1
port=6006
maxconnections=${NESS_MAX_CONNECTIONS:-125}

# Blockchain Settings
txindex=1
addressindex=1
timestampindex=1
spentindex=1

# Logging
debug=${NESS_DEBUG:-0}
printtoconsole=1

# Performance
dbcache=${NESS_DB_CACHE:-450}
maxmempool=${NESS_MAX_MEMPOOL:-300}
EOF
    echo "✓ ness.conf created"
fi

echo "=========================================="
echo "Configuration:"
echo "  Data directory: /data/ness"
echo "  RPC port: 6660"
echo "  P2P port: 6006"
echo "  RPC user: ${NESS_RPC_USER:-nessuser}"
echo "=========================================="

# Start Ness daemon
echo "Starting Ness blockchain node..."
exec nessd -datadir=/data/ness -conf=/data/ness/ness.conf "$@"
