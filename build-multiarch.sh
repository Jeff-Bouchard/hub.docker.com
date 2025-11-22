#!/bin/bash

set -e

# Build multi-architecture images using buildx
# Supports: linux/amd64, linux/arm64, linux/arm/v7

echo "Setting up Docker buildx..."
docker buildx create --name ness-builder --use 2>/dev/null || docker buildx use ness-builder

echo "Building multi-architecture images..."

PLATFORMS="linux/amd64,linux/arm64,linux/arm/v7"

docker buildx build --platform ${PLATFORMS} -t nessnetwork/emercoin-core:latest --push ./emercoin-core
docker buildx build --platform ${PLATFORMS} -t nessnetwork/skywire:latest --push ./skywire
docker buildx build --platform ${PLATFORMS} -t nessnetwork/dns-reverse-proxy:latest --push ./dns-reverse-proxy
docker buildx build --platform ${PLATFORMS} -t nessnetwork/privateness:latest --push ./privateness
docker buildx build --platform ${PLATFORMS} -t nessnetwork/pyuheprng:latest --push ./pyuheprng
docker buildx build --platform ${PLATFORMS} -t nessnetwork/privatenesstools:latest --push ./privatenesstools

# Tier 2: Heavy / Non-Essential / 64-bit only (Avoids QEMU crashes on armv7)
docker buildx build --platform linux/amd64,linux/arm64 -t nessnetwork/privatenumer:latest --push ./privatenumer
docker buildx build --platform linux/amd64,linux/arm64 -t nessnetwork/amneziawg:latest --push ./amneziawg
docker buildx build --platform linux/amd64,linux/arm64 -t nessnetwork/skywire-amneziawg:latest --push ./skywire-amneziawg
docker buildx build --platform linux/amd64,linux/arm64 -t nessnetwork/amnezia-exit:latest --push ./amnezia-exit
docker buildx build --platform linux/amd64,linux/arm64 -t nessnetwork/yggdrasil:latest --push ./yggdrasil
docker buildx build --platform linux/amd64,linux/arm64 -t nessnetwork/i2p-yggdrasil:latest --push ./i2p-yggdrasil
docker buildx build --platform linux/amd64,linux/arm64 -t nessnetwork/ness-unified:latest --push ./ness-unified

echo "All multi-architecture images built and pushed successfully!"
