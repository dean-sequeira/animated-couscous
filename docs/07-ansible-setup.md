# Ansible Configuration Management Setup Instructions

Ansible provides automated configuration management and deployment across multiple Raspberry Pi hosts in the home network infrastructure.

## Service Overview

- **Purpose**: Configuration management and automated deployment
- **Control Node**: Development machine or dedicated Pi
- **Managed Hosts**: All Raspberry Pi devices in the network
- **Dependencies**: Ansible, SSH access, Python on target hosts

## Pre-Installation Requirements

### Control Node Setup
- Ansible installed on control machine
- SSH key-based authentication to all Pi hosts
- Network connectivity to all managed devices
- Git repository access for playbook management

### Managed Host Requirements
- Python 3 installed on all Pi devices
- SSH access enabled
- Sudo privileges for automation user
- Consistent hostname/IP configuration

## Directory Structure
```
ansible/
├── ansible.cfg
├── inventory/
│   ├── hosts.yml
│   ├── group_vars/
│   │   ├── all.yml
│   │   ├── pihole.yml
│   │   ├── monitoring.yml
│   │   └── streamlit.yml
│   └── host_vars/
│       ├── pihole-01.yml
│       ├── monitoring-01.yml
│       └── streamlit-01.yml
├── playbooks/
│   ├── site.yml
│   ├── deploy-pihole.yml
│   ├── deploy-monitoring.yml
│   ├── deploy-streamlit.yml
│   └── system-update.yml
├── roles/
│   ├── common/
│   ├── docker/
│   ├── pihole/
│   ├── monitoring/
│   └── streamlit/
├── templates/
│   ├── docker-compose/
│   ├── configs/
│   └── scripts/
└── scripts/
    ├── setup-ssh-keys.sh
    └── deploy.sh
```

## Installation Steps

### 1. Create Ansible Directory
```bash
mkdir -p /home/pi/animated-couscous/ansible/{inventory,playbooks,roles,templates,scripts}
mkdir -p /home/pi/animated-couscous/ansible/inventory/{group_vars,host_vars}
cd /home/pi/animated-couscous/ansible
```

### 2. Ansible Configuration
Create `ansible.cfg`:
```ini
[defaults]
inventory = inventory/hosts.yml
host_key_checking = False
timeout = 30
gathering = smart
fact_caching = memory
stdout_callback = yaml
bin_ansible_callbacks = True

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
pipelining = True
```

### 3. Inventory Configuration
Create `inventory/hosts.yml`:
```yaml
all:
  children:
    pihole:
      hosts:
        pihole-01:
          ansible_host: 192.168.1.10
          ansible_user: pi
    monitoring:
      hosts:
        monitoring-01:
          ansible_host: 192.168.1.11
          ansible_user: pi
    streamlit:
      hosts:
        streamlit-01:
          ansible_host: 192.168.1.12
          ansible_user: pi
  vars:
    ansible_python_interpreter: /usr/bin/python3
    ansible_ssh_private_key_file: ~/.ssh/id_rsa
```

## Role Development

### Common Role Structure
```
roles/common/
├── tasks/main.yml
├── handlers/main.yml
├── templates/
├── files/
├── vars/main.yml
└── defaults/main.yml
```

### Common Role Tasks
Create `roles/common/tasks/main.yml`:
```yaml
---
- name: Update package cache
  apt:
    update_cache: yes
    cache_valid_time: 3600
  become: yes

- name: Install common packages
  apt:
    name:
      - curl
      - wget
      - git
      - vim
      - htop
      - ufw
      - fail2ban
    state: present
  become: yes

- name: Configure UFW firewall
  ufw:
    state: enabled
    policy: deny
    direction: incoming
  become: yes

- name: Allow SSH
  ufw:
    rule: allow
    port: 22
    proto: tcp
  become: yes

- name: Create application directories
  file:
    path: "{{ item }}"
    state: directory
    owner: pi
    group: pi
    mode: '0755'
  loop:
    - /home/pi/animated-couscous
    - /home/pi/backups
    - /home/pi/logs
```

