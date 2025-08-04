# Pi-hole Service Setup Instructions

Pi-hole provides network-level ad blocking by acting as a DNS sinkhole for unwanted domains. This service is critical for the home network infrastructure and runs on the combined Pi-hole + Monitoring host.

## Service Overview

- **Purpose**: DNS-level ad blocking and network-wide filtering
- **Host Requirements**: Raspberry Pi with static IP (192.168.3.10) - Combined with monitoring services
- **Dependencies**: Docker, Docker Compose
- **Ports**: 53 (DNS), 80 (Web Interface), 443 (HTTPS)

## Pre-Installation Requirements

### Network Configuration
- Static IP address configured (192.168.3.10)
- Router DHCP configured to use Pi-hole as primary DNS
- Firewall rules allowing DNS traffic from local network

### System Requirements
- **Minimum 4GB RAM** (since this Pi also runs ntopng, Grafana, Prometheus)
- SSD storage mounted at `/mnt/storage`
- Reliable power supply (UPS recommended)

## Directory Structure
```
pi-hole/
├── docker-compose.yml
├── .env.example
├── .env
├── config/
│   ├── custom.list      # Custom DNS entries
│   ├── adlists.list     # Additional blocklists
│   └── whitelist.txt    # Whitelisted domains
└── scripts/
    ├── backup.sh        # Configuration backup
    └── restore.sh       # Configuration restore
```

## Installation Steps

### 1. Create Service Directory
```bash
# Navigate to the project directory on SSD storage
cd /mnt/storage/animated-couscous/pi_hole

# Create config and scripts directories if they don't exist
mkdir -p config scripts

# Verify directory structure
ls -la
```

### 2. Environment Configuration

#### Option A: Create .env file directly via SSH
```bash
# Create .env file using heredoc (copy/paste this entire block)
cat > .env << 'EOF'
# Pi-hole Configuration
TZ=America/New_York
SERVER_IP=192.168.3.10
INTERFACE=eth0
VIRTUAL_HOST=pihole.local

# Pi-hole Web Interface
PIHOLE_PASSWORD=your_secure_password_here

# DNS Configuration
DNS1=1.1.1.1
DNS2=1.0.0.1
IPV6=false

# DNSMASQ Configuration
DNSMASQ_LISTENING=local

# Reverse DNS
REV_SERVER=true
REV_SERVER_TARGET=192.168.3.1
REV_SERVER_DOMAIN=local
REV_SERVER_CIDR=192.168.3.0/24

# Display Settings
TEMPERATURE_UNIT=c

# Advanced DNS Settings
DNSSEC=true
CONDITIONAL_FORWARDING=true
CONDITIONAL_FORWARDING_IP=192.168.3.1
CONDITIONAL_FORWARDING_DOMAIN=local
CONDITIONAL_FORWARDING_REVERSE=3.168.192.in-addr.arpa
EOF
```

#### Option B: Copy from example and edit
```bash
# Copy the example file
cp .env.example .env

# Edit with nano (or vim)
nano .env

# Make your changes:
# - Set PIHOLE_PASSWORD to a secure password
# - Verify SERVER_IP is 192.168.3.10
# - Adjust timezone if needed
# Save and exit (Ctrl+X, then Y, then Enter in nano)
```

### 3. Prepare Storage Directories
```bash
# Ensure Pi-hole data directories exist on SSD
sudo mkdir -p /mnt/storage/pi_hole_data/{etc-pihole,etc-dnsmasq.d}
sudo chown -R pi:pi /mnt/storage/pi_hole_data

# Set proper permissions
chmod 755 /mnt/storage/pi_hole_data
```

### 4. Deploy Pi-hole Service
```bash
# Start the Pi-hole service
docker compose up -d

# Verify the service is running
docker compose ps

# Check logs for any startup issues
docker compose logs pihole

# Set the Pi-hole web interface password
docker compose exec pihole pihole setpassword

# Alternative: Set password non-interactively
# docker compose exec pihole pihole setpassword your_secure_password

# Test DNS resolution using dig (more widely available)
dig @127.0.0.1 google.com

# Alternative: Test using the Pi-hole container's built-in tools
docker compose exec pihole nslookup google.com 127.0.0.1

# Or use curl to test HTTP connectivity through DNS
curl -I http://google.com
```

### 5. Configure Web Interface Access
```bash
# Access the Pi-hole web interface
# URL: http://192.168.3.10/admin

# If you need to change the password later:
docker compose exec pihole pihole setpassword

# To disable password protection (not recommended):
# docker compose exec pihole pihole setpassword ""

# To check Pi-hole status from command line:
docker compose exec pihole pihole status
```

## Option B: Pi-hole as DHCP Server Setup

**⚠️ Important**: This will make your Pi the DHCP server for your entire network. Ensure the Pi is stable and always powered on.

### Step 1: Update Firewall Rules
```bash
# Allow DHCP traffic on the Pi
sudo ufw allow 67/udp    # DHCP server
sudo ufw allow 68/udp    # DHCP client

# Verify firewall rules
sudo ufw status
```

### Step 2: Deploy Updated Pi-hole
```bash
# Stop current Pi-hole service
docker compose down

# Start with updated configuration (includes host networking for DHCP)
docker compose up -d

# Check that Pi-hole is running
docker compose ps
docker compose logs pihole
```

