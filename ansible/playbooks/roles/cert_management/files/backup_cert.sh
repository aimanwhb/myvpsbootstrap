#!/bin/bash
set -euo pipefail

if [ -z "${GIT_TOKEN:-}" ] || [ -z "${ROOT_PASSWORD:-}" ] || [ -z "${GIT_USERNAME:-}" ] || [ -z "${CERT_REPO:-}" ]; then
  echo "❌ ERROR: Missing required environment variables"
  exit 1
fi

DEST_DIR="/tmp/backup-cert"
REPO_URL="https://${GIT_USERNAME}:${GIT_TOKEN}@github.com/${GIT_USERNAME}/${CERT_REPO}.git"

# =========================
# Encrypt cert
# =========================
tar -czf - -P /etc/letsencrypt | \
  gpg --batch --yes --passphrase "$ROOT_PASSWORD" \
  --symmetric --cipher-algo AES256 \
  --output "$DEST_DIR/ssl-backup-$(date +%F).tar.gz.gpg"

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
# Push backup cert to Github
# =========================
mv "$DEST_DIR/ssl-backup-$(date +%F).tar.gz.gpg" "$DEST_DIR/$CERT_REPO"
git add "$DEST_DIR/$CERT_REPO/ssl-backup-$(date +%F).tar.gz.gpg"
git commit -m " Backup ssl-backup-$(date +%F).tar.gz.gpg"
git push -u origin main