### Docker Role
Create `roles/docker/tasks/main.yml`:
```yaml
---
- name: Install Docker dependencies
  apt:
    name:
      - apt-transport-https
      - ca-certificates
      - curl
      - gnupg
      - lsb-release
    state: present
  become: yes

- name: Add Docker GPG key
  apt_key:
    url: https://download.docker.com/linux/debian/gpg
    state: present
  become: yes

- name: Add Docker repository
  apt_repository:
    repo: "deb [arch=armhf] https://download.docker.com/linux/debian {{ ansible_distribution_release }} stable"
    state: present
  become: yes

- name: Install Docker
  apt:
    name:
      - docker-ce
      - docker-ce-cli
      - containerd.io
      - docker-compose-plugin
    state: present
  become: yes

- name: Add user to docker group
  user:
    name: pi
    groups: docker
    append: yes
  become: yes

- name: Start and enable Docker
  systemd:
    name: docker
    state: started
    enabled: yes
  become: yes
```

## Service Deployment Playbooks

### Pi-hole Deployment
Create `playbooks/deploy-pihole.yml`:
```yaml
---
- hosts: pihole
  become: yes
  roles:
    - common
    - docker
  tasks:
    - name: Create Pi-hole directories
      file:
        path: "{{ item }}"
        state: directory
        owner: pi
        group: pi
      loop:
        - /home/pi/animated-couscous/pi-hole
        - /home/pi/animated-couscous/pi-hole/config

    - name: Deploy Pi-hole docker-compose
      template:
        src: docker-compose/pihole.yml.j2
        dest: /home/pi/animated-couscous/pi-hole/docker-compose.yml
        owner: pi
        group: pi

    - name: Deploy Pi-hole environment file
      template:
        src: configs/pihole.env.j2
        dest: /home/pi/animated-couscous/pi-hole/.env
        owner: pi
        group: pi
        mode: '0600'

    - name: Start Pi-hole service
      docker_compose:
        project_src: /home/pi/animated-couscous/pi-hole
        state: present
      become_user: pi
```

### System Update Playbook
Create `playbooks/system-update.yml`:
```yaml
---
- hosts: all
  become: yes
  tasks:
    - name: Update package cache
      apt:
        update_cache: yes

    - name: Upgrade all packages
      apt:
        upgrade: dist
        autoremove: yes
        autoclean: yes

    - name: Check if reboot required
      stat:
        path: /var/run/reboot-required
      register: reboot_required

    - name: Reboot system if required
      reboot:
        msg: "Reboot initiated by Ansible for system updates"
        connect_timeout: 5
        reboot_timeout: 300
        pre_reboot_delay: 0
        post_reboot_delay: 30
      when: reboot_required.stat.exists

    - name: Update Docker images
      shell: |
        cd /home/pi/animated-couscous/{{ item }}
        docker-compose pull
        docker-compose up -d
      loop:
        - pi-hole
        - grafana-monitoring
        - streamlit-apps
      become_user: pi
      ignore_errors: yes
```

## Variable Management

### Group Variables
Create `inventory/group_vars/all.yml`:
```yaml
---
# Network Configuration
network_subnet: "192.168.1.0/24"
router_ip: "192.168.1.1"
dns_servers:
  - "1.1.1.1"
  - "1.0.0.1"

# Common Settings
timezone: "America/New_York"
log_retention_days: 30
backup_retention_days: 7

# Docker Configuration
docker_compose_version: "2.20.0"
docker_restart_policy: "unless-stopped"

# Security Settings
ssh_port: 22
fail2ban_enabled: true
ufw_enabled: true
```

### Service-Specific Variables
Create `inventory/group_vars/pihole.yml`:
```yaml
---
pihole_web_password: "{{ vault_pihole_password }}"
pihole_dns_servers:
  - "1.1.1.1"
  - "1.0.0.1"
pihole_interface: "eth0"
pihole_webport: 80
pihole_dnsport: 53

# Custom blocklists
pihole_blocklists:
  - "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
  - "https://mirror1.malwaredomains.com/files/justdomains"
```

