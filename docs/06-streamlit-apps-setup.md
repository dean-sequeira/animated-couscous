# Streamlit Apps Setup Instructions

Streamlit provides a framework for building internal Python dashboards and web applications for network monitoring, parental controls, and system management.

## Service Overview

- **Purpose**: Internal web applications and dashboards
- **Host Requirements**: Raspberry Pi with 1GB+ RAM (192.168.1.12)
- **Dependencies**: Docker, Docker Compose, Python 3.9+
- **Ports**: 8501-8510 (Multiple Streamlit apps)

## Pre-Installation Requirements

### System Configuration
- Static IP address configured (192.168.1.12)
- Python development environment
- Access to network monitoring data sources

### Application Architecture
- Multi-app deployment with reverse proxy
- Shared data access layer
- Session state management for concurrent users
- File-based storage (no database dependency)

## Directory Structure
```
streamlit-apps/
├── docker-compose.yml
├── .env.example
├── .env
├── requirements.txt
├── apps/
│   ├── network_dashboard/
│   │   ├── app.py
│   │   ├── utils.py
│   │   └── config.py
│   ├── parental_controls/
│   │   ├── app.py
│   │   ├── rules_engine.py
│   │   └── device_manager.py
│   ├── system_monitor/
│   │   ├── app.py
│   │   ├── metrics.py
│   │   └── alerts.py
│   └── shared/
│       ├── auth.py
│       ├── data_sources.py
│       └── components.py
├── data/                    # Shared data storage
│   ├── configs/
│   ├── logs/
│   └── exports/
└── scripts/
    ├── app_launcher.sh
    └── data_sync.sh
```

## Installation Steps

### 1. Create Service Directory
```bash
mkdir -p /home/pi/animated-couscous/streamlit-apps/{apps,data,scripts}
mkdir -p /home/pi/animated-couscous/streamlit-apps/apps/{network_dashboard,parental_controls,system_monitor,shared}
mkdir -p /home/pi/animated-couscous/streamlit-apps/data/{configs,logs,exports}
cd /home/pi/animated-couscous/streamlit-apps
```

### 2. Environment Configuration
Create `.env` file:
```bash
# Streamlit Configuration
STREAMLIT_SERVER_PORT=8501
STREAMLIT_SERVER_ADDRESS=0.0.0.0
STREAMLIT_BROWSER_GATHER_USAGE_STATS=false

# Network Configuration
PIHOLE_API_URL=http://192.168.1.10/admin/api.php
NTOPNG_API_URL=http://192.168.1.11:3001
GRAFANA_API_URL=http://192.168.1.11:3000

# Data Sources
DATA_DIRECTORY=/app/data
LOG_LEVEL=INFO
REFRESH_INTERVAL=30

# Security
SESSION_TIMEOUT=3600
ALLOWED_IPS=192.168.1.0/24
```

### 3. Python Dependencies
Create `requirements.txt`:
```txt
streamlit>=1.28.0
pandas>=2.0.0
plotly>=5.15.0
requests>=2.31.0
pyyaml>=6.0
watchdog>=3.0.0
psutil>=5.9.0
paramiko>=3.2.0
schedule>=1.2.0
```

## Application Development

### Network Dashboard App
Location: `apps/network_dashboard/app.py`

Key Features:
- Real-time bandwidth monitoring
- Device discovery and tracking
- Traffic pattern analysis
- Historical usage trends
- Export capabilities

### Parental Controls App
Location: `apps/parental_controls/app.py`

Key Features:
- Time-based internet restrictions
- Content filtering management
- Device-specific rules
- Usage monitoring and reporting
- Override controls

### System Monitor App
Location: `apps/system_monitor/app.py`

Key Features:
- Raspberry Pi health monitoring
- Service status dashboard
- Resource utilization graphs
- Log file analysis
- Alert management

### Shared Components
Location: `apps/shared/`

Common utilities:
- Authentication helpers
- Data source connectors
- Reusable UI components
- Configuration management

## Service Management

### Start All Applications
```bash
cd /home/pi/animated-couscous/streamlit-apps
docker-compose up -d
```

### Individual App Management
```bash
# Start specific app
docker-compose up -d network-dashboard

# View logs
docker-compose logs -f parental-controls

# Restart app
docker-compose restart system-monitor
```

### Development Mode
```bash
# Run single app for development
streamlit run apps/network_dashboard/app.py --server.port 8501
```

## Application Configuration

### Session State Management
```python
# Example session state handling
import streamlit as st

def init_session_state():
    if 'user_preferences' not in st.session_state:
        st.session_state.user_preferences = load_user_config()
    if 'last_refresh' not in st.session_state:
        st.session_state.last_refresh = datetime.now()
```

