#!/bin/bash
set -euo pipefail

if [ -z "${GIT_TOKEN:-}" ] || [ -z "${ROOT_PASSWORD:-}" ] || [ -z "${GIT_USERNAME:-}" ] || [ -z "${CERT_REPO:-}" ] || [ -z "${CERT_FILE:-}" ]; then
  echo "❌ ERROR: Missing required environment variables"
  exit 1
fi

DEST_DIR="/tmp/restore-cert"
REPO_URL="https://${GIT_USERNAME}:${GIT_TOKEN}@github.com/${GIT_USERNAME}/${CERT_REPO}.git"

# =========================
# CLONE REPO
# =========================
if [ ! -d "$DEST_DIR/.git" ]; then
  echo "📥 Cloning secrets repo..."
  git clone "$REPO_URL" "$DEST_DIR"
else
  echo "🔄 Updating secrets repo..."
  cd "$DEST_DIR"
  git pull
fi

# =========================
# Decrypt cert
# =========================
gpg --batch --yes --passphrase "$ROOT_PASSWORD" \
  --decrypt "$DEST_DIR/$CERT_FILE" | tar -xzf - -C "$DEST_DIR"

if [ ! -d "$DEST_DIR/etc/letsencrypt" ]; then
  echo "❌ ERROR: Decryption succeeded but letsencrypt folder is missing"
  exit 1
fi

# =========================
# Apply cert
# =========================
echo "🔐 Applying cert from decrypted folder..."
rm -rf /etc/letsencrypt
mv "$DEST_DIR/etc/letsencrypt" /etc/
echo "✅ SSL restore complete."

# =========================
# Cleanup
# =========================
echo "Cleanup......."
rm -rf "$DEST_DIR/etc"