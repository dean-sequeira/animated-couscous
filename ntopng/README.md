# ntopng Traffic Monitoring Service

ntopng provides real-time network traffic monitoring and analysis, offering insights into bandwidth usage, device activity, and network performance for your home network infrastructure.

## Features

- **Real-time Traffic Analysis**: Monitor network traffic in real-time
- **Device Discovery**: Automatically discover and track network devices
- **Bandwidth Monitoring**: Track bandwidth usage per device and application
- **Security Alerts**: Detect suspicious network activity and security threats
- **Historical Data**: Store and analyze historical network data
- **Web Interface**: Easy-to-use web dashboard for monitoring

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

## Configuration

### Network Interface
Update the `NETWORK_INTERFACE` in your `.env` file to match your primary network interface (usually `eth0` or `wlan0`).

### Local Network
Set the `LOCAL_NETWORK` to match your subnet (e.g., `192.168.3.0/24`).

### Traffic Categories
Edit `config/categories.txt` to customize traffic categorization rules.

### Alert Rules
Modify `config/alerts.conf` to configure network alerts and thresholds.

## Network Requirements

- **Promiscuous Mode**: The network interface must support promiscuous mode
- **Port Mirroring**: For complete traffic visibility, configure port mirroring on your router/switch
- **Static IP**: Recommended to use a static IP address for the monitoring host

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
    └── backup.sh        # Data backup script
```

## Security Notes

- The service is configured to disable login for internal network use
- For external access, enable authentication and HTTPS
- Regular backup of configuration and data is recommended
- Monitor alert logs for security events

## Performance Tuning

For large networks or high-traffic environments:

1. **Increase memory allocation** in docker-compose.yml
2. **Enable database backend** for better performance
3. **Adjust log levels** to reduce I/O overhead
4. **Configure data retention** to manage storage usage
