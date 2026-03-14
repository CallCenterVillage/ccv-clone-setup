#!/bin/bash
# =============================================================================
# setup-clone.sh — Call Center Village (CCV) Machine Setup
# Run this manually after cloning each machine.
#
# Usage:
#   cd /opt/clone-setup
#   sudo bash setup-clone.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
LOG_FILE="$SCRIPT_DIR/setup.log"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "========================================"
echo " CCV Clone Setup — $(date)"
echo "========================================"

# =============================================================================
# Load .env
# =============================================================================

if [[ ! -f "$ENV_FILE" ]]; then
    echo "ERROR: .env file not found at $ENV_FILE"
    exit 1
fi

source "$ENV_FILE"

# Validate required vars (hostname comes from prompt, not .env)
for var in AV_SITE_TOKEN RMM_INSTALL_URL; do
    if [[ -z "${!var:-}" ]]; then
        echo "ERROR: $var is not set in .env"
        exit 1
    fi
done

# Find the .deb file
AV_DEB=$(find "$SCRIPT_DIR" -maxdepth 1 -name "*.deb" | head -n 1)
if [[ -z "$AV_DEB" ]]; then
    echo "ERROR: No .deb file found in $SCRIPT_DIR"
    exit 1
fi

# Prompt for hostname
echo ""
read -rp "Enter hostname for this machine (e.g. ccv02): " HOSTNAME
if [[ -z "$HOSTNAME" ]]; then
    echo "ERROR: Hostname cannot be empty."
    exit 1
fi

echo ""
echo "Config:"
echo "  Hostname : $HOSTNAME"
echo "  AV token : ${AV_SITE_TOKEN:0:6}... (truncated)"
echo "  AV .deb  : $(basename "$AV_DEB")"
echo "  RMM URL  : $RMM_INSTALL_URL"
echo ""
read -rp "Proceed? (y/N) " CONFIRM
[[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

# =============================================================================
# STEP 1 — Hostname
# =============================================================================

echo ""
echo "[1/4] Setting hostname to '$HOSTNAME'..."
hostnamectl set-hostname "$HOSTNAME"
if grep -q "^127.0.1.1" /etc/hosts; then
    sed -i "s/127.0.1.1.*/127.0.1.1\t${HOSTNAME}/" /etc/hosts
else
    echo -e "127.0.1.1\t${HOSTNAME}" >> /etc/hosts
fi
echo "  Done."

# =============================================================================
# STEP 2 — Antivirus
# =============================================================================

echo ""
echo "[2/4] Installing Antivirus..."
dpkg -i "$AV_DEB"
/opt/sentinelone/bin/sentinelctl management token set "$AV_SITE_TOKEN"
/opt/sentinelone/bin/sentinelctl control start
echo "  Done."

# =============================================================================
# STEP 3 — Atera
# =============================================================================

echo ""
echo "[3/4] Installing RMM agent..."
curl -fsSL "$RMM_INSTALL_URL" -o /tmp/rmm-install.sh
chmod +x /tmp/rmm-install.sh
bash /tmp/rmm-install.sh
rm -f /tmp/rmm-install.sh
echo "  Done."

# =============================================================================
# STEP 4 — Halloy IRC config
# =============================================================================

echo ""
echo "[4/4] Installing Halloy config..."
HALLOY_DIR="/home/callcentervillage/.var/app/org.squidowl.halloy/config/halloy"
mkdir -p "$HALLOY_DIR"
sed "s/nickname = \"ccvXX\"/nickname = \"$HOSTNAME\"/" "$SCRIPT_DIR/halloy.toml" > "$HALLOY_DIR/config.toml"
chown -R callcentervillage:callcentervillage "$HALLOY_DIR"
echo "  Done."

# =============================================================================
# Done
# =============================================================================

echo ""
echo "========================================"
echo " Setup complete! — $(date)"
echo " Log saved to: $LOG_FILE"
echo "========================================"
