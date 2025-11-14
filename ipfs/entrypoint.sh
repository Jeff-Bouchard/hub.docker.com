#!/bin/bash

set -e

echo "=========================================="
echo "IPFS Daemon - Decentralized Storage"
echo "=========================================="

# Initialize IPFS if not already initialized
if [ ! -f "$IPFS_PATH/config" ]; then
    echo "Initializing IPFS repository..."
    ipfs init --profile=server
    
    # Configure for better performance
    ipfs config Addresses.API /ip4/0.0.0.0/tcp/5001
    ipfs config Addresses.Gateway /ip4/0.0.0.0/tcp/8080
    
    # Enable experimental features
    ipfs config --json Experimental.FilestoreEnabled true
    ipfs config --json Experimental.UrlstoreEnabled true
    ipfs config --json Experimental.Libp2pStreamMounting true
    ipfs config --json Experimental.P2pHttpProxy true
    
    # Configure swarm addresses
    ipfs config --json Addresses.Swarm '[
        "/ip4/0.0.0.0/tcp/4001",
        "/ip6/::/tcp/4001",
        "/ip4/0.0.0.0/udp/4001/quic",
        "/ip6/::/udp/4001/quic"
    ]'
    
    # Set storage limits
    ipfs config Datastore.StorageMax ${IPFS_STORAGE_MAX:-10GB}
    
    # Enable garbage collection
    ipfs config --json Datastore.GCPeriod "1h"
    
    echo "✓ IPFS initialized"
else
    echo "✓ IPFS repository already initialized"
fi

# Display IPFS ID
echo "=========================================="
echo "IPFS Node Information:"
ipfs id
echo "=========================================="

# Start IPFS daemon
echo "Starting IPFS daemon..."
exec ipfs "$@"
