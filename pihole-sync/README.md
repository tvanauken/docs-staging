# Pi-hole Sync System - Secure Version

This directory contains the secure Pi-hole synchronization system that uses SHA256 password hashing and secure credential management.

## Files

- `setup.sh` - Installation and configuration script
- `pihole-sync.sh` - Main synchronization script (interactive or with password prompt)
- `pihole-sync-cron.sh` - Wrapper for automated cron execution
- `.env` - Environment configuration (contains password hash)
- `.env.example` - Example environment file
- `README.md` - This file

## Password Hash

The system uses SHA256 hashing for password verification:
- **Password:** `Wiicco@111!!`
- **SHA256 Hash:** `e7d419feaa380d28aca62d603fc8926b77223c2c7651b30232199bf9eb67d143`

## Initial Setup

### On Primary Server (ns01 - 172.31.250.8)

1. Run the setup script:
   ```bash
   sudo /opt/pihole-sync/setup.sh
   ```

2. When prompted, enter the password: `Wiicco@111!!`

3. The script will:
   - Generate and store the password hash
   - Install required packages (sshpass, sqlite3)
   - Test connection to secondary server
   - Setup cron job (runs every 5 minutes)
   - Perform initial sync

### On Secondary Server (ns02 - 172.31.250.9)

Ensure the user `wiiccoadmin` exists with:
```bash
sudo useradd -m -s /bin/bash -G sudo wiiccoadmin
echo 'wiiccoadmin:Wiicco@111!!' | sudo chpasswd
echo "wiiccoadmin ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/wiiccoadmin
sudo chmod 440 /etc/sudoers.d/wiiccoadmin
```

## Manual Sync

To manually trigger a sync (will prompt for password):
```bash
sudo /opt/pihole-sync/pihole-sync.sh
```

Or provide password via environment variable:
```bash
sudo SYNC_PASSWORD='Wiicco@111!!' /opt/pihole-sync/pihole-sync.sh
```

## Monitoring

View sync logs:
```bash
tail -f /var/log/pihole-sync.log
```

Check recent syncs:
```bash
sudo grep "Sync Complete" /var/log/pihole-sync.log | tail -10
```

Check for errors:
```bash
sudo grep "ERROR" /var/log/pihole-sync.log
```

## Cron Schedule

The sync runs automatically every 5 minutes via cron:
```
*/5 * * * * /opt/pihole-sync/pihole-sync-cron.sh >> /var/log/pihole-sync.log 2>&1
```

View current cron jobs:
```bash
sudo crontab -l
```

## Security Features

1. **Password Hashing:** Passwords are verified using SHA256 hashes
2. **No Plaintext Storage:** Primary password only in memory during execution
3. **Secure Permissions:**
   - `.env` file: `600` (readable only by owner)
   - Scripts: `750` (executable by owner and group)
   - Directory: `750` (accessible by owner and group)
4. **Memory Cleanup:** Passwords unset after use

## Configuration

Edit `.env` file to change settings:
```bash
sudo nano /opt/pihole-sync/.env
```

Configuration options:
- `PASSWORD_HASH` - SHA256 hash of sync password
- `SECONDARY_IP` - IP address of secondary server
- `SECONDARY_USER` - Username on secondary server
- `PRIMARY_IP` - IP address of primary server (reference)
- `PRIMARY_USER` - Username on primary server (reference)

## Troubleshooting

### Connection Failed
Check:
1. Secondary server is online: `ping 172.31.250.9`
2. SSH is accessible: `ssh wiiccoadmin@172.31.250.9`
3. Password is correct
4. User has sudo privileges on secondary

### Sync Failed
Check logs for details:
```bash
sudo tail -50 /var/log/pihole-sync.log
```

### Verify Configuration
Test connection:
```bash
sshpass -p 'Wiicco@111!!' ssh wiiccoadmin@172.31.250.9 'echo Success'
```

## Files Synchronized

The system syncs these files from primary to secondary:

**Pi-hole Database:**
- `/etc/pihole/gravity.db`

**Configuration Files:**
- `/etc/pihole/custom.list`
- `/etc/pihole/local.list`
- `/etc/pihole/adlists.list`
- `/etc/pihole/regex.list`
- `/etc/pihole/whitelist.txt`
- `/etc/pihole/blacklist.txt`
- `/etc/pihole/pihole.toml`

**dnsmasq Configuration:**
- `/etc/dnsmasq.d/01-pihole.conf`
- `/etc/dnsmasq.d/02-pihole-dhcp.conf`
- `/etc/dnsmasq.d/04-pihole-static-dhcp.conf`
- `/etc/dnsmasq.d/05-pihole-custom-cname.conf`

**DHCP Data:**
- `/etc/pihole/dhcp.leases`

## Maintenance

### Update Password

1. Run setup script again:
   ```bash
   sudo /opt/pihole-sync/setup.sh
   ```

2. Enter new password when prompted

### Reinstall Cron Job

```bash
sudo /opt/pihole-sync/setup.sh
```

### Remove Sync System

```bash
sudo crontab -l | grep -v pihole-sync | sudo crontab -
sudo rm -rf /opt/pihole-sync
sudo rm -f /var/log/pihole-sync.log
```

## Support

For issues or questions:
1. Check logs: `/var/log/pihole-sync.log`
2. Verify connectivity between servers
3. Ensure both servers have matching Pi-hole versions
4. Review Pi-hole documentation: https://docs.pi-hole.net/

---

**Last Updated:** December 5, 2025  
**Version:** 2.0 (Secure)