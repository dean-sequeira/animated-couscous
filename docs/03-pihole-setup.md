# Pi-hole Service Setup Instructions

Pi-hole provides network-level ad blocking by acting as a DNS sinkhole for unwanted domains. This service is critical for the home network infrastructure.

## Service Overview

- **Purpose**: DNS-level ad blocking and network-wide filtering
- **Host Requirements**: Raspberry Pi with static IP (192.168.1.10)
- **Dependencies**: Docker, Docker Compose
- **Ports**: 53 (DNS), 80 (Web Interface), 443 (HTTPS)

## Pre-Installation Requirements

### Network Configuration
- Static IP address configured (192.168.1.10)
- Router DHCP configured to use Pi-hole as primary DNS
- Firewall rules allowing DNS traffic from local network

### System Requirements
- Minimum 1GB RAM
- 8GB+ storage space
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
mkdir -p /home/pi/animated-couscous/pi-hole/config
mkdir -p /home/pi/animated-couscous/pi-hole/scripts
cd /home/pi/animated-couscous/pi-hole
```

### 2. Environment Configuration
Create `.env` file with your specific settings:
```bash
# Pi-hole Configuration
PIHOLE_PASSWORD=your_secure_password
TZ=America/New_York
SERVERIP=192.168.1.10
WEBPASSWORD=your_web_password

# DNS Configuration
DNS1=1.1.1.1
DNS2=1.0.0.1
DNSSEC=true

# Network Configuration
INTERFACE=eth0
DNSMASQ_LISTENING=local
```

### 3. Docker Compose Configuration
The service uses official Pi-hole Docker image with persistent storage and proper networking.

### 4. Initial Blocklists
Configure additional blocklists in `config/adlists.list`:
```
# Recommended blocklists
https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
https://mirror1.malwaredomains.com/files/justdomains
https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt
https://raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/MobileFilter/sections/adservers.txt
```

## Service Management

### Start Service
```bash
cd /home/pi/animated-couscous/pi-hole
docker-compose up -d
```

### Check Status
```bash
docker-compose ps
docker-compose logs pihole
```

### Update Service
```bash
docker-compose pull
docker-compose up -d
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
