#!/bin/bash
#
# Pi-hole Sync Cron Wrapper
# This script provides the password from environment for automated runs
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment
source "${SCRIPT_DIR}/.env"

# Derive password from hash (this should be updated with actual password storage method)
# For now, we'll use the password directly in environment variable
# In production, consider using a secrets management system

# Export password for the main script
export SYNC_PASSWORD="Wiicco@111!!"

# Run the sync script
"${SCRIPT_DIR}/pihole-sync.sh"

# Clear password
unset SYNC_PASSWORD