### Step 3: Configure Pi-hole DHCP via Web Interface
```bash
# Access Pi-hole admin: http://192.168.3.10/admin
# 1. Go to Settings → DHCP
# 2. Check "DHCP server enabled"
# 3. Configure DHCP settings:
#    - From: 192.168.3.100
#    - To: 192.168.3.254
#    - Router (gateway) IP: 192.168.3.1
#    - Domain name: local
#    - Lease time: 24 hours
# 4. Click "Save"
```

### Step 4: Disable Router DHCP
```bash
# Access your router's admin interface (usually http://192.168.3.1)
# Look for DHCP settings and disable DHCP server
# Save/Apply settings
```

### Step 5: Restart Network Devices
```bash
# On all devices (phones, computers, etc.), either:
# - Disconnect and reconnect to WiFi
# - Restart the device
# - Or run: sudo dhclient -r && sudo dhclient (on Linux devices)

# Verify Pi got correct IP:
ip addr show eth0
# Should show 192.168.3.10

# Test that Pi-hole is handling DHCP:
docker compose exec pihole cat /var/log/pihole.log | grep DHCP
```

### Step 6: Verify Everything Works
```bash
# Test DNS resolution and blocking
dig @192.168.3.10 google.com
dig @192.168.3.10 doubleclick.net  # Should be blocked

# Check DHCP leases in Pi-hole admin interface
# Go to Tools → Network Overview
# You should see all devices getting IPs from 192.168.3.100+
```

## Service Management

### Start Service
```bash
cd /mnt/storage/animated-couscous/pi_hole
docker compose up -d
```

### Check Status
```bash
docker compose ps
docker compose logs pihole

# Check if Pi-hole is responding to DNS queries
docker compose exec pihole pihole status
```

### Stop Service
```bash
docker compose down
```

### Update Service
```bash
docker compose pull
docker compose up -d
```

### Restart Service
```bash
docker compose restart pihole
```

## Configuration

### Web Interface Access
- URL: http://192.168.1.10/admin
- Login with password from `.env` file

### Custom DNS Entries
Add local domain resolution in `config/custom.list`:
```
192.168.1.11 monitoring.local
192.168.1.12 apps.local
192.168.1.11 grafana.local
192.168.1.11 ntopng.local
```

### Whitelist Management
Add essential domains to `config/whitelist.txt`:
```
# Essential domains that should never be blocked
microsoft.com
apple.com
google.com
github.com
docker.io
ubuntu.com
```

### Parental Controls
Configure time-based blocking and content filtering:
```bash
# Add to Pi-hole via web interface or API
# Block social media during specific hours
# Block inappropriate content categories
# Set different rules for different devices
```

## Monitoring and Maintenance

### Health Checks
```bash
# Test DNS resolution
nslookup google.com 192.168.1.10
dig @192.168.1.10 google.com

# Check blocking functionality
nslookup doubleclick.net 192.168.1.10

# Monitor query logs
docker-compose exec pihole tail -f /var/log/pihole.log
```

### Performance Monitoring
- Monitor query response times
- Track blocked vs allowed queries ratio
- Monitor memory and CPU usage
- Check for DNS resolution failures

### Backup and Restore
```bash
# Backup configuration
./scripts/backup.sh

# Restore from backup
./scripts/restore.sh backup-date.tar.gz
```

## Advanced Configuration

### Unbound Integration (Optional)
Add recursive DNS resolver for improved privacy:
- Eliminates dependency on external DNS providers
- Reduces DNS query leakage
- Improves response times for cached queries

### Conditional Forwarding
Configure for local network discovery:
```
# Forward reverse DNS queries for local network
# Enable in Pi-hole settings for 192.168.1.0/24
```

### API Integration
Use Pi-hole API for automation:
```bash
# Enable/disable Pi-hole
curl "http://192.168.1.10/admin/api.php?disable&auth=your_api_token"

# Add domains to whitelist programmatically
curl "http://192.168.1.10/admin/api.php?list=white&add=example.com&auth=your_api_token"
```

## Troubleshooting

### Common Issues
1. **DNS not resolving**: Check static IP configuration
2. **Web interface not accessible**: Verify port 80 is not blocked
3. **Slow DNS queries**: Check upstream DNS servers
4. **Too many blocked domains**: Review and adjust blocklists

### Debug Commands
```bash
# Check Pi-hole status
docker-compose exec pihole pihole status

# Verify DNS configuration
docker-compose exec pihole cat /etc/dnsmasq.d/01-pihole.conf

# Test internal DNS resolution
docker-compose exec pihole nslookup google.com localhost
```

### Performance Tuning
- Adjust cache size for high-traffic networks
- Optimize blocklist update frequency
- Monitor and tune Docker resource limits
- Consider Pi-hole on SSD for better I/O performance

## Security Considerations

### Access Control
- Change default passwords immediately
- Use strong web interface password
- Restrict admin access to local network only
- Enable HTTPS for web interface

### Regular Updates
- Update Pi-hole container weekly
- Review and update blocklists monthly
- Monitor security advisories
- Keep host OS updated

## Integration with Other Services

### Grafana Monitoring
- Export Pi-hole metrics to Prometheus
- Create dashboards for query statistics
- Set up alerts for service outages

### Streamlit Apps
- Create admin dashboard for Pi-hole management
- Build parental control interface
- Develop network usage analytics

## Next Steps

After Pi-hole deployment:
1. Update router DNS settings to use Pi-hole
2. Test DNS resolution from all network devices
3. Configure monitoring in Grafana
4. Set up automated backups
5. Implement parental control rules
