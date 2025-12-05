# Changelog

All notable changes to the Pi-hole Sync System will be documented in this file.

## [2.0.0] - 2025-12-05

### Changed - Credential Update
- **Username changed** from `tvanauken` to `wiiccoadmin`
- **Password changed** from `VanAwsome1` to `Wiicco@111!!`
- **Password Hash (SHA256):** `e7d419feaa380d28aca62d603fc8926b77223c2c7651b30232199bf9eb67d143`

### Security Enhancements
- Implemented SHA256 password hashing for verification
- Passwords no longer stored in plaintext
- Added memory cleanup after password use
- Secure file permissions (600) for .env file
- Added .gitignore to prevent committing sensitive credentials

### Scripts Updated
- `setup.sh` - Interactive setup with password hashing
- `pihole-sync.sh` - Main sync script with secure authentication
- `pihole-sync-cron.sh` - Automated cron wrapper with new credentials
- `.env` - Configuration file with new user and password hash
- `.env.example` - Template without actual credentials

### Documentation
- Complete rewrite of README.md
- Added detailed setup instructions
- Added troubleshooting section
- Added security features documentation
- Added monitoring and maintenance procedures

### Server Configuration
- Primary Server: ns01 (172.31.250.8) - User: wiiccoadmin
- Secondary Server: ns02 (172.31.250.9) - User: wiiccoadmin

### Files Synchronized
- Pi-hole database: `/etc/pihole/gravity.db`
- Configuration files: custom.list, local.list, adlists.list, regex.list, etc.
- dnsmasq configuration files
- DHCP leases

### Automation
- Cron job runs every 5 minutes
- Automatic verification after sync
- Comprehensive logging to `/var/log/pihole-sync.log`

## [1.0.0] - Previous Version

### Initial Implementation
- Basic sync functionality
- Used plaintext credentials
- Username: tvanauken
- Password: VanAwsome1