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
    -enable-gui=false \
    -launch-browser=false \
    -log-level=debug \
    -disable-pex \
    "$@"
