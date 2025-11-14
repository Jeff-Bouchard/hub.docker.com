#!/bin/bash

set -e

echo "Pushing all ness-network images to Docker Hub..."

docker push ness-network/emercoin-core
docker push ness-network/privateness
docker push ness-network/skywire
docker push ness-network/pyuheprng
docker push ness-network/privatenumer
docker push ness-network/privatenesstools
docker push ness-network/yggdrasil
docker push ness-network/i2p-yggdrasil
docker push ness-network/dns-reverse-proxy
docker push ness-network/amneziawg
docker push ness-network/skywire-amneziawg
docker push ness-network/ness-unified

echo "All images pushed successfully!"
