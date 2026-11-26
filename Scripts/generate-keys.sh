#!/usr/bin/env bash
# Regenerate Brewery's Sparkle EdDSA (Ed25519) signing keypair.
#
# The private key is written to the gitignored Keys/ directory and must never
# be committed — anyone with it can sign a malicious "update". The public key
# is printed as the SUPublicEDKey value to bake into Scripts/build-app.sh.
#
# Re-run this only if the signing key is lost or compromised; after changing
# the key you must also update SU_PUBLIC_ED_KEY in Scripts/build-app.sh.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEYS_DIR="$ROOT_DIR/Keys"
PRIVATE_KEY="$KEYS_DIR/release-signing"

mkdir -p "$KEYS_DIR"

if [[ -f "$PRIVATE_KEY" ]]; then
    echo "A signing key already exists at Keys/release-signing; not overwriting." >&2
    echo "Delete it first if you really want to generate a new keypair." >&2
    exit 1
fi

openssl genpkey -algorithm ED25519 -out "$PRIVATE_KEY"

echo "Private key written to Keys/release-signing (gitignored)."
echo
echo "Add this as SUPublicEDKey in Scripts/build-app.sh:"
openssl pkey -in "$PRIVATE_KEY" -pubout -outform DER 2>/dev/null | tail -c 32 | base64
