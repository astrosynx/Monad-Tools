#!/usr/bin/env bash
set -euo pipefail

echo "== TrieDB Sanity Check =="
echo

# ----------------------------
# Configuration
# ----------------------------

TRIEDB_DEVICE="${TRIEDB_DEVICE:-/dev/triedb}"
EXPECTED_LBA="${EXPECTED_LBA:-512}"      # bytes, per the official Monad install guide
MAX_READ_LATENCY_MS="${MAX_READ_LATENCY_MS:-50}"

# ----------------------------
# Device presence
# ----------------------------

echo "[+] Checking TrieDB device"

if [[ ! -b "$TRIEDB_DEVICE" ]]; then
  echo "  ✗ TrieDB device not found: $TRIEDB_DEVICE"
  echo "    Check the udev rule in /etc/udev/rules.d/99-triedb.rules"
  exit 1
fi

echo "  ✓ TrieDB block device exists → $(readlink -f "$TRIEDB_DEVICE")"

# ----------------------------
# Block device info
# ----------------------------

echo
echo "[+] Inspecting block device properties"

lsblk "$TRIEDB_DEVICE"

# Formatted by monad-mpt, never mounted
if findmnt -rn -S "$(readlink -f "$TRIEDB_DEVICE")" >/dev/null 2>&1; then
  echo "  ✗ TrieDB device is mounted as a filesystem"
  exit 1
fi
echo "  ✓ Not mounted"

# ----------------------------
# LBA size
# ----------------------------

echo
echo "[+] Checking logical block size"

LBA=$(blockdev --getss "$TRIEDB_DEVICE")

if [[ "$LBA" -ne "$EXPECTED_LBA" ]]; then
  echo "  ✗ LBA size is ${LBA} bytes, expected ${EXPECTED_LBA}"
  echo "    See the TrieDB section of https://docs.monad.xyz/node-ops/full-node-installation"
  echo "    Reformatting the namespace ERASES the drive. Do not do it on a live node."
  exit 1
fi

echo "  ✓ LBA size OK: ${LBA} bytes"

# ----------------------------
# Read latency sample
# ----------------------------

echo
echo "[+] Sampling read latency (1 MiB, direct I/O, read-only)"

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