### Data Source Integration
```python
# Shared data access layer
class DataSourceManager:
    def __init__(self):
        self.pihole_api = PiHoleAPI(os.getenv('PIHOLE_API_URL'))
        self.ntopng_api = NtopngAPI(os.getenv('NTOPNG_API_URL'))
    
    def get_network_stats(self):
        return {
            'dns_queries': self.pihole_api.get_query_stats(),
            'traffic_data': self.ntopng_api.get_traffic_summary()
        }
```

### File-Based Storage
```python
# Configuration persistence
import yaml
import json

def save_config(config_name, data):
    config_path = f"/app/data/configs/{config_name}.yaml"
    with open(config_path, 'w') as f:
        yaml.dump(data, f)

def load_config(config_name):
    config_path = f"/app/data/configs/{config_name}.yaml"
    try:
        with open(config_path, 'r') as f:
            return yaml.safe_load(f)
    except FileNotFoundError:
        return {}
```

## UI/UX Guidelines

### Layout Design
```python
# Clean, minimal layout structure
st.set_page_config(
    page_title="Network Dashboard",
    page_icon="🌐",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Use columns for responsive design
col1, col2, col3 = st.columns([1, 2, 1])
```

### Interactive Components
```python
# Real-time updates with auto-refresh
placeholder = st.empty()
refresh_interval = st.sidebar.slider("Refresh Interval (seconds)", 5, 60, 30)

# Use session state for form persistence
with st.form("device_rules"):
    device = st.selectbox("Select Device", device_list)
    time_restrictions = st.time_input("Block until", value=datetime.time(22, 0))
    submitted = st.form_submit_button("Apply Rules")
```

### Data Visualization
```python
# Plotly for interactive charts
import plotly.express as px
import plotly.graph_objects as go

# Bandwidth usage chart
fig = px.line(
    df, x='timestamp', y='bandwidth_mbps',
    title='Network Bandwidth Usage',
    labels={'bandwidth_mbps': 'Bandwidth (Mbps)'}
)
st.plotly_chart(fig, use_container_width=True)
```

## Deployment Configuration

### Multi-App Reverse Proxy
```nginx
# nginx configuration for app routing
upstream network_dashboard {
    server streamlit-network:8501;
}

upstream parental_controls {
    server streamlit-parental:8502;
}

server {
    listen 80;
    server_name apps.local;
    
    location /network/ {
        proxy_pass http://network_dashboard/;
        proxy_set_header Host $host;
    }
    
    location /parental/ {
        proxy_pass http://parental_controls/;
        proxy_set_header Host $host;
    }
}
```

### Docker Configuration
Each app runs in its own container with shared volumes for data persistence and inter-app communication.

## Monitoring and Maintenance

### Application Health Checks
```python
# Health check endpoint
def health_check():
    checks = {
        'pihole_connection': test_pihole_api(),
        'ntopng_connection': test_ntopng_api(),
        'data_directory': os.path.exists('/app/data'),
        'memory_usage': psutil.virtual_memory().percent < 80
    }
    return all(checks.values()), checks
```

### Log Management
```python
import logging

# Structured logging configuration
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/app/data/logs/app.log'),
        logging.StreamHandler()
    ]
)
```

### Performance Optimization
- Use st.cache_data for expensive operations
- Implement lazy loading for large datasets
- Optimize chart rendering with data sampling
- Use session state efficiently

## Security Implementation

### Access Control
```python
# Simple IP-based access control
def check_access():
    client_ip = st.context.headers.get('X-Forwarded-For', 'unknown')
    allowed_networks = ['192.168.1.0/24']
    return is_ip_in_networks(client_ip, allowed_networks)
```

### Input Validation
```python
# Sanitize user inputs
def validate_device_name(name):
    import re
    pattern = r'^[a-zA-Z0-9-_]+$'
    return re.match(pattern, name) is not None

def validate_time_range(start_time, end_time):
    return start_time < end_time
```

## Integration Features

### API Endpoints
```python
# REST API for external integration
from flask import Flask, jsonify
app = Flask(__name__)

@app.route('/api/network/status')
def network_status():
    return jsonify(get_network_stats())

@app.route('/api/parental/rules/<device_id>')
def get_device_rules(device_id):
    return jsonify(load_device_rules(device_id))
```

### Automation Scripts
```bash
# Daily report generation
python3 scripts/generate_daily_report.py --output /app/data/exports/

# Configuration backup
python3 scripts/backup_configs.py --destination /home/pi/backups/
```

## Troubleshooting

### Common Issues
1. **Apps not loading**: Check port conflicts and Docker status
2. **Data not updating**: Verify API connections and permissions
3. **Slow performance**: Monitor resource usage and optimize queries
4. **Session issues**: Clear browser cache and check session timeout

### Debug Mode
```python
# Enable debug mode
st.write("Debug Info:")
st.write(f"Session State: {st.session_state}")
st.write(f"Connection Status: {test_all_connections()}")
```

## Next Steps

After Streamlit apps deployment:
1. Customize dashboards for specific use cases
2. Implement user authentication system
3. Set up automated data exports
4. Create mobile-responsive layouts
5. Integrate with notification systems
