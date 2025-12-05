# Pi-hole Infrastructure Documentation

**Project:** Dual Pi-hole DNS Server Setup with Automatic Synchronization  
**Author:** System Documentation  
**Date:** December 5, 2025  
**Version:** 1.0

## Table of Contents

1. [Overview](#overview)
2. [Infrastructure Architecture](#infrastructure-architecture)
3. [Server Specifications](#server-specifications)
4. [Operating System Configuration](#operating-system-configuration)
5. [Pi-hole Configuration](#pi-hole-configuration)
6. [Automatic Synchronization System](#automatic-synchronization-system)
7. [Network Configuration](#network-configuration)
8. [Maintenance & Monitoring](#maintenance--monitoring)
9. [Troubleshooting](#troubleshooting)
10. [Appendix](#appendix)

---

## Overview

This document provides complete documentation for a dual Pi-hole DNS server infrastructure with automatic configuration synchronization. The system consists of:

- **Primary DNS Server (ns01):** 172.31.250.8
- **Secondary DNS Server (ns02):** 172.31.250.9
- **Automatic Sync:** 5-minute interval synchronization from primary to secondary

### Key Features

- ✅ Redundant DNS infrastructure for high availability
- ✅ Network-wide ad blocking and tracking protection
- ✅ Automatic configuration replication
- ✅ 5.6+ million blocked domains across 30 curated blocklists
- ✅ Custom allowlist/denylist management
- ✅ DHCP capability (optional)
- ✅ Local DNS record management

---

## Infrastructure Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Network Clients                         │
│         (Desktops, Laptops, Mobile Devices, etc.)           │
└────────────┬─────────────────────────┬──────────────────────┘
             │                         │
             │ DNS Queries             │ DNS Queries
             ▼                         ▼
    ┌────────────────┐        ┌────────────────┐
    │  Primary DNS   │        │ Secondary DNS  │
    │     (ns01)     │◄──────►│     (ns02)     │
    │ 172.31.250.8   │  Sync  │ 172.31.250.9   │
    └────────────────┘        └────────────────┘
             │                         │
             │ Upstream DNS            │ Upstream DNS
             ▼                         ▼
    ┌─────────────────────────────────────────┐
    │         Internet / Upstream DNS         │
    └─────────────────────────────────────────┘
```

### Data Flow

1. **Client DNS Requests:** Network clients query primary (172.31.250.8) or secondary (172.31.250.9)
2. **Ad Filtering:** Pi-hole checks domain against gravity database (5.6M+ blocked domains)
3. **Upstream Resolution:** If not blocked, query forwarded to upstream DNS servers
4. **Automatic Sync:** Every 5 minutes, primary syncs all configuration to secondary
5. **Failover:** If primary is unavailable, clients automatically use secondary

---

## Server Specifications

### Primary Server (ns01)

| Property | Value |
|----------|-------|
| **Hostname** | ns01 |
| **FQDN** | ns01.anchor.gammatime.ai |
| **IP Address** | 172.31.250.8 |
| **Operating System** | Debian GNU/Linux 12 (bookworm) |
| **Architecture** | amd64 |
| **Pi-hole Version** | v6.3 (Core), v6.4 (Web) |
| **Role** | Primary DNS Server (source for sync) |
| **Web Interface** | http://172.31.250.8/admin |

### Secondary Server (ns02)

| Property | Value |
|----------|-------|
| **Hostname** | ns02 |
| **FQDN** | ns02.anchor.gammatime.ai |
| **IP Address** | 172.31.250.9 |
| **Operating System** | Ubuntu 24.04 LTS (Noble Numbat) |
| **Architecture** | ARM64/v8 |
| **Pi-hole Version** | v6.3 (Core), v6.4 (Web) |
| **Role** | Secondary DNS Server (destination for sync) |
| **Web Interface** | http://172.31.250.9/admin |

---

## Operating System Configuration

### Network Configuration

#### ns01 (Primary Server)

**Hostname Configuration:**
```bash
# /etc/hostname
ns01.anchor.gammatime.ai
```

**Hosts File:**
```bash
# /etc/hosts
127.0.0.1       localhost
127.0.1.1       ns01.anchor.gammatime.ai ns01
172.31.250.8    ns01.anchor.gammatime.ai ns01

# IPv6
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```

**Static IP Configuration:**
- Interface: Configured via network manager or netplan
- IP: 172.31.250.8/24
- Gateway: (As configured in your network)
- DNS: 127.0.0.1 (self)

#### ns02 (Secondary Server)

**Hostname Configuration:**
```bash
# /etc/hostname
ns02.anchor.gammatime.ai
```

**Hosts File:**
```bash
# /etc/hosts
127.0.0.1       localhost
127.0.1.1       ns02.anchor.gammatime.ai ns02
172.31.250.9    ns02.anchor.gammatime.ai ns02

# IPv6
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```

**Static IP Configuration:**
- Interface: Configured via network manager or netplan
- IP: 172.31.250.9/24
- Gateway: (As configured in your network)
- DNS: 127.0.0.1 (self)

### User Configuration

#### Sync User Account (Both Servers)

**Username:** `tvanauken`  
**Purpose:** Administrative access and sync operations  
**Groups:** `sudo`, `adm`, `netdev`

**Sudo Configuration:**
```bash
# /etc/sudoers.d/tvanauken
tvanauken ALL=(ALL) NOPASSWD: ALL
```

**Permissions:** `440 (r--r-----)`

This configuration allows passwordless sudo for automated sync operations.

### SSH Configuration

**Service Status:** Active and enabled  
**Port:** 22 (default)  
**Authentication:** Password authentication enabled  
**Key-based Auth:** Recommended but not required

**SSH Access Test:**
```bash
# From any server, test SSH connectivity
ssh tvanauken@172.31.250.8
ssh tvanauken@172.31.250.9
```

### Installed Packages (Sync-Related)

#### Primary Server (ns01)
```bash
- pihole-FTL (Pi-hole core)
- lighttpd (web server)
- sqlite3 (database management)
- sshpass (automated SSH operations)
- git (version control)
```

#### Secondary Server (ns02)
```bash
- pihole-FTL (Pi-hole core)
- lighttpd (web server)
- sqlite3 (database management)
- sshpass (automated SSH operations)
```

---

## Pi-hole Configuration

### Core Settings

Both servers maintain identical Pi-hole configurations that are automatically synchronized.

#### Blocking Configuration

| Setting | Value |
|---------|-------|
| **Total Gravity Domains** | 5,623,210 blocked domains |
| **Unique Domains** | 5,439,716 unique blocked domains |
| **Enabled Blocklists** | 30 active lists |
| **Allowlist Entries** | 132 domains |
| **Denylist Entries** | 3 domains (Ring.com related) |
| **Regex Allow Filters** | 1 |
| **Regex Deny Filters** | 1 |

#### Custom Groups

Pi-hole groups organize blocklists and domain lists into categories:

| ID | Name | Purpose | Status |
|----|------|---------|--------|
| 0 | Default | System default group | Enabled |
| 1 | Suspicious | Suspicious domains and activities | Enabled |
| 3 | Advertising | Ad-serving domains | Enabled |
| 5 | Malicious | Malware, phishing, crypto-mining | Enabled |
| 7 | Other Lists | Adult content, explicit material | Enabled |
| 11 | Whitelist | Exceptions and allowed domains | Enabled |
| 12 | Tracking & Telemetry | Tracking scripts and analytics | Enabled |

### Blocklists Configuration

#### Complete Blocklist Inventory

##### Category: Default
1. **StevenBlack Hosts** (Group 0)
   - URL: `https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts`
   - Domains: ~85,644
   - Description: Unified hosts file with base extensions

##### Category: Suspicious (Group 1)
2. **KADhosts**
   - URL: `https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt`
   - Domains: ~54,262
   - Source: Polish Filters Team

3. **FadeMind - Spam Hosts**
   - URL: `https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts`
   - Domains: ~57

4. **Firebog - Static W3KBL**
   - URL: `https://v.firebog.net/hosts/static/w3kbl.txt`
   - Domains: ~355

##### Category: Advertising (Group 3)
5. **AdAway Hosts**
   - URL: `https://adaway.org/hosts.txt`
   - Domains: ~6,540

6. **AdGuard DNS**
   - URL: `https://v.firebog.net/hosts/AdguardDNS.txt`
   - Domains: ~121,832

7. **Admiral**
   - URL: `https://v.firebog.net/hosts/Admiral.txt`
   - Domains: ~1,746

8. **AnudeepND Blacklist**
   - URL: `https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt`
   - Domains: ~42,536

9. **Easylist**
   - URL: `https://v.firebog.net/hosts/Easylist.txt`
   - Domains: ~42,225

10. **Pgl.yoyo Adservers**
    - URL: `https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext`
    - Domains: ~3,478

11. **UncheckyAds**
    - URL: `https://raw.githubusercontent.com/FadeMind/hosts.extras/master/UncheckyAds/hosts`
    - Domains: ~9

12. **HostsVN**
    - URL: `https://raw.githubusercontent.com/bigdargon/hostsVN/master/hosts`
    - Domains: ~19,112

##### Category: Tracking & Telemetry (Group 12)
13. **Easyprivacy**
    - URL: `https://v.firebog.net/hosts/Easyprivacy.txt`
    - Domains: ~42,156

14. **Prigent Ads**
    - URL: `https://v.firebog.net/hosts/Prigent-Ads.txt`
    - Domains: ~4,270

15. **2o7Net**
    - URL: `https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts`
    - Domains: ~2,030

16. **Windows Spy Blocker**
    - URL: `https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt`
    - Domains: ~347

17. **FirstParty Trackers**
    - URL: `https://hostfiles.frogeye.fr/firstparty-trackers-hosts.txt`
    - Domains: ~32,301

##### Category: Malicious (Group 5)
18. **DandelionSprout Anti-Malware**
    - URL: `https://raw.githubusercontent.com/DandelionSprout/adfilt/master/Alternate%20versions%20Anti-Malware%20List/AntiMalwareHosts.txt`
    - Domains: ~14,604

19. **Prigent Crypto**
    - URL: `https://v.firebog.net/hosts/Prigent-Crypto.txt`
    - Domains: ~16,288

20. **FadeMind Risk**
    - URL: `https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Risk/hosts`
    - Domains: ~2,189

21. **Mandiant APT1**
    - URL: `https://bitbucket.org/ethanr/dns-blacklists/raw/8575c9f96e5b4a1308f2f12394abd86d0927a4a0/bad_lists/Mandiant_APT1_Report_Appendix_D.txt`
    - Domains: ~2,046

22. **Phishing Army Extended**
    - URL: `https://phishing.army/download/phishing_army_blocklist_extended.txt`
    - Domains: ~159,299

23. **NoTrack Malware**
    - URL: `https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-malware.txt`
    - Domains: ~141

24. **RPiList Malware**
    - URL: `https://v.firebog.net/hosts/RPiList-Malware.txt`
    - Domains: ~290,974 (ABP-style)

25. **Spam404**
    - URL: `https://raw.githubusercontent.com/Spam404/lists/master/main-blacklist.txt`
    - Domains: ~8,140

26. **Stalkerware Indicators**
    - URL: `https://raw.githubusercontent.com/AssoEchap/stalkerware-indicators/master/generated/hosts`
    - Domains: ~919

27. **URLhaus Abuse.ch**
    - URL: `https://urlhaus.abuse.ch/downloads/hostfile/`
    - Domains: ~758

28. **CyberHost Malware**
    - URL: `https://lists.cyberhost.uk/malware.txt`
    - Domains: ~20,091

##### Category: Other Lists - Adult Content (Group 7)
29. **Chad Mayfield Porn Top 1M**
    - URL: `https://raw.githubusercontent.com/chadmayfield/my-pihole-blocklists/master/lists/pi_blocklist_porn_top1m.list`
    - Domains: ~11,868

30. **Prigent Adult**
    - URL: `https://v.firebog.net/hosts/Prigent-Adult.txt`
    - Domains: ~4,646,762
    - Note: Largest list, covers extensive adult content

### Allowlist Configuration

The allowlist contains 132 domains that are explicitly allowed despite appearing in blocklists. These are essential services:

#### Google Services (15 domains)
```
googleapis.l.google.com
clients4.google.com
clients2.google.com
s.youtube.com
video-stats.l.google.com
www.googleapis.com
youtubei.googleapis.com
oauthaccountmanager.googleapis.com
android.clients.google.com
gstaticadssl.l.google.com
dl.google.com
redirector.gvt1.com
^((alt)[0-9](-))?mtalk\.google\.com$  # Regex for Google Talk
```

#### Microsoft Services (10 domains)
```
msedge.api.cdp.microsoft.com
sls.update.microsoft.com.akadns.net
fe3.delivery.dsp.mp.microsoft.com.nsatc.net
tlu.dl.delivery.mp.microsoft.com
dl.delivery.mp.microsoft.com
geo-prod.do.dsp.mp.microsoft.com
displaycatalog.mp.microsoft.com
outlook.office365.com
products.office.com
c.s-microsoft.com
i.s-microsoft.com
login.live.com
login.microsoftonline.com
officeclient.microsoft.com
```

#### Apple Services (11 domains)
```
ca.iadsdk.apple.com
itunes.apple.com
s.mzstatic.com
appleid.apple.com
captive.apple.com
gsp1.apple.com
www.apple.com
www.appleiphonecell.com
```

#### Facebook/Meta Services (25 domains)
```
upload.facebook.com
creative.ak.fbcdn.net
external-lhr0-1.xx.fbcdn.net
[... and 22 more Facebook CDN domains]
graph.facebook.com
b-graph.facebook.com
connect.facebook.com
api.facebook.com
edge-mqtt.facebook.com
www.facebook.com
web.facebook.com
```

#### Plex Services (23 domains)
```
plex.tv
tvdb2.plex.tv
pubsub.plex.bz
proxy.plex.bz
meta.plex.bz
tvthemes.plexapp.com
meta.plex.tv
proxy.plex.tv
metrics.plex.tv
pubsub.plex.tv
status.plex.tv
www.plex.tv
app.plex.tv
dashboard.plex.tv
[... and more]
```

#### Communication Services
- **Spotify:** `spclient.wg.spotify.com`, `apresolve.spotify.com`
- **WhatsApp:** `wa.me`, `www.wa.me`
- **Signal:** Multiple domains for Signal messaging app

#### Other Services
- **Dropbox:** `dl.dropboxusercontent.com`, `ns1.dropbox.com`, `ns2.dropbox.com`
- **NVIDIA:** `gfwsl.geforce.com`
- **Hulu:** `ads-a-darwin.hulustream.com`, `ads-fa-darwin.hulustream.com`
- **GoDaddy:** `imagesak.secureserver.net`

### Denylist Configuration

Custom blocked domains (3 entries):

```
# Ring.com blocking (privacy concerns)
az.ring.com                 # Exact match
account.ring.com            # Exact match
(\.|^)ring\.com$           # Regex - blocks all Ring.com subdomains
```

**Reasoning:** User requested blocking of Ring camera services for privacy concerns.

### DNS Settings

#### Upstream DNS Servers
Pi-hole forwards unblocked queries to these upstream DNS servers:

**Primary Upstream:**
- Configuration managed via Pi-hole web interface
- Default: System DNS or custom configured

**DNS Query Handling:**
1. Client queries Pi-hole
2. Pi-hole checks local cache
3. Pi-hole checks gravity database (blocked?)
4. If not blocked, forward to upstream DNS
5. Cache result for future queries

#### DNSSEC
- Status: Configurable via web interface
- Validates DNS responses cryptographically

#### Conditional Forwarding
- Purpose: Resolve local hostnames
- Configuration: Via Pi-hole web interface

### DHCP Configuration

**Current Status:** DHCP can be enabled/disabled as needed  
**Configuration File:** `/etc/dnsmasq.d/02-pihole-dhcp.conf`

If DHCP is enabled, Pi-hole can serve as the network DHCP server, automatically configuring clients to use it as their DNS server.

### Local DNS Records

**Configuration File:** `/etc/pihole/custom.list`

Format:
```
<IP_ADDRESS>    <HOSTNAME>
```

Example:
```
192.168.1.10    server.local
192.168.1.20    nas.local
```

### CNAME Records

**Configuration File:** `/etc/dnsmasq.d/05-pihole-custom-cname.conf`

Format:
```
cname=<alias>,<target>
```

Example:
```
cname=nas.local,storage.local
```

---

## Automatic Synchronization System

### Overview

The automatic synchronization system ensures that any configuration changes made on the primary server (ns01) are automatically replicated to the secondary server (ns02) every 5 minutes.

### Architecture

```
┌─────────────────────────────────────┐
│   Primary Server (ns01)              │
│   172.31.250.8                       │
│                                      │
│   ┌──────────────────────────────┐  │
│   │  Cron Job (*/5 * * * *)      │  │
│   │  Triggers every 5 minutes    │  │
│   └──────────┬───────────────────┘  │
│              │                       │
│              ▼                       │
│   ┌──────────────────────────────┐  │
│   │  /usr/local/bin/             │  │
│   │  pihole-sync.sh              │  │
│   │                               │  │
│   │  1. Copy gravity.db          │  │
│   │  2. Copy config files        │  │
│   │  3. Copy dnsmasq configs     │  │
│   │  4. Copy DHCP leases         │  │
│   │  5. Reload DNS on secondary  │  │
│   │  6. Verify sync              │  │
│   └──────────┬───────────────────┘  │
│              │                       │
│              │ SSH/SCP               │
└──────────────┼───────────────────────┘
               │
               │ (Password: VanAwsome1)
               │ (User: tvanauken)
               │
               ▼
┌──────────────────────────────────────┐
│   Secondary Server (ns02)             │
│   172.31.250.9                        │
│                                       │
│   Files received and placed:          │
│   • /etc/pihole/gravity.db           │
│   • /etc/pihole/*.list               │
│   • /etc/pihole/pihole.toml          │
│   • /etc/dnsmasq.d/*.conf            │
│   • /etc/pihole/dhcp.leases          │
│                                       │
│   DNS service reloaded automatically  │
└───────────────────────────────────────┘
```

### Sync Script Details

#### Location
- **Primary Server:** `/usr/local/bin/pihole-sync.sh`
- **Permissions:** `755 (rwxr-xr-x)`
- **Owner:** `root:root`

#### Complete Script Source Code

```bash
#!/bin/bash
#
# Pi-hole Primary to Secondary Sync Script
# Syncs ns01 (172.31.250.8) -> ns02 (172.31.250.9)
#

SECONDARY_IP="172.31.250.9"
SECONDARY_USER="tvanauken"
SECONDARY_PASS="VanAwsome1"
LOG_FILE="/var/log/pihole-sync.log"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

remote_exec() {
    sshpass -p "$SECONDARY_PASS" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR \
        ${SECONDARY_USER}@${SECONDARY_IP} "$1" 2>&1
}

copy_to_secondary() {
    sshpass -p "$SECONDARY_PASS" scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR \
        "$1" ${SECONDARY_USER}@${SECONDARY_IP}:"$2" 2>&1
}

log_message "====== Starting Pi-hole Sync ======"

# Sync gravity database
log_message "Syncing gravity database..."
copy_to_secondary /etc/pihole/gravity.db /tmp/gravity.db.new
[ $? -eq 0 ] && remote_exec "sudo mv /tmp/gravity.db.new /etc/pihole/gravity.db && sudo chown pihole:pihole /etc/pihole/gravity.db && sudo chmod 644 /etc/pihole/gravity.db" && log_message "Gravity synced" || log_message "ERROR: Gravity sync failed"

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
remote_exec "sudo pihole reloaddns" >/dev/null 2>&1 && log_message "DNS reloaded" || log_message "WARNING: DNS reload failed"

# Verify
SECONDARY_COUNT=$(remote_exec "sudo sqlite3 /etc/pihole/gravity.db 'SELECT COUNT(*) FROM gravity;'" 2>/dev/null | tail -1)
PRIMARY_COUNT=$(sqlite3 /etc/pihole/gravity.db 'SELECT COUNT(*) FROM gravity;' 2>/dev/null)
log_message "Verification: Primary=$PRIMARY_COUNT Secondary=$SECONDARY_COUNT"
[ "$PRIMARY_COUNT" == "$SECONDARY_COUNT" ] && log_message "✓ Sync verified" || log_message "⚠ Count mismatch"
log_message "====== Sync Complete ======"

exit 0
```

#### Files Synchronized

The sync script synchronizes the following files and configurations:

**Critical Database:**
1. `/etc/pihole/gravity.db` - Main Pi-hole database containing:
   - All blocklist domains
   - Group configurations
   - Domain lists (allow/deny)
   - Regex filters
   - Adlist subscriptions

**Configuration Files:**
2. `/etc/pihole/custom.list` - Local DNS records
3. `/etc/pihole/local.list` - Local hostname mappings
4. `/etc/pihole/adlists.list` - Legacy adlist format
5. `/etc/pihole/regex.list` - Legacy regex filters
6. `/etc/pihole/whitelist.txt` - Legacy whitelist
7. `/etc/pihole/blacklist.txt` - Legacy blacklist
8. `/etc/pihole/pihole.toml` - Main Pi-hole configuration

**dnsmasq Configuration:**
9. `/etc/dnsmasq.d/01-pihole.conf` - Core dnsmasq settings
10. `/etc/dnsmasq.d/02-pihole-dhcp.conf` - DHCP configuration
11. `/etc/dnsmasq.d/04-pihole-static-dhcp.conf` - Static DHCP leases
12. `/etc/dnsmasq.d/05-pihole-custom-cname.conf` - CNAME records

**DHCP Data:**
13. `/etc/pihole/dhcp.leases` - Active DHCP leases

### Cron Configuration

#### Cron Job Definition

```bash
# Run Pi-hole sync every 5 minutes
*/5 * * * * /usr/local/bin/pihole-sync.sh >> /var/log/pihole-sync.log 2>&1
```

**Installed on:** Primary server (ns01) root crontab  
**Schedule:** Every 5 minutes  
**Output:** Appended to `/var/log/pihole-sync.log`

#### Cron Schedule Breakdown

- `*/5` - Every 5 minutes
- `*` - Every hour
- `*` - Every day of month
- `*` - Every month
- `*` - Every day of week

#### Managing the Cron Job

**View cron jobs:**
```bash
sudo crontab -l
```

**Edit cron jobs:**
```bash
sudo crontab -e
```

**Remove sync cron job:**
```bash
sudo crontab -l | grep -v pihole-sync | sudo crontab -
```

### Log File

#### Location
`/var/log/pihole-sync.log` (on primary server)

#### Permissions
- **Mode:** `666 (rw-rw-rw-)`
- **Owner:** `root:root`

#### Log Format

```
[YYYY-MM-DD HH:MM:SS] Message
```

#### Sample Log Output

```
[2025-12-05 06:44:04] ====== Starting Pi-hole Sync ======
[2025-12-05 06:44:04] Syncing gravity database...
[2025-12-05 06:44:20] Gravity synced
[2025-12-05 06:44:20] Syncing adlists.list...
[2025-12-05 06:44:22] Syncing pihole.toml...
[2025-12-05 06:44:24] Syncing DHCP leases...
[2025-12-05 06:44:26] Reloading DNS on secondary...
[2025-12-05 06:44:27] DNS reloaded
[2025-12-05 06:44:29] Verification: Primary=5623210 Secondary=5623210
[2025-12-05 06:44:29] ✓ Sync verified
[2025-12-05 06:44:29] ====== Sync Complete ======
```

#### Viewing Logs

**View entire log:**
```bash
cat /var/log/pihole-sync.log
```

**View last 50 lines:**
```bash
tail -50 /var/log/pihole-sync.log
```

**Monitor in real-time:**
```bash
tail -f /var/log/pihole-sync.log
```

**View only errors:**
```bash
grep ERROR /var/log/pihole-sync.log
```

**View specific date:**
```bash
grep "2025-12-05" /var/log/pihole-sync.log
```

### Sync Process Flow

1. **Trigger:** Cron executes script every 5 minutes
2. **Log Start:** Script logs sync initiation
3. **Database Sync:** 
   - Copies `gravity.db` from primary to secondary `/tmp`
   - Moves to proper location with correct ownership
4. **Configuration Sync:**
   - Iterates through Pi-hole config files
   - Copies each existing file to secondary
   - Sets proper ownership and permissions
5. **dnsmasq Sync:**
   - Copies dnsmasq configuration files
   - Maintains proper permissions
6. **DHCP Sync:**
   - Copies DHCP lease file if it exists
7. **DNS Reload:**
   - Executes `pihole reloaddns` on secondary
   - Applies all configuration changes
8. **Verification:**
   - Counts gravity domains on both servers
   - Compares counts to verify sync success
   - Logs result (✓ verified or ⚠ mismatch)
9. **Completion:** Logs sync completion

### Security Considerations

#### Password Storage
- **Method:** Plain text in script
- **Risk Level:** Medium
- **Mitigation:** 
  - Script only accessible by root
  - Suitable for private network environment
  - Consider SSH keys for higher security

#### SSH Configuration
- **Host Key Checking:** Disabled in script (`StrictHostKeyChecking=no`)
- **Known Hosts:** Not used (`UserKnownHostsFile=/dev/null`)
- **Reasoning:** Automation requirement, acceptable for trusted internal network

#### File Permissions
- **Script:** `755` - Root can write, all can execute
- **Log:** `666` - All can read/write
- **Sudoers:** `440` - Only root can read

#### Network Security
- **Traffic:** Unencrypted SSH (within local network)
- **Exposure:** Limited to local network only
- **Recommendation:** Firewall rules to restrict SSH access

### Manual Sync Operations

#### Force Immediate Sync
```bash
sudo /usr/local/bin/pihole-sync.sh
```

#### Sync Specific File
```bash
# Example: Sync only gravity database
sudo scp /etc/pihole/gravity.db tvanauken@172.31.250.9:/tmp/
ssh tvanauken@172.31.250.9 "sudo mv /tmp/gravity.db /etc/pihole/ && sudo pihole reloaddns"
```

#### Verify Sync Status
```bash
# On primary
PRIMARY_COUNT=$(sudo sqlite3 /etc/pihole/gravity.db 'SELECT COUNT(*) FROM gravity;')
echo "Primary: $PRIMARY_COUNT"

# On secondary  
ssh tvanauken@172.31.250.9 "sudo sqlite3 /etc/pihole/gravity.db 'SELECT COUNT(*) FROM gravity;'"
```

---

## Network Configuration

### DNS Server Setup

#### Client Configuration

To use the Pi-hole servers, configure clients with:

**Primary DNS:** `172.31.250.8`  
**Secondary DNS:** `172.31.250.9`

#### Router/DHCP Configuration

Configure your router's DHCP server to automatically provide these DNS servers to all network clients:

**DHCP DNS Server 1:** `172.31.250.8`  
**DHCP DNS Server 2:** `172.31.250.9`

#### Manual Configuration Examples

**Windows:**
```
Network Settings → Change Adapter Options → Properties → 
Internet Protocol Version 4 (TCP/IPv4) → Properties →
Use the following DNS server addresses:
  Preferred: 172.31.250.8
  Alternate: 172.31.250.9
```

**Linux (netplan):**
```yaml
# /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: yes
      nameservers:
        addresses: [172.31.250.8, 172.31.250.9]
```

**macOS:**
```
System Preferences → Network → Advanced → DNS →
DNS Servers:
  172.31.250.8
  172.31.250.9
```

### Testing DNS Resolution

#### From Any Client

**Test basic resolution:**
```bash
nslookup google.com 172.31.250.8
nslookup google.com 172.31.250.9
```

**Test blocking (should return 0.0.0.0):**
```bash
nslookup doubleclick.net 172.31.250.8
nslookup ads.google.com 172.31.250.9
```

**Test with dig:**
```bash
dig @172.31.250.8 example.com
dig @172.31.250.9 example.com
```

### Firewall Configuration

#### Required Ports (Both Servers)

| Port | Protocol | Purpose | Access |
|------|----------|---------|--------|
| 53 | TCP/UDP | DNS queries | All network clients |
| 80 | TCP | Web interface (HTTP) | Admin access |
| 22 | TCP | SSH administration | Admin hosts only |
| 67 | UDP | DHCP (if enabled) | All network clients |

#### Example Firewall Rules (UFW)

```bash
# Allow DNS
sudo ufw allow 53/tcp
sudo ufw allow 53/udp

# Allow web interface
sudo ufw allow 80/tcp

# Allow SSH (restrict to specific IPs recommended)
sudo ufw allow from 192.168.1.0/24 to any port 22

# If using DHCP
sudo ufw allow 67/udp

# Enable firewall
sudo ufw enable
```

---

## Maintenance & Monitoring

### Regular Maintenance Tasks

#### Weekly Tasks

**1. Review Sync Logs**
```bash
# Check for any sync errors
ssh tvanauken@172.31.250.8
sudo grep ERROR /var/log/pihole-sync.log | tail -20
```

**2. Verify Gravity Update**
```bash
# Ensure blocklists are up to date (both servers)
ssh tvanauken@172.31.250.8 "sudo pihole -g"
ssh tvanauken@172.31.250.9 "sudo pihole -g"
```

#### Monthly Tasks

**1. System Updates**
```bash
# Update operating system packages (both servers)
sudo apt update && sudo apt upgrade -y
```

**2. Pi-hole Updates**
```bash
# Update Pi-hole (both servers)
sudo pihole -up
```

**3. Log Rotation Check**
```bash
# Verify log files aren't growing excessively
ls -lh /var/log/pihole*.log
```

**4. Database Maintenance**
```bash
# Optimize gravity database (primary server)
sudo sqlite3 /etc/pihole/gravity.db 'VACUUM;'
```

#### Quarterly Tasks

**1. Review Blocklists**
- Check for deprecated lists
- Add new recommended lists
- Remove inactive lists

**2. Review Allow/Deny Lists**
- Remove unnecessary entries
- Add new exceptions as needed

**3. Backup Configuration**
```bash
# Create backup (primary server)
sudo tar czf ~/pihole-backup-$(date +%Y%m%d).tar.gz /etc/pihole /etc/dnsmasq.d
```

### Monitoring

#### Health Check Commands

**Check Pi-hole Status:**
```bash
sudo pihole status
```

**Expected Output:**
```
[✓] FTL is listening on port 53
   [✓] UDP (IPv4)
   [✓] TCP (IPv4)
   [✓] UDP (IPv6)
   [✓] TCP (IPv6)

[✓] Pi-hole blocking is enabled
```

**Check Service Status:**
```bash
sudo systemctl status pihole-FTL
```

**View DNS Query Statistics:**
```bash
pihole -c  # Interactive dashboard
pihole -q example.com  # Query specific domain
```

#### Key Metrics to Monitor

**1. DNS Query Rate**
- View in web interface dashboard
- Normal: Varies by network size
- Alert if: Suddenly drops to zero or spikes abnormally

**2. Blocking Percentage**
- View in web interface
- Typical range: 10-30%
- Alert if: Drops below 5% (possible sync issue)

**3. Gravity Database Size**
```bash
# Should be ~5.6 million domains
sudo sqlite3 /etc/pihole/gravity.db 'SELECT COUNT(*) FROM gravity;'
```

**4. Sync Success Rate**
```bash
# Check recent syncs
sudo grep "Sync Complete" /var/log/pihole-sync.log | tail -10
```

#### Automated Monitoring Script

```bash
#!/bin/bash
# /usr/local/bin/pihole-health-check.sh

ADMIN_EMAIL="admin@example.com"

# Check if FTL is running
if ! systemctl is-active --quiet pihole-FTL; then
    echo "ERROR: Pi-hole FTL service is down!" | mail -s "Pi-hole Alert" $ADMIN_EMAIL
fi

# Check sync status
LAST_SYNC=$(sudo grep "Sync Complete" /var/log/pihole-sync.log | tail -1)
if [ -z "$LAST_SYNC" ]; then
    echo "ERROR: No recent sync found!" | mail -s "Pi-hole Sync Alert" $ADMIN_EMAIL
fi

# Check gravity count
GRAVITY_COUNT=$(sudo sqlite3 /etc/pihole/gravity.db 'SELECT COUNT(*) FROM gravity;')
if [ "$GRAVITY_COUNT" -lt 5000000 ]; then
    echo "WARNING: Gravity database has only $GRAVITY_COUNT domains!" | mail -s "Pi-hole Gravity Alert" $ADMIN_EMAIL
fi
```

### Web Interface Access

**Primary Server:** http://172.31.250.8/admin  
**Secondary Server:** http://172.31.250.9/admin  
**Password:** VanAwsome1

#### Web Interface Features

- **Dashboard:** Real-time query statistics
- **Query Log:** View all DNS queries
- **Long-term Data:** Historical statistics and graphs
- **Lists:** Manage blocklists, allowlists, denylists
- **Groups:** Configure list groups
- **Settings:** Pi-hole configuration options
- **Tools:** Update, restart, backup utilities

---

## Troubleshooting

### Common Issues and Solutions

#### Issue: Sync Not Running

**Symptoms:**
- Secondary server configuration outdated
- No recent entries in sync log

**Diagnosis:**
```bash
# Check if cron job exists
ssh tvanauken@172.31.250.8 "sudo crontab -l | grep pihole-sync"

# Check if script exists and is executable
ssh tvanauken@172.31.250.8 "ls -l /usr/local/bin/pihole-sync.sh"

# Check recent sync attempts
ssh tvanauken@172.31.250.8 "sudo tail -20 /var/log/pihole-sync.log"
```

**Solutions:**
```bash
# Reinstall cron job
ssh tvanauken@172.31.250.8 "echo 'VanAwsome1' | sudo -S bash -c \"(crontab -l 2>/dev/null | grep -v pihole-sync; echo '*/5 * * * * /usr/local/bin/pihole-sync.sh >> /var/log/pihole-sync.log 2>&1') | crontab -\""

# Make script executable
ssh tvanauken@172.31.250.8 "sudo chmod +x /usr/local/bin/pihole-sync.sh"

# Run manual sync
ssh tvanauken@172.31.250.8 "sudo /usr/local/bin/pihole-sync.sh"
```

#### Issue: SSH Connection Failures

**Symptoms:**
- Sync logs show "Permission denied" or "Connection refused"
- Cannot SSH to secondary server

**Diagnosis:**
```bash
# Test SSH connection
ssh tvanauken@172.31.250.9 'echo success'

# Check SSH service
ssh tvanauken@172.31.250.9 "sudo systemctl status sshd"

# Test with sshpass
sshpass -p 'VanAwsome1' ssh tvanauken@172.31.250.9 'echo success'
```

**Solutions:**
```bash
# Restart SSH service on secondary
ssh tvanauken@172.31.250.9 "sudo systemctl restart sshd"

# Verify SSH is enabled
ssh tvanauken@172.31.250.9 "sudo systemctl enable sshd"

# Check firewall
ssh tvanauken@172.31.250.9 "sudo ufw status"
```

#### Issue: DNS Not Resolving

**Symptoms:**
- Clients cannot resolve domains
- "Server can't find" errors

**Diagnosis:**
```bash
# Check if Pi-hole is running
sudo pihole status

# Check FTL service
sudo systemctl status pihole-FTL

# Test local resolution
dig @127.0.0.1 google.com

# Check DNS port
sudo netstat -tulpn | grep :53
```

**Solutions:**
```bash
# Restart Pi-hole FTL
sudo systemctl restart pihole-FTL

# Restart DNS resolver
sudo pihole restartdns

# Repair Pi-hole
sudo pihole -r  # Select "Repair"

# Check upstream DNS
pihole -q google.com
```

#### Issue: Web Interface Not Accessible

**Symptoms:**
- Cannot access http://172.31.250.x/admin
- 404 or connection timeout

**Diagnosis:**
```bash
# Check lighttpd service
sudo systemctl status lighttpd

# Check if port 80 is open
sudo netstat -tulpn | grep :80

# Check firewall
sudo ufw status
```

**Solutions:**
```bash
# Restart web server
sudo systemctl restart lighttpd

# Enable lighttpd
sudo systemctl enable lighttpd

# Allow port 80
sudo ufw allow 80/tcp

# Repair web interface
sudo pihole -r  # Select "Repair"
```

#### Issue: High Memory Usage

**Symptoms:**
- System slowdown
- FTL consuming excessive RAM

**Diagnosis:**
```bash
# Check memory usage
free -h

# Check FTL memory
ps aux | grep pihole-FTL

# Check gravity database size
ls -lh /etc/pihole/gravity.db
```

**Solutions:**
```bash
# Restart FTL to clear cache
sudo systemctl restart pihole-FTL

# Optimize database
sudo sqlite3 /etc/pihole/gravity.db 'VACUUM;'

# Clear old queries
sudo pihole flush
```

#### Issue: Blocked Legitimate Site

**Symptoms:**
- Needed website not loading
- Service not working correctly

**Solutions:**
```bash
# Add to allowlist via CLI
pihole -w example.com

# Or via web interface:
# Settings → Blocklists → Allowlist → Add
```

**Test after adding:**
```bash
pihole -q example.com
```

#### Issue: Gravity Update Fails

**Symptoms:**
- "Error downloading blocklist"
- Outdated gravity database

**Diagnosis:**
```bash
# Run gravity update with verbose output
sudo pihole -g

# Check internet connectivity
ping -c 4 8.8.8.8

# Check DNS resolution
nslookup google.com

# Check specific blocklist
curl -I https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
```

**Solutions:**
```bash
# Update with debugging
sudo pihole -g -v

# Clear gravity and rebuild
sudo rm /etc/pihole/gravity.db
sudo pihole -g

# Check disk space
df -h
```

### Recovery Procedures

#### Full System Recovery

**If primary server fails:**

1. Promote secondary to primary temporarily
2. Update clients to use 172.31.250.9 only
3. Repair/rebuild primary server
4. Copy configuration from secondary back to primary
5. Restore sync operation
6. Update clients to use both servers again

**Configuration Backup:**
```bash
# Create full backup
sudo tar czf pihole-backup-$(date +%Y%m%d).tar.gz \
  /etc/pihole \
  /etc/dnsmasq.d \
  /usr/local/bin/pihole-sync.sh \
  /var/log/pihole-sync.log
```

**Configuration Restore:**
```bash
# Extract backup
sudo tar xzf pihole-backup-YYYYMMDD.tar.gz -C /

# Fix permissions
sudo chown -R pihole:pihole /etc/pihole
sudo chown root:root /etc/dnsmasq.d/*

# Restart services
sudo systemctl restart pihole-FTL
sudo pihole reloaddns
```

### Getting Help

**Pi-hole Community:**
- Forum: https://discourse.pi-hole.net/
- Documentation: https://docs.pi-hole.net/
- GitHub: https://github.com/pi-hole/pi-hole

**Diagnostic Information:**
```bash
# Generate debug log
pihole -d

# System information
pihole -v
uname -a
free -h
df -h
```

---

## Appendix

### A. File Locations Reference

#### Pi-hole Core Files
```
/etc/pihole/
├── gravity.db              # Main database
├── pihole.toml            # Configuration
├── custom.list            # Local DNS records
├── local.list             # Hostname mappings
├── adlists.list           # Legacy adlist format
├── regex.list             # Legacy regex filters
├── whitelist.txt          # Legacy whitelist
├── blacklist.txt          # Legacy blacklist
└── dhcp.leases            # DHCP leases
```

#### dnsmasq Configuration
```
/etc/dnsmasq.d/
├── 01-pihole.conf                  # Core settings
├── 02-pihole-dhcp.conf            # DHCP config
├── 04-pihole-static-dhcp.conf     # Static leases
└── 05-pihole-custom-cname.conf    # CNAME records
```

#### Sync System Files
```
/usr/local/bin/
└── pihole-sync.sh          # Sync script

/var/log/
└── pihole-sync.log         # Sync log file

/etc/sudoers.d/
└── tvanauken               # Sudo configuration
```

### B. Command Reference

#### Pi-hole Commands
```bash
pihole status               # Check Pi-hole status
pihole -v                  # Version information
pihole -g                  # Update gravity
pihole -up                 # Update Pi-hole
pihole -r                  # Repair/reconfigure
pihole restartdns          # Restart DNS service
pihole reloaddns           # Reload DNS configuration
pihole -w example.com      # Whitelist domain
pihole -b example.com      # Blacklist domain
pihole -q example.com      # Query domain
pihole -c                  # Chronometer (live stats)
pihole -t                  # Tail log
pihole -d                  # Generate debug log
pihole flush               # Flush query log
```

#### Sync Management Commands
```bash
# Manual sync
sudo /usr/local/bin/pihole-sync.sh

# View sync log
sudo tail -f /var/log/pihole-sync.log

# Check cron job
sudo crontab -l

# Edit cron job
sudo crontab -e

# Verify sync
sudo grep "✓ Sync verified" /var/log/pihole-sync.log | tail -5
```

#### Database Queries
```bash
# Count gravity domains
sqlite3 /etc/pihole/gravity.db 'SELECT COUNT(*) FROM gravity;'

# List groups
sqlite3 /etc/pihole/gravity.db 'SELECT * FROM "group";'

# Count allowlist
sqlite3 /etc/pihole/gravity.db 'SELECT COUNT(*) FROM domainlist WHERE type IN (0,2);'

# List adlists
sqlite3 /etc/pihole/gravity.db 'SELECT address FROM adlist WHERE enabled=1;'
```

### C. Network Diagram

```
                    Internet
                        ↕
                  [Router/Gateway]
                        ↕
        ┌───────────────┴───────────────┐
        ↕                               ↕
   [ns01 - Primary]              [ns02 - Secondary]
   172.31.250.8                  172.31.250.9
        ↕                               ↕
        └───────────────┬───────────────┘
                        ↕
        ┌───────────────┴───────────────┐
        ↕               ↕               ↕
    [Laptop]        [Phone]        [Desktop]
```

### D. Changelog

**Version 1.0 - December 5, 2025**
- Initial deployment
- Primary server: ns01.anchor.gammatime.ai (172.31.250.8)
- Secondary server: ns02.anchor.gammatime.ai (172.31.250.9)
- 30 blocklists configured
- 5.6M+ blocked domains
- Automatic 5-minute sync implemented
- Complete documentation created

### E. Contact Information

**Infrastructure Owner:** tvanauken  
**Repository:** https://github.com/tvanauken/docs-staging  
**Documentation:** This file

---

**Document End**

*Last Updated: December 5, 2025*  
*Document Version: 1.0*  
*Infrastructure Status: Operational*