## Automation Scripts

### SSH Key Setup
Create `scripts/setup-ssh-keys.sh`:
```bash
#!/bin/bash
# Setup SSH key authentication for all Pi hosts

HOSTS=("192.168.1.10" "192.168.1.11" "192.168.1.12")
USER="pi"

echo "Setting up SSH keys for Raspberry Pi hosts..."

# Generate SSH key if it doesn't exist
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
fi

# Copy SSH key to each host
for host in "${HOSTS[@]}"; do
    echo "Setting up SSH key for $host..."
    ssh-copy-id -i ~/.ssh/id_rsa.pub $USER@$host
done

echo "SSH key setup complete!"
```

### Deployment Script
Create `scripts/deploy.sh`:
```bash
#!/bin/bash
# Main deployment script for all services

set -e

echo "Starting deployment of home network infrastructure..."

# Run system updates
echo "Updating all systems..."
ansible-playbook playbooks/system-update.yml

# Deploy Pi-hole
echo "Deploying Pi-hole..."
ansible-playbook playbooks/deploy-pihole.yml

# Deploy monitoring
echo "Deploying monitoring stack..."
ansible-playbook playbooks/deploy-monitoring.yml

# Deploy Streamlit apps
echo "Deploying Streamlit applications..."
ansible-playbook playbooks/deploy-streamlit.yml

echo "Deployment complete!"
echo "Access points:"
echo "  Pi-hole: http://192.168.1.10/admin"
echo "  Grafana: http://192.168.1.11:3000"
echo "  ntopng: http://192.168.1.11:3001"
echo "  Apps: http://192.168.1.12:8501"
```

## Execution and Management

### Initial Setup
```bash
# Setup SSH keys
chmod +x scripts/setup-ssh-keys.sh
./scripts/setup-ssh-keys.sh

# Test connectivity
ansible all -m ping

# Run initial deployment
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

### Common Operations
```bash
# Update all systems
ansible-playbook playbooks/system-update.yml

# Deploy specific service
ansible-playbook playbooks/deploy-pihole.yml

# Run ad-hoc commands
ansible all -m shell -a "docker ps"
ansible pihole -m service -a "name=docker state=restarted" --become
```

### Maintenance Tasks
```bash
# Check system status
ansible all -m setup -a "filter=ansible_uptime_seconds"

# Backup configurations
ansible all -m archive -a "path=/home/pi/animated-couscous dest=/tmp/config-backup.tar.gz"

# Update Docker images
ansible all -m shell -a "cd /home/pi/animated-couscous && find . -name docker-compose.yml -execdir docker-compose pull \;"
```

## Security and Best Practices

### Vault Usage
```bash
# Create encrypted variables file
ansible-vault create inventory/group_vars/vault.yml

# Edit vault file
ansible-vault edit inventory/group_vars/vault.yml

# Run playbook with vault
ansible-playbook --ask-vault-pass playbooks/site.yml
```

### Idempotency
- Ensure all tasks are idempotent
- Use appropriate Ansible modules
- Test playbooks multiple times

### Error Handling
```yaml
- name: Task with error handling
  command: /some/command
  register: result
  failed_when: result.rc not in [0, 2]
  ignore_errors: yes
```

## Monitoring and Logging

### Ansible Logs
- Configure logging in ansible.cfg
- Monitor playbook execution results
- Set up alerts for failed deployments

### Integration with Grafana
- Track deployment frequency
- Monitor configuration drift
- Alert on automation failures

## Next Steps

After Ansible setup:
1. Create additional playbooks for specific maintenance tasks
2. Implement rolling updates for zero-downtime deployments
3. Set up automated testing of configurations
4. Integrate with CI/CD pipeline for continuous deployment
5. Develop custom modules for specific home automation tasks
