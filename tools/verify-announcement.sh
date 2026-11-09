#!/usr/bin/env bash
# Verifies a GPG-signed Monad Foundation node operator announcement.
# Uses a throwaway keyring in a temp dir; your own GPG setup is not touched.
# Exit 0 = signed by 2+ authorized active signers, 1 = not verified.
set -uo pipefail

# ----------------------------
# Configuration
# ----------------------------

ANNOUNCEMENT="${1:-latest}"   # index (e.g. 9), "latest", or a local dir with announcement.txt/.sig
REPO_RAW="${REPO_RAW:-https://raw.githubusercontent.com/monad-crypto/mf-nodeops-comms/main}"
REPO_API="${REPO_API:-https://api.github.com/repos/monad-crypto/mf-nodeops-comms}"
FINGERPRINTS_URL="${FINGERPRINTS_URL:-https://docs.monad.xyz/node-ops/gpg-keys.json}"
MIN_SIGNERS="${MIN_SIGNERS:-2}"

for bin in curl gpg jq; do
  command -v "$bin" >/dev/null 2>&1 || { echo "✗ $bin is required"; exit 1; }
done

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
export GNUPGHOME="$WORK/gnupg"
mkdir -m 700 "$GNUPGHOME"

echo "== Monad Foundation Announcement Check =="
echo

# ----------------------------
# Authorized fingerprints (published in the Monad docs)
# ----------------------------

echo "[+] Authorized signers ($FINGERPRINTS_URL)"

if ! curl -fsSL -m 15 "$FINGERPRINTS_URL" -o "$WORK/gpg-keys.json"; then
  echo "  ✗ could not download the fingerprint list"
  exit 1
fi
mapfile -t AUTHORIZED < <(jq -r 'to_entries[] | select(.value.status == "active") | .value.fingerprint | ascii_upcase' "$WORK/gpg-keys.json")
if [[ "${#AUTHORIZED[@]}" -eq 0 ]]; then
  echo "  ✗ no active fingerprints found"
  exit 1
fi
echo "  ✓ ${#AUTHORIZED[@]} active signers"

is_authorized() {
  local fpr
  for fpr in "${AUTHORIZED[@]}"; do [[ "$fpr" == "$1" ]] && return 0; done
  return 1
}

# ----------------------------
# Public keys (from the repository), checked against the list above
# ----------------------------

echo
echo "[+] Public keys"

mapfile -t KEY_FILES < <(curl -fsSL -m 15 "$REPO_API/contents/keys" | jq -r '.[] | select(.name | endswith(".pub.asc")) | .name')
if [[ "${#KEY_FILES[@]}" -eq 0 ]]; then
  echo "  ✗ could not list keys/ in the repository"
  exit 1
fi

for f in "${KEY_FILES[@]}"; do
  curl -fsSL -m 15 "$REPO_RAW/keys/$f" -o "$WORK/$f" || { echo "  ✗ could not download $f"; exit 1; }
  FPR=$(gpg --with-colons --show-keys "$WORK/$f" 2>/dev/null | awk -F: '/^fpr:/ {print $10; exit}')
  if is_authorized "$FPR"; then
    gpg --quiet --import "$WORK/$f" 2>/dev/null
    echo "  ✓ $f  $FPR"
  else
    echo "  ! $f  $FPR is not an active authorized fingerprint, not imported"
  fi
done

# ----------------------------
# Announcement
# ----------------------------

echo
if [[ -d "$ANNOUNCEMENT" ]]; then
  SRC="$ANNOUNCEMENT"
  echo "[+] Announcement (local: $SRC)"
else
  if [[ "$ANNOUNCEMENT" == "latest" ]]; then
    ANNOUNCEMENT=$(curl -fsSL -m 15 "$REPO_API/contents/announcements" \
      | jq -r '[.[] | select(.name | test("^mf-[0-9]+$")) | .name | ltrimstr("mf-") | tonumber] | max')
  fi
  SRC="$WORK/mf-$ANNOUNCEMENT"
  mkdir -p "$SRC"
  echo "[+] Announcement #$ANNOUNCEMENT"
  for f in announcement.txt announcement.sig; do
    curl -fsSL -m 15 "$REPO_RAW/announcements/mf-$ANNOUNCEMENT/$f" -o "$SRC/$f" \
      || { echo "  ✗ could not download mf-$ANNOUNCEMENT/$f"; exit 1; }
  done
fi

sed -n '1,8p' "$SRC/announcement.txt" | grep -Ei 'announcement|created|code' | sed 's/^/  │ /'

# ----------------------------
# Signatures
# ----------------------------

echo
echo "[+] Signatures"

# VALIDSIG field 12 is the primary key fingerprint
mapfile -t SIGNERS < <(gpg --status-fd 1 --verify "$SRC/announcement.sig" "$SRC/announcement.txt" 2>/dev/null \
  | awk '$2 == "VALIDSIG" {print toupper($12)}' | sort -u)

GOOD=0
for fpr in "${SIGNERS[@]}"; do
  if is_authorized "$fpr"; then
    echo "  ✓ good signature from $fpr"
    GOOD=$((GOOD + 1))
  fi
done

echo
if [[ "$GOOD" -ge "$MIN_SIGNERS" ]]; then
  echo "✓ Verified: $GOOD authorized signatures (need $MIN_SIGNERS)"
  exit 0
else
  echo "✗ NOT verified: $GOOD authorized signatures (need $MIN_SIGNERS). Do not act on this message."
  exit 1
fi
