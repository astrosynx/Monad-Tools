#!/usr/bin/env bash
set -euo pipefail

echo "== TrieDB Sanity Check =="
echo

# ----------------------------
# Configuration
# ----------------------------

TRIEDB_DEVICE="${TRIEDB_DEVICE:-/dev/triedb}"
MAX_READ_LATENCY_MS=50

# ----------------------------
# Device presence
# ----------------------------

echo "[+] Checking TrieDB device"

if [[ ! -b "$TRIEDB_DEVICE" ]]; then
  echo "  ✗ TrieDB device not found: $TRIEDB_DEVICE"
  exit 1
fi

echo "  ✓ TrieDB block device exists"

# ----------------------------
# Block device info
# ----------------------------

echo
echo "[+] Inspecting block device properties"

lsblk "$TRIEDB_DEVICE"

# ----------------------------
# LBA size
# ----------------------------

echo
echo "[+] Checking logical block size"

LBA=$(blockdev --getss "$TRIEDB_DEVICE")

if [[ "$LBA" -lt 4096 ]]; then
  echo "  ✗ LBA size too small: ${LBA} bytes"
  exit 1
fi

echo "  ✓ LBA size OK: ${LBA} bytes"

# ----------------------------
# Read latency sample
# ----------------------------

echo
echo "[+] Sampling read latency"

START=$(date +%s%3N)
dd if="$TRIEDB_DEVICE" of=/dev/null bs=4K count=256 iflag=direct status=none
END=$(date +%s%3N)

LATENCY=$((END - START))

if [[ "$LATENCY" -gt "$MAX_READ_LATENCY_MS" ]]; then
  echo "  ✗ High read latency: ${LATENCY}ms"
  exit 1
fi

echo "  ✓ Read latency OK: ${LATENCY}ms"

echo
echo "✓ TrieDB sanity check passed"
