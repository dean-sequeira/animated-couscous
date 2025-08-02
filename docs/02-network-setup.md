# Network Setup Instructions

This document outlines the recommended network topology and configuration for the home network infrastructure project.

## Network Topology Overview

```
Internet
    |
Router/Gateway (192.168.1.1)
    |
    ├── Pi-hole DNS Server (192.168.1.10)
    ├── Monitoring Host (192.168.1.11) - ntopng, Grafana
    ├── Streamlit Apps Host (192.168.1.12)
    └── Client Devices (192.168.1.100-254)
```

## IP Address Allocation

### Static IP Assignments
- **Router/Gateway**: 192.168.1.1
- **Pi-hole DNS**: 192.168.1.10
- **Monitoring Host**: 192.168.1.11
- **Streamlit Host**: 192.168.1.12
- **Reserved Range**: 192.168.1.10-20 (infrastructure)
- **DHCP Pool**: 192.168.1.100-254 (client devices)

### Port Allocations
- **53**: DNS (Pi-hole)
- **80**: Pi-hole Web Interface
- **3000**: Grafana Dashboard
- **3001**: ntopng Web Interface
- **8501-8510**: Streamlit Applications
- **22**: SSH (all hosts)

## Router Configuration

### DHCP Settings
```yaml
# Example router DHCP configuration
dhcp_pool_start: 192.168.1.100
dhcp_pool_end: 192.168.1.254
lease_time: 24h
default_gateway: 192.168.1.1
primary_dns: 192.168.1.10  # Pi-hole
secondary_dns: 192.168.1.1  # Router fallback
```

### DNS Settings
1. Set Pi-hole (192.168.1.10) as primary DNS
2. Keep router IP as secondary DNS for redundancy
3. Disable router's built-in DNS caching if possible

### Port Forwarding (Optional)
```yaml
# Only if remote access needed (not recommended for security)
# ssh_access:
#   external_port: 2222
#   internal_ip: 192.168.1.10
#   internal_port: 22
```

## Network Security Configuration

### Firewall Rules (UFW on each Pi)
```bash
# Pi-hole host (192.168.1.10)
sudo ufw allow from 192.168.1.0/24 to any port 53
sudo ufw allow from 192.168.1.0/24 to any port 80
sudo ufw allow from 192.168.1.0/24 to any port 22

# Monitoring host (192.168.1.11)
sudo ufw allow from 192.168.1.0/24 to any port 3000
sudo ufw allow from 192.168.1.0/24 to any port 3001
sudo ufw allow from 192.168.1.0/24 to any port 22

# Streamlit host (192.168.1.12)
sudo ufw allow from 192.168.1.0/24 to any port 8501:8510
sudo ufw allow from 192.168.1.0/24 to any port 22
```

### Network Segmentation (Advanced)
```yaml
# VLAN configuration (if supported by router)
vlans:
  infrastructure: 10  # Pi devices
  iot_devices: 20     # Smart home devices
  guest_network: 30   # Guest access
  
# Corresponding IP ranges
vlan_10: 192.168.10.0/24  # Infrastructure
vlan_20: 192.168.20.0/24  # IoT
vlan_30: 192.168.30.0/24  # Guests
```

## DNS Configuration

### Pi-hole Upstream DNS
```yaml
# Recommended upstream DNS servers
upstream_dns:
  - 1.1.1.1        # Cloudflare
  - 1.0.0.1        # Cloudflare
  - 8.8.8.8        # Google
  - 208.67.222.222 # OpenDNS
```

### Local DNS Records
```yaml
# Add these to Pi-hole custom DNS
local_records:
  pihole.local: 192.168.1.10
  monitoring.local: 192.168.1.11
  apps.local: 192.168.1.12
  grafana.local: 192.168.1.11
  ntopng.local: 192.168.1.11
```

## Quality of Service (QoS)

### Traffic Prioritization
```yaml
# Router QoS settings (if supported)
priority_high:
  - DNS traffic (port 53)
  - SSH traffic (port 22)
  - Web interfaces (ports 80, 443, 3000, 3001)

priority_medium:
  - Streamlit apps (ports 8501-8510)
  - General web traffic

priority_low:
  - File transfers
  - Backup traffic
```

## Monitoring Network Health

### Essential Monitoring Points
1. **DNS Resolution**: Monitor Pi-hole query logs
2. **Bandwidth Usage**: Track via ntopng
3. **Device Connectivity**: Ping tests from monitoring host
4. **Service Availability**: Health checks for all services

### Network Testing Commands
```bash
# Test DNS resolution
nslookup google.com 192.168.1.10

# Test connectivity between hosts
ping 192.168.1.11

# Check port availability
nc -zv 192.168.1.10 53

# Monitor network traffic
sudo tcpdump -i eth0 port 53
```

## Backup and Recovery

### Network Configuration Backup
```bash
# Router config backup (method varies by router)
# Save current DHCP reservations
# Document all port forwarding rules
# Export firewall rules from each Pi

# Example UFW rules backup
sudo ufw --dry-run | tee ufw-rules-backup.txt
```

### Disaster Recovery Plan
1. **Pi failure**: Deploy service to another Pi using Docker Compose
2. **Network failure**: Fallback DNS configuration
3. **Internet outage**: Local services remain functional
4. **Complete rebuild**: Restore from configuration files in git repo

## Troubleshooting

### Common Network Issues
```bash
# Check routing table
ip route show

# Verify DNS settings
cat /etc/resolv.conf

# Test internal connectivity
ping -c 4 192.168.1.1

# Check for IP conflicts
arping -D 192.168.1.10
```

### Performance Optimization
1. **Enable jumbo frames** on gigabit networks
2. **Tune TCP buffer sizes** for high throughput
3. **Use wired connections** for Pi hosts when possible
4. **Monitor for network congestion** via ntopng

## Next Steps

After network setup:
1. Configure static IPs on all Pi hosts
2. Update router DNS settings to point to Pi-hole
3. Test connectivity between all services
4. Deploy monitoring to verify network health
5. Document any custom router-specific configurations
