#!/bin/bash
set -euo pipefail

MAIN_REPO="https://github.com/aimanwhb/myvpsbootstrap.git"
MAIN_DIR="myvpsbootstrap"
SECRET_REPO="https://github.com/aimanwhb/secrets.git"
SECRET_DIR="secrets"

# -------------------------------
# Check required environment variables
# -------------------------------
if [ -z "${ROOT_PASSWORD:-}" ]; then
    echo "ERROR: ROOT_PASSWORD is not set. Exiting."
    exit 1
fi

if [ -z "${GIT_TOKEN:-}" ]; then
    echo "ERROR: GIT_TOKEN is not set. Exiting."
    exit 1
fi

export ROOT_PASSWORD
export GIT_TOKEN

# -------------------------------
# Parse options
# -------------------------------
DRY_RUN=false
POSITIONAL=()

for arg in "$@"; do
    case "$arg" in
        --check)
            DRY_RUN=true
            ;;
        *)
            POSITIONAL+=("$arg")
            ;;
    esac
done

# Tags are remaining positional arguments
TAGS="${POSITIONAL[*]}"

# -------------------------------
# Clone or update main repo
# -------------------------------
if [ ! -d "$MAIN_DIR" ]; then
    echo "[+] Cloning repo..."
    git clone "$MAIN_REPO"
else
    echo "[+] Repo exists, pulling latest..."
    cd "$MAIN_DIR"
    git pull
    cd ..
fi

# -------------------------------
# Clone or update secrets repo
# -------------------------------
if [ ! -d "$SECRET_DIR" ]; then
    echo "[+] Cloning repo..."
    git clone "$SECRET_REPO"
else
    echo "[+] Repo exists, pulling latest..."
    cd "$SECRET_DIR"
    git pull
    cd ..
fi

# ------------------------------------------
# Update vars.yaml file from secrets repo
# ------------------------------------------
cp -f "$SECRET_DIR"/vars.yaml  "$MAIN_DIR"/ansible/playboks/var/vars.yaml
if [ "$?" -eq 0 ]; then 
    echo "Successfully updated vars.yaml"
else
    echo "Error updating vars.yaml"
    exit 1

# -------------------------------
# Tags info
# -------------------------------
if [ -n "$TAGS" ]; then
    echo "[+] Running with tags: $TAGS"
else
    echo "[+] Running full playbook (no tags)."
fi

if [ "$DRY_RUN" = true ]; then
    echo "[+] Dry-run enabled (--check)"
fi

# -------------------------------
# Run Ansible playbook
# -------------------------------
ANSIBLE_CMD=(ansible-playbook -i "$MAIN_DIR/ansible/inventory/hosts" "$MAIN_DIR/ansible/playbooks/main.yaml")

if [ -n "$TAGS" ]; then
    ANSIBLE_CMD+=(--tags "$TAGS")
fi

if [ "$DRY_RUN" = true ]; then
    ANSIBLE_CMD+=(--check)
fi

# Execute
"${ANSIBLE_CMD[@]}"