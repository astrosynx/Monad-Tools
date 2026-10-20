#!/usr/bin/env bash
set -euo pipefail

echo "== Monad Sync State Inspector =="
echo

# ----------------------------
# Configuration
# ----------------------------

RPC_ENDPOINT="${RPC_ENDPOINT:-http://localhost:8080}"
STAGNATION_THRESHOLD="${STAGNATION_THRESHOLD:-300}"   # seconds
STATE_FILE="${STATE_FILE:-/tmp/monad_last_block}"

NOW=$(date +%s)

rpc() {
  curl -sf -m 5 "$RPC_ENDPOINT" \
    -X POST \
    -H "Content-Type: application/json" \
    --data "{\"jsonrpc\":\"2.0\",\"method\":\"$1\",\"params\":[],\"id\":1}"
}

# ----------------------------
# Block height (also proves the RPC is up)
# ----------------------------

echo "[+] Fetching current block height from $RPC_ENDPOINT"

BLOCK_HEX=$(rpc eth_blockNumber | jq -r '.result' 2>/dev/null || true)

if [[ -z "$BLOCK_HEX" || "$BLOCK_HEX" == "null" ]]; then
  echo "  ✗ RPC not reachable or returned no block number"
  exit 1
fi

BLOCK_DEC=$((BLOCK_HEX))

echo "  ✓ Current block height: $BLOCK_DEC"

# ----------------------------
# Sync status and peers (informational)
# ----------------------------

echo
echo "[+] Sync status"

SYNCING=$(rpc eth_syncing | jq -c '.result' 2>/dev/null || true)
if [[ "$SYNCING" == "false" ]]; then
  echo "  ✓ Node reports it is not syncing"
elif [[ -n "$SYNCING" && "$SYNCING" != "null" ]]; then
  echo "  ! Node is syncing: $SYNCING"
else
  echo "  ! eth_syncing not available"
fi

PEERS_HEX=$(rpc net_peerCount | jq -r '.result' 2>/dev/null || true)
if [[ -n "$PEERS_HEX" && "$PEERS_HEX" != "null" ]]; then
  echo "  ✓ Peers: $((PEERS_HEX))"
else
  echo "  ! net_peerCount not available"
fi

# ----------------------------
# Sync stagnation detection
# ----------------------------
# The state file keeps the last height and the time it was first seen.
# The timestamp only moves when the height moves, so a stall is detected
# however often the script runs (cron every minute or every hour).

echo
echo "[+] Checking for stalled height"

if [[ -f "$STATE_FILE" ]]; then
  read -r LAST_BLOCK LAST_TS < "$STATE_FILE"

  if [[ "$BLOCK_DEC" -le "$LAST_BLOCK" ]]; then
    AGE=$((NOW - LAST_TS))
    if [[ "$AGE" -ge "$STAGNATION_THRESHOLD" ]]; then
      echo "  ✗ Height stuck at $BLOCK_DEC for ${AGE}s"
      exit 1
    fi
    echo "  ! Height unchanged for ${AGE}s (threshold ${STAGNATION_THRESHOLD}s)"
  else
    echo "  ✓ Height advanced by $((BLOCK_DEC - LAST_BLOCK)) since last run"
    echo "$BLOCK_DEC $NOW" > "$STATE_FILE"
  fi
else
  echo "  i First run, baseline saved to $STATE_FILE"
  echo "$BLOCK_DEC $NOW" > "$STATE_FILE"
fi

echo
echo "✓ Sync state looks healthy"
