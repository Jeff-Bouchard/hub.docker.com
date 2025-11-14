#!/bin/bash

set -e

echo "=========================================="
echo "Privateness Blockchain Node"
echo "=========================================="

echo "=========================================="
echo "Configuration:"
echo "  Data directory: .privateness/data"
echo "  P2P port: 6006"
echo "  RPC port: 6660"
echo "=========================================="

# Start Privateness daemon
echo "Starting Privateness blockchain node..."
exec privateness \
    -data-dir=.privateness/data \
    -web-interface-addr=0.0.0.0:6006 \
    -rpc-interface-addr=0.0.0.0:6660 \
    "$@"
