#!/bin/bash
#
# Pi-hole Primary to Secondary Sync Script (Secure Version)
# Syncs ns01 (172.31.250.8) -> ns02 (172.31.250.9)
#
# Uses SHA256 password hash verification and secure password handling
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
LOG_FILE="/var/log/pihole-sync.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error_exit() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    log_message "ERROR: $1"
    exit 1
}

# Load environment variables
if [ ! -f "$ENV_FILE" ]; then
    error_exit "Environment file not found: $ENV_FILE"
fi

source "$ENV_FILE"

# Verify required variables
[ -z "$PASSWORD_HASH" ] && error_exit "PASSWORD_HASH not set in $ENV_FILE"
[ -z "$SECONDARY_IP" ] && error_exit "SECONDARY_IP not set in $ENV_FILE"
[ -z "$SECONDARY_USER" ] && error_exit "SECONDARY_USER not set in $ENV_FILE"

# Check if password is provided as environment variable or prompt for it
if [ -z "$SYNC_PASSWORD" ]; then
    # Check if running interactively
    if [ -t 0 ]; then
        echo -e "${YELLOW}Please enter the sync password:${NC}"
        read -s SYNC_PASSWORD
        echo
    else
        error_exit "SYNC_PASSWORD not set and script is not running interactively"
    fi
fi

# Verify password hash
ENTERED_HASH=$(echo -n "$SYNC_PASSWORD" | sha256sum | awk '{print $1}')
if [ "$ENTERED_HASH" != "$PASSWORD_HASH" ]; then
    error_exit "Invalid password"
fi

remote_exec() {
    sshpass -p "$SYNC_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR \
        ${SECONDARY_USER}@${SECONDARY_IP} "$1" 2>&1
}

copy_to_secondary() {
    sshpass -p "$SYNC_PASSWORD" scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR \
        "$1" ${SECONDARY_USER}@${SECONDARY_IP}:"$2" 2>&1
}

log_message "====== Starting Pi-hole Sync ======"

# Sync gravity database
log_message "Syncing gravity database..."
copy_to_secondary /etc/pihole/gravity.db /tmp/gravity.db.new
if [ $? -eq 0 ]; then
    remote_exec "sudo mv /tmp/gravity.db.new /etc/pihole/gravity.db && sudo chown pihole:pihole /etc/pihole/gravity.db && sudo chmod 644 /etc/pihole/gravity.db"
    log_message "Gravity synced"
else
    log_message "ERROR: Gravity sync failed"
fi

# Sync configuration files
for file in custom.list local.list adlists.list regex.list whitelist.txt blacklist.txt pihole.toml; do
    if [ -f /etc/pihole/$file ]; then
        log_message "Syncing $file..."
        copy_to_secondary /etc/pihole/$file /tmp/${file}.new
        remote_exec "sudo mv /tmp/${file}.new /etc/pihole/$file && sudo chown pihole:pihole /etc/pihole/$file && sudo chmod 644 /etc/pihole/$file"
    fi
done

# Sync dnsmasq configs
for file in 01-pihole.conf 02-pihole-dhcp.conf 04-pihole-static-dhcp.conf 05-pihole-custom-cname.conf; do
    if [ -f /etc/dnsmasq.d/$file ]; then
        log_message "Syncing $file..."
        copy_to_secondary /etc/dnsmasq.d/$file /tmp/${file}.new
        remote_exec "sudo mv /tmp/${file}.new /etc/dnsmasq.d/$file && sudo chown root:root /etc/dnsmasq.d/$file && sudo chmod 644 /etc/dnsmasq.d/$file"
    fi
done

# Sync DHCP leases
if [ -f /etc/pihole/dhcp.leases ]; then
    log_message "Syncing DHCP leases..."
    copy_to_secondary /etc/pihole/dhcp.leases /tmp/dhcp.leases.new
    remote_exec "sudo mv /tmp/dhcp.leases.new /etc/pihole/dhcp.leases && sudo chown pihole:pihole /etc/pihole/dhcp.leases"
fi

# Reload DNS
log_message "Reloading DNS on secondary..."
remote_exec "sudo pihole restartdns" >/dev/null 2>&1 && log_message "DNS reloaded" || log_message "WARNING: DNS reload failed"

# Verify
SECONDARY_COUNT=$(remote_exec "sudo sqlite3 /etc/pihole/gravity.db 'SELECT COUNT(*) FROM gravity;'" 2>/dev/null | tail -1)
PRIMARY_COUNT=$(sqlite3 /etc/pihole/gravity.db 'SELECT COUNT(*) FROM gravity;' 2>/dev/null)
log_message "Verification: Primary=$PRIMARY_COUNT Secondary=$SECONDARY_COUNT"
[ "$PRIMARY_COUNT" == "$SECONDARY_COUNT" ] && log_message "✓ Sync verified" || log_message "⚠ Count mismatch"
log_message "====== Sync Complete ======"

# Clear password from memory
unset SYNC_PASSWORD
unset ENTERED_HASH

exit 0