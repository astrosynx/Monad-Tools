#!/usr/bin/env bash
set -euo pipefail

# ----------------------------
# Configuration (explicit)
# ----------------------------

RPC_ENDPOINT="${RPC_ENDPOINT:-}"

P2P_PORT="${P2P_PORT:-8000}"

CORE_SERVICES=(
  monad-bft
  monad-execution
)

OPTIONAL_SERVICES=(
  monad-rpc
)

MAX_CLOCK_DRIFT=5    # seconds
MIN_DISK_FREE=10     # percent
DISK_PATH="${DISK_PATH:-/}"

echo "== Monad Node Health Check =="
echo

# ----------------------------
# Services
# ----------------------------

echo "[+] Checking systemd services"

for svc in "${CORE_SERVICES[@]}"; do
  if systemctl is-active --quiet "$svc"; then
    echo "  ✓ $svc is running"
  else
    echo "  ✗ $svc is NOT running"
    exit 1
  fi
done

for svc in "${OPTIONAL_SERVICES[@]}"; do
  if systemctl is-active --quiet "$svc"; then
    echo "  ✓ $svc is running"
  else
    echo "  ! $svc is not running (optional)"
  fi
done

# ----------------------------
# P2P / Consensus Port
# ----------------------------

echo
echo "[+] Checking consensus P2P port ($P2P_PORT)"

if ss -ltnH | awk '{print $4}' | grep -Eq "(:|\])$P2P_PORT$"; then
  echo "  ✓ P2P port $P2P_PORT is listening"
else
  echo "  ✗ P2P port $P2P_PORT is not listening"
  exit 1
fi

# ----------------------------
# RPC (optional, explicit)
# ----------------------------

if [[ -n "$RPC_ENDPOINT" ]]; then
  echo
  echo "[+] Checking RPC endpoint"
  echo "  Using RPC endpoint: $RPC_ENDPOINT"

  if curl -sf "$RPC_ENDPOINT" >/dev/null; then
    echo "  ✓ RPC reachable"
  else
    echo "  ✗ RPC not reachable"
    exit 1
  fi
else
  echo
  echo "[i] RPC check skipped (RPC_ENDPOINT not set)"
fi

# ----------------------------
# Clock drift
# ----------------------------

echo
echo "[+] Checking clock drift"

if command -v chronyc >/dev/null 2>&1; then
  DRIFT=$(chronyc tracking | awk -F': ' '/Last offset/ {print int($2)}')
  if [[ "${DRIFT#-}" -le "$MAX_CLOCK_DRIFT" ]]; then
    echo "  ✓ Clock drift within limits (${DRIFT}s)"
  else
    echo "  ✗ Clock drift too high (${DRIFT}s)"
    exit 1
  fi
else
  echo "  ! chronyc not found, skipping clock drift check"
fi

# ----------------------------
# Disk space
# ----------------------------

echo
echo "[+] Checking disk space ($DISK_PATH)"

USED_PERCENT=$(df "$DISK_PATH" | awk 'NR==2 {print $5}' | tr -d '%')
FREE_PERCENT=$((100 - USED_PERCENT))

if [[ "$FREE_PERCENT" -ge "$MIN_DISK_FREE" ]]; then
  echo "  ✓ Disk space OK (${FREE_PERCENT}% free)"
else
  echo "  ✗ Low disk space (${FREE_PERCENT}% free)"
  exit 1
fi

echo
echo "✓ Node health check passed"

