#!/bin/bash

set -e

DOCKER_USER="nessnetwork"

echo "Building all images for ${DOCKER_USER}..."

docker build -t ${DOCKER_USER}/emercoin-core ./emercoin-core
docker build -t ${DOCKER_USER}/ness-blockchain ./ness-blockchain
docker build -t ${DOCKER_USER}/privateness ./privateness
docker build -t ${DOCKER_USER}/skywire ./skywire
docker build -t ${DOCKER_USER}/pyuheprng ./pyuheprng
docker build -t ${DOCKER_USER}/privatenumer ./privatenumer
docker build -t ${DOCKER_USER}/privatenesstools ./privatenesstools
docker build -t ${DOCKER_USER}/pyuheprng-privatenesstools ./pyuheprng-privatenesstools
docker build -t ${DOCKER_USER}/yggdrasil ./yggdrasil
docker build -t ${DOCKER_USER}/i2p-yggdrasil ./i2p-yggdrasil
docker build -t ${DOCKER_USER}/dns-reverse-proxy ./dns-reverse-proxy
docker build -t ${DOCKER_USER}/ipfs ./ipfs
docker build -t ${DOCKER_USER}/amneziawg ./amneziawg
docker build -t ${DOCKER_USER}/skywire-amneziawg ./skywire-amneziawg
docker build -t ${DOCKER_USER}/ness-unified ./ness-unified

echo "All images built successfully for ${DOCKER_USER}!"
