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

# Default GUI directory inside the container, can be overridden via PRIVATENESS_GUI_DIR
GUI_DIR=${PRIVATENESS_GUI_DIR:-/opt/privateness/gui/static}

exec privateness \
    -gui-dir="${GUI_DIR}" \
    -launch-browser=false \
    -no-ping-log \
    -enable-all-api-sets=true \
    -enable-gui=true \
    -log-level=error \
    -disable-pex=true \
    "$@"
