#!/bin/bash

set -e

echo "=========================================="
echo "Privateness Blockchain Node"
echo "=========================================="

# Create data directory if it doesn't exist
mkdir -p /data/ness/.privateness

echo "=========================================="
echo "Configuration:"
echo "  Data directory: /data/ness/.privateness"
echo "  P2P port: 6006"
echo "  RPC port: 6660"
echo "=========================================="

# Start Privateness daemon
echo "Starting Privateness blockchain node..."
exec privateness \
    -data-dir=/data/ness/.privateness \
    -web-interface-addr=0.0.0.0:6006 \
    -rpc-interface-addr=0.0.0.0:6660 \
    "$@"
