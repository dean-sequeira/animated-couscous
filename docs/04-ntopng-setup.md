# ntopng Traffic Monitoring Setup

ntopng provides real-time network traffic monitoring and analysis, offering insights into bandwidth usage, device activity, and network performance for your home network infrastructure.

## Features

- **Real-time Traffic Analysis**: Monitor network traffic in real-time
- **Device Discovery**: Automatically discover and track network devices
- **Bandwidth Monitoring**: Track bandwidth usage per device and application
- **Security Alerts**: Detect suspicious network activity and security threats
- **Historical Data**: Store and analyze historical network data
- **Web Interface**: Easy-to-use web dashboard for monitoring

## Service Overview

- **Purpose**: Network traffic monitoring and analysis
- **Host Requirements**: Raspberry Pi with 2GB+ RAM (192.168.3.11)
- **Dependencies**: Docker, Docker Compose
- **Ports**: 3001 (Web Interface)

## Quick Start

1. **Copy and configure environment file:**
   ```bash
   cp .env.example .env
   # Edit .env with your network configuration
   ```

2. **Run the setup script:**
   ```bash
   ./scripts/setup.sh
   ```

3. **Start the service:**
   ```bash
   docker-compose up -d
   ```

4. **Access the web interface:**
   Open http://192.168.3.11:3001 in your browser

## Pre-Installation Requirements

### Network Configuration
- Static IP address configured (192.168.3.11)
- Network interface in promiscuous mode for traffic capture
- Router configured for port mirroring (if supported)

### System Requirements
- Minimum 2GB RAM (4GB recommended for large networks)
- Fast storage (SSD preferred for database writes)
- Network interface capable of monitoring traffic

## Directory Structure
```
ntopng/
├── docker-compose.yml      # Service definition
├── .env.example           # Environment template
├── .env                   # Your configuration (create from template)
├── config/
│   ├── ntopng.conf       # Main ntopng configuration
│   ├── categories.txt    # Traffic categories
│   └── alerts.conf       # Alert rules
├── data/                 # Persistent data storage
├── logs/                 # Log files
└── scripts/
    ├── setup.sh         # Initial setup script
    ├── backup.sh        # Data backup script
    └── manage.sh        # Service management
```

## Installation Steps

### 1. Create Service Directory
```bash
mkdir -p /home/pi/animated-couscous/ntopng/{config,data,scripts}
cd /home/pi/animated-couscous/ntopng
```

### 2. Environment Configuration
Create `.env` file:
```bash
# ntopng Configuration
NTOPNG_HTTP_PORT=3001
NTOPNG_INTERFACE=eth0
NTOPNG_DATA_DIR=/var/lib/ntopng
NTOPNG_LOG_LEVEL=normal

# Network Configuration
NETWORK_SUBNET=192.168.3.0/24
ROUTER_IP=192.168.3.1

# Database Configuration
DB_RETENTION_DAYS=30
MAX_FLOWS=1000000
```

### 3. Network Interface Setup
```bash
# Enable promiscuous mode for traffic monitoring
sudo ip link set eth0 promisc on

# For persistent promiscuous mode
echo 'pre-up ip link set $IFACE promisc on' | sudo tee -a /etc/network/interfaces
```

## Configuration

### Network Interface
Update the `NETWORK_INTERFACE` in your `.env` file to match your primary network interface (usually `eth0` or `wlan0`).

### Local Network
Set the `LOCAL_NETWORK` to match your subnet (e.g., `192.168.3.0/24`).

### Main Configuration File
Create `config/ntopng.conf`:
```
# Network interfaces to monitor
-i=eth0

# HTTP port
-P=/var/lib/ntopng/ntopng.pid
-p=3001

# Data directory
-d=/var/lib/ntopng

# Network configuration
-n=192.168.3.0/24

# Enable historical data
-F=es

# Log level
-v=2

# Disable login (local network only)
-l=0
```

### Traffic Categories
Configure in `config/categories.txt`:
```
# Custom traffic categories
social_media:facebook.com,instagram.com,twitter.com,tiktok.com
streaming:netflix.com,youtube.com,twitch.tv,hulu.com
gaming:steam.com,epicgames.com,xbox.com,playstation.com
work:zoom.us,teams.microsoft.com,slack.com,webex.com
```

### Alert Rules
Modify `config/alerts.conf` to configure network alerts and thresholds.

## Network Requirements

- **Promiscuous Mode**: The network interface must support promiscuous mode
- **Port Mirroring**: For complete traffic visibility, configure port mirroring on your router/switch
- **Static IP**: Recommended to use a static IP address for the monitoring host

## Service Management

### Start Service
```bash
cd /home/pi/animated-couscous/ntopng
docker-compose up -d
```

### Check Status
```bash
docker-compose ps
docker-compose logs ntopng
```

### Using Management Script
```bash
# Start/stop/restart service
./scripts/manage.sh start
./scripts/manage.sh stop
./scripts/manage.sh restart

# Check status and health
./scripts/manage.sh status

# View logs
./scripts/manage.sh logs

# Update to latest version
./scripts/manage.sh update

# Check network configuration
./scripts/manage.sh network
```

