# Grafana Monitoring Setup Instructions

Grafana provides comprehensive monitoring dashboards for system metrics, network performance, and service health across the home network infrastructure.

## Service Overview

- **Purpose**: Centralized monitoring and alerting platform
- **Host Requirements**: Raspberry Pi with 2GB+ RAM (192.168.1.11)
- **Dependencies**: Docker, Docker Compose, Prometheus
- **Ports**: 3000 (Web Interface), 9090 (Prometheus)

## Pre-Installation Requirements

### System Configuration
- Static IP address configured (192.168.1.11)
- Sufficient storage for metrics retention
- Network access to all monitored services

### Monitoring Stack
- Grafana for visualization and dashboards
- Prometheus for metrics collection
- Node Exporter for system metrics
- Custom exporters for Pi-hole and ntopng

## Directory Structure
```
grafana-monitoring/
├── docker-compose.yml
├── .env.example
├── .env
├── prometheus/
│   ├── prometheus.yml
│   ├── rules/
│   │   ├── network.yml
│   │   ├── system.yml
│   │   └── pihole.yml
│   └── targets/
│       └── static_configs.yml
├── grafana/
│   ├── provisioning/
│   │   ├── dashboards/
│   │   │   ├── network-overview.json
│   │   │   ├── pihole-stats.json
│   │   │   └── system-health.json
│   │   └── datasources/
│   │       └── prometheus.yml
│   └── plugins/
├── exporters/
│   ├── pihole-exporter/
│   ├── ntopng-exporter/
│   └── custom-scripts/
└── data/                    # Persistent storage
    ├── grafana/
    └── prometheus/
```

## Installation Steps

### 1. Create Service Directory
```bash
mkdir -p /home/pi/animated-couscous/grafana-monitoring/{prometheus,grafana,exporters,data}
mkdir -p /home/pi/animated-couscous/grafana-monitoring/prometheus/{rules,targets}
mkdir -p /home/pi/animated-couscous/grafana-monitoring/grafana/provisioning/{dashboards,datasources}
cd /home/pi/animated-couscous/grafana-monitoring
```

### 2. Environment Configuration
Create `.env` file:
```bash
# Grafana Configuration
GRAFANA_PORT=3000
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=your_secure_password

# Prometheus Configuration
PROMETHEUS_PORT=9090
PROMETHEUS_RETENTION=30d
PROMETHEUS_STORAGE_PATH=/prometheus

# Data Sources
PIHOLE_HOST=192.168.1.10
NTOPNG_HOST=192.168.1.11
ROUTER_HOST=192.168.1.1

# Alerting
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
ALERT_EMAIL=alerts@yourdomain.com
```

### 3. Prometheus Configuration
Create `prometheus/prometheus.yml`:
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "rules/*.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  # Prometheus self-monitoring
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # System metrics from Node Exporter
  - job_name: 'node-exporter'
    static_configs:
      - targets: 
        - '192.168.1.10:9100'  # Pi-hole host
        - '192.168.1.11:9100'  # Monitoring host
        - '192.168.1.12:9100'  # Streamlit host

  # Pi-hole metrics
  - job_name: 'pihole'
    static_configs:
      - targets: ['192.168.1.10:9617']
    scrape_interval: 30s

  # Custom network metrics
  - job_name: 'network-health'
    static_configs:
      - targets: ['192.168.1.11:9116']
    scrape_interval: 60s
```

## Service Configuration

### Grafana Provisioning
Configure automatic dashboard and datasource provisioning:

**Datasources** (`grafana/provisioning/datasources/prometheus.yml`):
```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
```

### Alert Rules
Create `prometheus/rules/network.yml`:
```yaml
groups:
  - name: network.rules
    rules:
      - alert: PiHoleDown
        expr: up{job="pihole"} == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Pi-hole service is down"
          description: "Pi-hole has been down for more than 2 minutes"

      - alert: HighDNSQueries
        expr: pihole_queries_today > 50000
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Unusual DNS query volume"
          description: "DNS queries today: {{ $value }}"

      - alert: HighBandwidthUsage
        expr: rate(network_bytes_total[5m]) > 100000000  # 100 MB/s
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High bandwidth usage detected"
          description: "Network usage: {{ $value | humanize }}B/s"
