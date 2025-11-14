#!/bin/bash

set -e

# Build multi-architecture images using buildx
# Supports: linux/amd64, linux/arm64, linux/arm/v7

echo "Setting up Docker buildx..."
docker buildx create --name ness-builder --use 2>/dev/null || docker buildx use ness-builder

echo "Building multi-architecture images..."

PLATFORMS="linux/amd64,linux/arm64,linux/arm/v7"

docker buildx build --platform ${PLATFORMS} -t ness-network/emercoin-core:latest --push ./emercoin-core
docker buildx build --platform ${PLATFORMS} -t ness-network/yggdrasil:latest --push ./yggdrasil
docker buildx build --platform ${PLATFORMS} -t ness-network/skywire:latest --push ./skywire
docker buildx build --platform ${PLATFORMS} -t ness-network/dns-reverse-proxy:latest --push ./dns-reverse-proxy
docker buildx build --platform ${PLATFORMS} -t ness-network/privateness:latest --push ./privateness
docker buildx build --platform ${PLATFORMS} -t ness-network/pyuheprng:latest --push ./pyuheprng
docker buildx build --platform ${PLATFORMS} -t ness-network/privatenumer:latest --push ./privatenumer
docker buildx build --platform ${PLATFORMS} -t ness-network/privatenesstools:latest --push ./privatenesstools

# I2P and unified are larger, build separately
docker buildx build --platform linux/amd64,linux/arm64 -t ness-network/i2p-yggdrasil:latest --push ./i2p-yggdrasil
docker buildx build --platform linux/amd64,linux/arm64 -t ness-network/ness-unified:latest --push ./ness-unified

echo "All multi-architecture images built and pushed successfully!"
