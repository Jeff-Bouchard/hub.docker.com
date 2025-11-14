#!/bin/bash

set -e

# Paths for mounted configs
WG_CONF=${WG_CONF:-/etc/amneziawg/wg.conf}
XRAY_CONF=${XRAY_CONF:-/etc/xray/config.json}

echo "amnezia-exit starting..."

if [ ! -f "$XRAY_CONF" ]; then
    echo "ERROR: Xray config not found at $XRAY_CONF" >&2
    exit 1
fi

if [ -f "$WG_CONF" ]; then
    echo "NOTE: /etc/amneziawg/wg.conf is present."
    echo "This image includes amneziawg-tools, but does NOT automatically bring up the WG interface."
    echo "Bring up AmneziaWG/WG from your orchestrator or a mounted script, since the exact CLI"
    echo "usage depends on your policy derived from Privateness identities."
fi

echo "Starting Xray with config: $XRAY_CONF"
exec xray -c "$XRAY_CONF"
