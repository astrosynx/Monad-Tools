#!/usr/bin/env bash
set -euo pipefail

echo "== Monad Sync State Inspector =="
echo

# ----------------------------
# Configuration
# ----------------------------

RPC_ENDPOINT="${RPC_ENDPOINT:-http://localhost:8080}"
STAGNATION_THRESHOLD=300   # seconds

NOW=$(date +%s)

# ----------------------------
# RPC availability
# ----------------------------

echo "[+] Checking RPC availability"

if ! curl -sf "$RPC_ENDPOINT" >/dev/null; then
  echo "  ✗ RPC not reachable: $RPC_ENDPOINT"
  exit 1
fi

echo "  ✓ RPC reachable"

# ----------------------------
# Block height
# ----------------------------

echo
echo "[+] Fetching current block height"

BLOCK_HEX=$(curl -s "$RPC_ENDPOINT" \
  -X POST \
  -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  | jq -r '.result')

if [[ "$BLOCK_HEX" == "null" || -z "$BLOCK_HEX" ]]; then
  echo "  ✗ Failed to retrieve block number"
  exit 1
fi

BLOCK_DEC=$((BLOCK_HEX))

echo "  ✓ Current block height: $BLOCK_DEC"

# ----------------------------
# Sync stagnation detection
# ----------------------------

STATE_FILE="/tmp/monad_last_block"

if [[ -f "$STATE_FILE" ]]; then
  read -r LAST_BLOCK LAST_TS < "$STATE_FILE"

  if [[ "$BLOCK_DEC" -le "$LAST_BLOCK" ]]; then
    AGE=$((NOW - LAST_TS))
    if [[ "$AGE" -ge "$STAGNATION_THRESHOLD" ]]; then
      echo "  ✗ Sync appears stalled for ${AGE}s"
      exit 1
    fi
  fi
fi

echo "$BLOCK_DEC $NOW" > "$STATE_FILE"

echo
echo "✓ Sync state looks healthy"
