#!/bin/bash

set -e

echo "Building all ness-network images..."

docker build -t ness-network/emercoin-core ./emercoin-core
docker build -t ness-network/privateness ./privateness
docker build -t ness-network/skywire ./skywire
docker build -t ness-network/pyuheprng ./pyuheprng
docker build -t ness-network/privatenumer ./privatenumer
docker build -t ness-network/privatenesstools ./privatenesstools
docker build -t ness-network/yggdrasil ./yggdrasil
docker build -t ness-network/i2p-yggdrasil ./i2p-yggdrasil
docker build -t ness-network/dns-reverse-proxy ./dns-reverse-proxy
docker build -t ness-network/amneziawg ./amneziawg
docker build -t ness-network/skywire-amneziawg ./skywire-amneziawg
docker build -t ness-network/ness-unified ./ness-unified

echo "All images built successfully!"
