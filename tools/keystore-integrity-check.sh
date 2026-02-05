#!/usr/bin/env bash
set -euo pipefail

echo "== Monad Keystore Integrity Check =="
echo

# ----------------------------
# Configuration
# ----------------------------

KEYSTORE_BASE="${KEYSTORE_BASE:-/var/lib/monad/keystore}"

SECP_KEY_PATTERN="secp"
BLS_KEY_PATTERN="bls"

EXPECTED_KEYS=2

# ----------------------------
# Keystore directory
# ----------------------------

echo "[+] Checking keystore directory"

if [[ ! -d "$KEYSTORE_BASE" ]]; then
  echo "  ✗ Keystore directory not found: $KEYSTORE_BASE"
  exit 1
fi

echo "  ✓ Keystore directory exists"

# ----------------------------
# Key discovery
# ----------------------------

echo
echo "[+] Discovering keystore files"

SECP_KEYS=$(find "$KEYSTORE_BASE" -type f -iname "*$SECP_KEY_PATTERN*" 2>/dev/null || true)
BLS_KEYS=$(find "$KEYSTORE_BASE" -type f -iname "*$BLS_KEY_PATTERN*" 2>/dev/null || true)

SECP_COUNT=$(echo "$SECP_KEYS" | sed '/^$/d' | wc -l)
BLS_COUNT=$(echo "$BLS_KEYS" | sed '/^$/d' | wc -l)

if [[ "$SECP_COUNT" -eq 0 ]]; then
  echo "  ✗ No SECP keystore found"
  exit 1
else
  echo "  ✓ Found $SECP_COUNT SECP keystore(s)"
fi

if [[ "$BLS_COUNT" -eq 0 ]]; then
  echo "  ✗ No BLS keystore found"
  exit 1
else
  echo "  ✓ Found $BLS_COUNT BLS keystore(s)"
fi

# ----------------------------
# Permissions
# ----------------------------

echo
echo "[+] Checking file permissions"

BAD_PERMS=0

while read -r key; do
  PERM=$(stat -c "%a" "$key")
  if [[ "$PERM" -gt 600 ]]; then
    echo "  ✗ Insecure permissions ($PERM): $key"
    BAD_PERMS=1
  else
    echo "  ✓ Permissions OK ($PERM): $(basename "$key")"
  fi
done <<< "$(echo -e "$SECP_KEYS\n$BLS_KEYS")"

if [[ "$BAD_PERMS" -ne 0 ]]; then
  exit 1
fi

echo
echo "✓ Keystore integrity check passed"