```

### System Health Rules
Create `prometheus/rules/system.yml`:
```yaml
groups:
  - name: system.rules
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is above 80%"

      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"
          description: "Memory usage is above 85%"

      - alert: LowDiskSpace
        expr: (1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100 > 90
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Low disk space on {{ $labels.instance }}"
          description: "Disk usage is above 90%"
```

## Dashboard Configuration

### Network Overview Dashboard
Key metrics to display:
- Real-time bandwidth utilization
- Device connection status
- DNS query statistics
- Top bandwidth consumers
- Network topology view

### Pi-hole Monitoring Dashboard
Metrics include:
- Queries blocked percentage
- Top blocked domains
- Query types distribution
- Client activity
- Blocklist effectiveness

### System Health Dashboard
Monitor:
- CPU and memory usage across all Pis
- Disk space utilization
- Network interface statistics
- Service uptime
- Temperature monitoring

## Custom Exporters

### Pi-hole Exporter
```python
# exporters/pihole-exporter/exporter.py
import requests
import time
from prometheus_client import start_http_server, Gauge

# Define metrics
pihole_queries_today = Gauge('pihole_queries_today', 'Total queries today')
pihole_blocked_today = Gauge('pihole_blocked_today', 'Blocked queries today')
pihole_percent_blocked = Gauge('pihole_percent_blocked', 'Percentage blocked')

def collect_pihole_metrics():
    try:
        response = requests.get('http://192.168.1.10/admin/api.php')
        data = response.json()
        
        pihole_queries_today.set(data['dns_queries_today'])
        pihole_blocked_today.set(data['ads_blocked_today'])
        pihole_percent_blocked.set(data['ads_percentage_today'])
    except Exception as e:
        print(f"Error collecting Pi-hole metrics: {e}")

if __name__ == '__main__':
    start_http_server(9617)
    while True:
        collect_pihole_metrics()
        time.sleep(30)
```

### Network Health Exporter
```python
# exporters/network-health/exporter.py
import subprocess
import time
from prometheus_client import start_http_server, Gauge

# Network connectivity metrics
ping_success = Gauge('network_ping_success', 'Ping success', ['target'])
ping_latency = Gauge('network_ping_latency_ms', 'Ping latency in ms', ['target'])

def ping_check(host):
    try:
        result = subprocess.run(['ping', '-c', '1', '-W', '2', host], 
                              capture_output=True, text=True)
        if result.returncode == 0:
            # Extract latency from ping output
            latency = float(result.stdout.split('time=')[1].split(' ms')[0])
            return True, latency
        else:
            return False, 0
    except:
        return False, 0

def collect_network_metrics():
    targets = ['192.168.1.1', '192.168.1.10', '192.168.1.12', '8.8.8.8']
    
    for target in targets:
        success, latency = ping_check(target)
        ping_success.labels(target=target).set(1 if success else 0)
        if success:
            ping_latency.labels(target=target).set(latency)

if __name__ == '__main__':
    start_http_server(9116)
    while True:
        collect_network_metrics()
        time.sleep(60)
```

## Service Management

### Start Monitoring Stack
```bash
cd /home/pi/animated-couscous/grafana-monitoring
docker-compose up -d
```

### Access Interfaces
- **Grafana**: http://192.168.1.11:3000 (admin/password from .env)
- **Prometheus**: http://192.168.1.11:9090

### Health Checks
```bash
# Check all services
docker-compose ps

# View logs
docker-compose logs grafana
docker-compose logs prometheus

# Test metric collection
curl http://192.168.1.11:9090/api/v1/query?query=up
```

## Alerting Configuration

### Email Notifications
Configure in Grafana:
1. Add SMTP notification channel
2. Set up alert rules in dashboards
3. Configure escalation policies

### Webhook Integrations
```yaml
# Add to docker-compose.yml for custom alerting
alertmanager:
  image: prom/alertmanager
  ports:
    - "9093:9093"
  volumes:
    - ./alertmanager.yml:/etc/alertmanager/alertmanager.yml
```

## Performance Optimization

### Metrics Retention
- Configure appropriate retention periods
- Use recording rules for complex queries
- Implement metric downsampling

### Query Optimization
- Use efficient PromQL queries
- Cache frequently accessed data
- Limit dashboard refresh rates

## Backup and Recovery

### Configuration Backup
```bash
# Backup Grafana dashboards
curl -H "Authorization: Bearer <api-key>" \
  http://192.168.1.11:3000/api/search?dashboardIds > dashboards.json

# Backup Prometheus data
docker-compose exec prometheus promtool tsdb snapshot /prometheus
```

### Disaster Recovery
- Document all configuration files in git
- Automate dashboard provisioning
- Implement regular data exports

## Troubleshooting

### Common Issues
1. **Metrics not appearing**: Check exporter connectivity
2. **High memory usage**: Adjust retention settings
3. **Dashboard errors**: Verify datasource configuration
4. **Alert fatigue**: Fine-tune alert thresholds

### Debug Commands
```bash
# Check Prometheus targets
curl http://192.168.1.11:9090/api/v1/targets

# Test PromQL queries
curl 'http://192.168.1.11:9090/api/v1/query?query=up'

# Validate configuration
docker-compose exec prometheus promtool check config /etc/prometheus/prometheus.yml
```

## Integration Features

### API Access
- Grafana HTTP API for dashboard management
- Prometheus query API for custom applications
- Webhook endpoints for external alerting

### Automation Scripts
```bash
# Daily report generation
python3 scripts/generate_reports.py --period 24h

# Automatic dashboard updates
python3 scripts/update_dashboards.py --source templates/
```

## Next Steps

After Grafana deployment:
1. Import pre-built dashboard templates
2. Configure alert notification channels
3. Set up automated report generation
4. Implement custom metrics for specific use cases
5. Create mobile-friendly dashboard views
