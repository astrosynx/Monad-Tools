#!/usr/bin/env bash
set -euo pipefail

echo "== Monad Keystore Integrity Check =="
echo

# ----------------------------
# Configuration
# ----------------------------

# Default layout from the official Monad node installation guide
KEYSTORE_BASE="${KEYSTORE_BASE:-/home/monad/monad-bft/config}"
SECP_KEYSTORE="${SECP_KEYSTORE:-$KEYSTORE_BASE/id-secp}"
BLS_KEYSTORE="${BLS_KEYSTORE:-$KEYSTORE_BASE/id-bls}"
KEYSTORE_OWNER="${KEYSTORE_OWNER:-monad}"

# ----------------------------
# Keystore directory
# ----------------------------

echo "[+] Checking keystore directory"

if [[ ! -d "$KEYSTORE_BASE" ]]; then
  echo "  ✗ Keystore directory not found: $KEYSTORE_BASE"
  echo "    Set KEYSTORE_BASE if your node uses a different layout"
  exit 1
fi

echo "  ✓ Keystore directory exists: $KEYSTORE_BASE"

# ----------------------------
# Key files
# ----------------------------

echo
echo "[+] Checking keystore files"

FAILED=0

for key in "$SECP_KEYSTORE" "$BLS_KEYSTORE"; do
  name=$(basename "$key")

  if [[ ! -f "$key" ]]; then
    echo "  ✗ Missing: $key"
    FAILED=1
    continue
  fi

  if [[ ! -s "$key" ]]; then
    echo "  ✗ Empty file: $key"
    FAILED=1
    continue
  fi

  echo "  ✓ Found $name ($(stat -c %s "$key") bytes)"

  # Any group or other permission bit is too open for key material
  PERM=$(stat -c "%a" "$key")
  if (( 8#$PERM & 8#077 )); then
    echo "  ✗ Insecure permissions ($PERM): $name  →  chmod 600 $key"
    FAILED=1
  else
    echo "  ✓ Permissions OK ($PERM): $name"
  fi

  OWNER=$(stat -c "%U" "$key")
  if [[ "$OWNER" != "$KEYSTORE_OWNER" ]]; then
    echo "  ! Owned by '$OWNER', expected '$KEYSTORE_OWNER': $name"
  fi
done

if [[ "$FAILED" -ne 0 ]]; then
  exit 1
fi

echo
echo "✓ Keystore integrity check passed"
