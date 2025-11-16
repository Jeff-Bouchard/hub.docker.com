#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_USER="${DOCKER_USER:-nessnetwork}"

BUILD_ARGS=()
if [[ "${NO_CACHE:-0}" != "0" ]]; then
  BUILD_ARGS+=("--no-cache")
fi

# Keep the build order deterministic so dependency images are prepared first.
IMAGES=(
  "emercoin-core"
  "yggdrasil"
  "dns-reverse-proxy"
  "skywire"
  "privateness"
  "ness-blockchain"
  "pyuheprng"
  "privatenumer"
  "privatenesstools"
  "pyuheprng-privatenesstools"
  "ipfs"
  "i2p-yggdrasil"
  "amneziawg"
  "skywire-amneziawg"
  "amnezia-exit"
  "ness-unified"
)

echo "Building ${#IMAGES[@]} images for namespace '${DOCKER_USER}'..."

for image in "${IMAGES[@]}"; do
  context_path="${SCRIPT_DIR}/${image}"

  if [[ ! -d "${context_path}" ]]; then
    echo "[ERROR] Missing build context: ${context_path}" >&2
    exit 1
  fi

  echo "\n>>> Building ${DOCKER_USER}/${image}:latest"
  docker build "${BUILD_ARGS[@]}" -t "${DOCKER_USER}/${image}:latest" "${context_path}"
done

echo "\nAll images built successfully."
