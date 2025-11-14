#!/bin/bash

set -e

echo "=========================================="
echo "pyuheprng + privatenesstools Combined"
echo "=========================================="
echo "Services:"
echo "  - pyuheprng (port 5000)"
echo "  - privatenesstools (port 8888)"
echo "=========================================="

# Check if running with required privileges
if [ ! -w /dev/random ]; then
    echo "ERROR: Cannot write to /dev/random"
    echo "ERROR: Container must run with --privileged or --device /dev/random"
    exit 1
fi

# Check Emercoin connection
echo "Checking Emercoin Core connection..."
until curl -s --user "$EMERCOIN_USER:$EMERCOIN_PASS" \
    --data-binary '{"jsonrpc":"1.0","id":"test","method":"getinfo","params":[]}' \
    -H 'content-type: text/plain;' \
    http://$EMERCOIN_HOST:$EMERCOIN_PORT/ > /dev/null 2>&1; do
    echo "Waiting for Emercoin Core at $EMERCOIN_HOST:$EMERCOIN_PORT..."
    sleep 5
done

echo "✓ Emercoin Core connected"

# Check hardware RNG availability
if [ -c /dev/hwrng ]; then
    echo "✓ Hardware RNG available: /dev/hwrng"
else
    echo "⚠ Hardware RNG not available (will use CPU RDRAND/RDSEED)"
fi

# Check current entropy level
ENTROPY_AVAIL=$(cat /proc/sys/kernel/random/entropy_avail)
echo "Current entropy available: $ENTROPY_AVAIL bits"

# Verify /dev/urandom is disabled (via GRUB/cmdline)
if grep -q "random.trust_cpu=off" /proc/cmdline 2>/dev/null; then
    echo "✓ /dev/urandom protections enabled (GRUB/cmdline configured)"
else
    echo "⚠ WARNING: /dev/urandom not disabled via GRUB/cmdline"
    echo "⚠ For production, add to GRUB/cmdline: random.trust_cpu=off random.trust_bootloader=off"
fi

echo "=========================================="
echo "Starting combined services..."
echo "  pyuheprng: Feeding /dev/random"
echo "  privatenesstools: Network utilities"
echo "=========================================="

# Create log directory
mkdir -p /var/log/supervisor

# Execute supervisor to run both services
exec "$@"
