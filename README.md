# animated-couscous
A Raspberry Pi-powered home network setup with Pi-hole, private Streamlit apps, parental controls, and dashboards to keep an eye on internet use. Everything's version-controlled, automated, and runs locally—no cloud needed.

## 🏗️ Architecture Overview

This project creates a self-hosted home network infrastructure using multiple Raspberry Pi devices:

- **DNS & Ad Blocking**: Pi-hole for network-wide ad blocking
- **Traffic Monitoring**: ntopng for real-time network analysis  
- **System Monitoring**: Grafana + Prometheus for metrics and alerting
- **Internal Apps**: Streamlit dashboards for network management
- **Automation**: Ansible for configuration management across devices

## 📋 Prerequisites

- 2-4 Raspberry Pi 4 devices (4GB RAM recommended)
- MicroSD cards (32GB+ Class 10) and SSDs (250GB+) for storage
- Network switch/router with static IP capability
- Basic knowledge of Docker, networking, and Linux administration

## 🚀 Setup Guide

**⚠️ Important**: Follow these steps in order, as later services depend on earlier ones being properly configured.

### Phase 1: Foundation Setup

#### 1. Hardware & OS Preparation
📖 **[01-raspberry-pi-setup.md](docs/01-raspberry-pi-setup.md)**

Set up each Raspberry Pi with:
- Raspberry Pi OS installation and initial configuration
- Docker and Docker Compose installation
- SSD storage configuration for persistent data
- SSH access and security hardening

#### 2. Network Architecture
📖 **[02-network-setup.md](docs/02-network-setup.md)**

Configure your network topology:
- Static IP assignments for each Pi
- Router/firewall rule configuration
- Port allocation planning
- Network security considerations

**🔗 Dependencies**: Requires Pi hardware setup from step 1

### Phase 2: Core Services

#### 3. DNS & Ad Blocking (Pi-hole)
📖 **[03-pihole-setup.md](docs/03-pihole-setup.md)**

Deploy Pi-hole as your primary DNS server:
- Docker Compose configuration
- Custom blocklists and whitelists
- Router DNS configuration
- Backup and restore procedures

**🔗 Dependencies**: Requires network setup from step 2

#### 4. Traffic Monitoring (ntopng)
📖 **[04-ntopng-setup.md](docs/04-ntopng-setup.md)**

Set up network traffic analysis:
- Real-time bandwidth monitoring
- Device activity tracking
- Historical traffic analysis
- Network interface configuration

**🔗 Dependencies**: Requires network setup from step 2

### Phase 3: Advanced Monitoring

#### 5. System Monitoring (Grafana)
📖 **[05-grafana-monitoring-setup.md](docs/05-grafana-monitoring-setup.md)**

Deploy comprehensive monitoring stack:
- Grafana dashboards for visualization
- Prometheus for metrics collection
- Node exporters for system metrics
- Alerting rules and notifications

**🔗 Dependencies**: Requires Pi-hole and ntopng services for complete monitoring

### Phase 4: Applications & Management

#### 6. Internal Applications (Streamlit)
📖 **[06-streamlit-apps-setup.md](docs/06-streamlit-apps-setup.md)**

Deploy custom web applications:
- Parental control dashboards
- Network usage analytics
- System administration tools
- Multi-app deployment with reverse proxy

**🔗 Dependencies**: Requires all monitoring services for data access

#### 7. Configuration Management (Ansible)
📖 **[07-ansible-setup.md](docs/07-ansible-setup.md)**

Automate deployment and updates:
- Playbooks for service deployment
- Configuration synchronization
- Automated backups and updates
- Multi-host orchestration

**🔗 Dependencies**: Requires all services to be initially deployed

## 📊 Service Architecture

```
Internet
    |
Router/Gateway (192.168.3.1)
    |
    ├── Pi-hole DNS (192.168.3.10) - Ad blocking, Custom DNS
    ├── Monitoring Host (192.168.3.11) - ntopng, Grafana, Prometheus
    ├── App Host (192.168.3.12) - Streamlit dashboards
    └── Client Devices (192.168.3.100-254)
```

## 🔧 Quick Start

For experienced users who want to deploy everything at once:

```bash
# Clone the repository
git clone <repository-url>
cd animated-couscous

# Follow the setup docs in order 1-7
# Or use Ansible after manual setup of first Pi:
ansible-playbook -i inventory/hosts playbooks/site.yml
```

## 📁 Repository Structure

```
├── docs/                    # Step-by-step setup documentation
├── pi_hole/                 # Pi-hole DNS server configuration
├── ntopng/                  # Network traffic monitoring
├── grafana_monitoring/      # System monitoring stack
├── streamlit_apps/          # Internal web applications
└── ansible/                 # Configuration management (if present)
```

## 🛠️ Key Features

- **Local-Only**: No cloud dependencies, complete privacy
- **Automated**: Docker Compose + Ansible for easy deployment
- **Scalable**: Add more Pis as your network grows
- **Monitored**: Comprehensive dashboards for all services
- **Secured**: Network-level filtering and access controls

## 📚 Documentation

Each service has detailed setup instructions in the `docs/` directory. Start with `01-raspberry-pi-setup.md` and follow the numbered sequence for best results.

## 🤝 Contributing

This project follows infrastructure-as-code principles. All configurations are version-controlled and reproducible. See individual service READMEs for development guidelines.

## ⚖️ License

[Add your license information here]
