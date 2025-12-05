#!/bin/bash
#
# Pi-hole Sync Setup Script
# Sets up the synchronization system on both primary and secondary servers
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Pi-hole Sync Setup${NC}"
echo -e "${BLUE}================================${NC}"
echo

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

# Prompt for password
echo -e "${YELLOW}Enter the sync password:${NC}"
read -s SYNC_PASSWORD
echo
echo -e "${YELLOW}Confirm password:${NC}"
read -s SYNC_PASSWORD_CONFIRM
echo

if [ "$SYNC_PASSWORD" != "$SYNC_PASSWORD_CONFIRM" ]; then
    echo -e "${RED}Passwords do not match!${NC}"
    exit 1
fi

# Generate hash
PASSWORD_HASH=$(echo -n "$SYNC_PASSWORD" | sha256sum | awk '{print $1}')
echo -e "${GREEN}✓ Password hash generated${NC}"

# Load current environment or create new
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}Creating new environment file...${NC}"
    cat > "$ENV_FILE" << EOF
# Pi-hole Sync Environment Configuration
PASSWORD_HASH="${PASSWORD_HASH}"
SECONDARY_IP="172.31.250.9"
SECONDARY_USER="wiiccoadmin"
PRIMARY_IP="172.31.250.8"
PRIMARY_USER="wiiccoadmin"
EOF
    chmod 600 "$ENV_FILE"
    echo -e "${GREEN}✓ Environment file created${NC}"
else
    # Update existing
    sed -i "s/^PASSWORD_HASH=.*/PASSWORD_HASH=\"${PASSWORD_HASH}\"/" "$ENV_FILE"
    echo -e "${GREEN}✓ Environment file updated${NC}"
fi

# Check for required packages
echo
echo -e "${YELLOW}Checking required packages...${NC}"
PACKAGES_TO_INSTALL=()

if ! command -v sshpass &> /dev/null; then
    PACKAGES_TO_INSTALL+=(sshpass)
fi

if ! command -v sqlite3 &> /dev/null; then
    PACKAGES_TO_INSTALL+=(sqlite3)
fi

if [ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]; then
    echo -e "${YELLOW}Installing: ${PACKAGES_TO_INSTALL[*]}${NC}"
    apt-get update -qq
    apt-get install -y "${PACKAGES_TO_INSTALL[@]}"
    echo -e "${GREEN}✓ Packages installed${NC}"
else
    echo -e "${GREEN}✓ All required packages present${NC}"
fi

# Create log file
touch /var/log/pihole-sync.log
chmod 644 /var/log/pihole-sync.log
echo -e "${GREEN}✓ Log file created${NC}"

# Test connection to secondary
echo
echo -e "${YELLOW}Testing connection to secondary server...${NC}"
source "$ENV_FILE"

if sshpass -p "$SYNC_PASSWORD" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
    ${SECONDARY_USER}@${SECONDARY_IP} "echo 'Connection successful'" 2>/dev/null | grep -q "Connection successful"; then
    echo -e "${GREEN}✓ Connection to secondary server successful${NC}"
else
    echo -e "${RED}✗ Failed to connect to secondary server${NC}"
    echo -e "${YELLOW}Please ensure:${NC}"
    echo "  1. Secondary server is accessible at ${SECONDARY_IP}"
    echo "  2. User ${SECONDARY_USER} exists on secondary"
    echo "  3. Password is correct"
    echo "  4. SSH is enabled and accessible"
    exit 1
fi

# Setup cron job
echo
echo -e "${YELLOW}Setting up cron job...${NC}"
CRON_CMD="*/5 * * * * ${SCRIPT_DIR}/pihole-sync-cron.sh >> /var/log/pihole-sync.log 2>&1"

# Remove old cron jobs
crontab -l 2>/dev/null | grep -v "pihole-sync" | crontab - 2>/dev/null || true

# Add new cron job
(crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -

echo -e "${GREEN}✓ Cron job installed (runs every 5 minutes)${NC}"

# Run initial sync
echo
echo -e "${YELLOW}Running initial sync test...${NC}"
export SYNC_PASSWORD
if "${SCRIPT_DIR}/pihole-sync.sh"; then
    echo -e "${GREEN}✓ Initial sync completed successfully${NC}"
else
    echo -e "${RED}✗ Initial sync failed - check /var/log/pihole-sync.log for details${NC}"
    exit 1
fi

# Clear password
unset SYNC_PASSWORD
unset SYNC_PASSWORD_CONFIRM

echo
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo
echo "Configuration:"
echo "  - Scripts location: ${SCRIPT_DIR}"
echo "  - Environment file: ${ENV_FILE}"
echo "  - Log file: /var/log/pihole-sync.log"
echo "  - Sync interval: Every 5 minutes"
echo
echo "To manually trigger sync:"
echo "  sudo ${SCRIPT_DIR}/pihole-sync.sh"
echo
echo "To view logs:"
echo "  tail -f /var/log/pihole-sync.log"
echo