### Monitor Performance
```bash
# Check resource usage
docker stats ntopng
htop
```

## Web Interface Access

### Access URL
- URL: http://192.168.3.11:3001
- Default credentials: admin/admin (change immediately)

### Key Features
- Real-time traffic dashboards
- Per-device bandwidth usage
- Application protocol analysis
- Historical traffic trends
- Network flow analysis

## Monitoring Configuration

### Dashboard Setup
Key metrics to monitor:
- Total network throughput
- Top talkers (devices with most traffic)
- Protocol distribution
- Anomalous traffic patterns
- Bandwidth utilization trends

### Alert Configuration
Create `config/alerts.conf`:
```bash
# High bandwidth usage alert
--threshold-cross=host_traffic:>:1GB/min

# Suspicious activity detection
--threshold-cross=flows:>:10000/min

# External communication monitoring
--threshold-cross=external_traffic:>:500MB/min
```

## Maintenance

### Backup Data
```bash
./scripts/backup.sh
```

### View Logs
```bash
docker-compose logs -f ntopng
```

### Update Service
```bash
docker-compose pull
docker-compose up -d
```

## Data Management

### Retention Policy
```bash
# Configure data retention
# Modify in ntopng.conf or environment variables
-F=es:retention=30d  # Keep 30 days of data

# Monitor disk space usage
df -h /path/to/ntopng/data
```

### Backup Strategy
```bash
# Daily backup script
#!/bin/bash
BACKUP_DIR="/home/pi/backups/ntopng"
DATE=$(date +%Y%m%d)

# Create backup
tar -czf "$BACKUP_DIR/ntopng-data-$DATE.tar.gz" \
  /home/pi/animated-couscous/ntopng/data

# Keep only last 7 days
find $BACKUP_DIR -name "ntopng-data-*.tar.gz" -mtime +7 -delete
```

## Troubleshooting

### Common Issues

1. **No traffic visible**: Ensure promiscuous mode is enabled and port mirroring is configured
2. **Permission errors**: Run the setup script to fix directory permissions
3. **High CPU usage**: Reduce logging level in ntopng.conf
4. **Storage issues**: Configure log rotation and data retention policies

### Enable Promiscuous Mode
```bash
sudo ip link set eth0 promisc on
```

### Check Interface Status
```bash
ip link show eth0
```

### Debug Commands
```bash
# Check interface status
ip link show eth0

# Monitor network traffic
sudo tcpdump -i eth0 -c 100

# Check ntopng logs
docker-compose logs -f ntopng

# Verify data directory permissions
ls -la /home/pi/animated-couscous/ntopng/data
```

## Advanced Features

### Deep Packet Inspection (DPI)
- Enable application protocol detection
- Monitor encrypted traffic patterns
- Identify bandwidth-heavy applications

### Flow Export Integration
```bash
# Export flows to external systems
-F=es:elastic_host=192.168.3.11:9200

# NetFlow/sFlow support
--netflow-port=2055
--sflow-port=6343
```

### API Integration
```bash
# REST API access for automation
curl "http://192.168.3.11:3001/lua/rest/v2/get/host/stats.lua?host=192.168.3.100"

# Export data programmatically
curl "http://192.168.3.11:3001/lua/export_data.lua?format=json"
```

## Performance Tuning

### Resource Optimization
```bash
# Adjust memory limits in docker-compose.yml
mem_limit: 1g
memswap_limit: 1g

# Optimize database settings
--db-file-permissions=0644
--max-num-flows=1000000
--max-num-hosts=10000
```

### Network Optimization
- Use dedicated network interface for monitoring
- Configure network card offloading features
- Optimize buffer sizes for high-traffic networks

## Security Considerations

### Access Control
- Change default admin password
- Restrict web interface to local network
- Use HTTPS for secure access
- Implement user access controls

### Data Privacy
- Configure data anonymization
- Set appropriate retention periods
- Secure backup storage
- Monitor access logs

## Integration with Other Services

### Grafana Integration
- Export metrics to Prometheus
- Create network monitoring dashboards
- Set up bandwidth alerts

### Streamlit Apps
- Build custom traffic analysis tools
- Create parental monitoring interfaces
- Develop network usage reports

### Automation Scripts
```bash
# Automated traffic analysis
python3 scripts/analyze_traffic.py --threshold 1GB --period 1h

# Generate daily reports
python3 scripts/daily_report.py --output /tmp/network_report.pdf
```

## Compliance and Monitoring

### Network Policies
- Monitor compliance with bandwidth policies
- Track usage patterns for capacity planning
- Identify potential security threats

### Reporting
- Generate daily/weekly traffic summaries
- Create device-specific usage reports
- Monitor protocol distribution trends

## Next Steps

After ntopng deployment:
1. Configure network interface for optimal monitoring
2. Set up dashboard customization
3. Integrate with Grafana for alerting
4. Create automated reporting scripts
5. Implement bandwidth monitoring policies
