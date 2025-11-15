#!/bin/sh
set -euo pipefail

EMERCOIN_HOST="${EMERCOIN_HOST:-emercoin-core}"
EMERCOIN_PORT="${EMERCOIN_PORT:-6662}"
EMERCOIN_USER="${EMERCOIN_USER:-rpcuser}"
EMERCOIN_PASS="${EMERCOIN_PASS:-rpcpassword}"
DNS_NVS_KEY="${DNS_NVS_KEY:-ness:dns-reverse-proxy-config}"

rpc_call() {
  local payload="$1"
  curl -s --user "$EMERCOIN_USER:$EMERCOIN_PASS" \
    --data-binary "$payload" \
    -H 'content-type: text/plain;' \
    "http://$EMERCOIN_HOST:$EMERCOIN_PORT/"
}

wait_for_rpc() {
  echo "[dns-reverse-proxy] Waiting for Emercoin RPC at $EMERCOIN_HOST:$EMERCOIN_PORT..."
  while true; do
    if rpc_call '{"jsonrpc":"1.0","id":"ping","method":"getinfo","params":[]}' >/dev/null 2>&1; then
      echo "[dns-reverse-proxy] Emercoin RPC is available."
      break
    fi
    sleep 5
  done
}

fetch_nvs_config() {
  echo "[dns-reverse-proxy] Fetching NVS record $DNS_NVS_KEY..."
  RESPONSE=$(rpc_call "{\"jsonrpc\":\"1.0\",\"id\":\"nvs\",\"method\":\"name_show\",\"params\":[\"$DNS_NVS_KEY\"]}")
  VALUE=$(printf '%s' "$RESPONSE" | sed -n 's/.*"value"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p')

  if [ -z "$VALUE" ]; then
    echo "[dns-reverse-proxy] ERROR: Could not parse value from NVS response: $RESPONSE" >&2
    exit 1
  fi

  # Unescape common JSON sequences
  VALUE=$(printf '%s' "$VALUE" | sed 's/\\n/\n/g; s/\\"/"/g')
  echo "$VALUE"
}

wait_for_rpc
ARGS="$(fetch_nvs_config)"

echo "[dns-reverse-proxy] Starting with args from NVS: $ARGS"
exec dns-reverse-proxy $ARGS
