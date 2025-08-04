# Raspberry Pi Setup Instructions

This document provides step-by-step instructions for configuring Raspberry Pi devices for the home network infrastructure project.

## Hardware Requirements

- Raspberry Pi 4 (4GB RAM minimum recommended)
- MicroSD card (32GB+ Class 10)
- **250GB SATA SSD with mSATA to USB adapter**
- Ethernet cable
- Power supply (official Pi adapter recommended)

## Initial OS Setup

### 1. Flash Raspberry Pi OS
```bash
# Download Raspberry Pi Imager
# Use Raspberry Pi OS Lite (64-bit) for headless setup
# Enable SSH, set username/password, configure WiFi if needed
```

### 2. First Boot Configuration
```bash
# SSH into the Pi
ssh pi@<pi-ip-address>

# Update system
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y git vim curl htop ufw fail2ban
```

### 3. External SSD Setup

```bash
# Connect the SSD via USB and identify the device
lsblk
# Look for your SSD (usually /dev/sda or /dev/sdb)

# Check USB devices to confirm SSD is detected
lsusb

# Install required tools for disk management
sudo apt install -y parted

# Partition the SSD (replace /dev/sda with your actual device)
sudo parted /dev/sda --script mklabel gpt
sudo parted /dev/sda --script mkpart primary ext4 0% 100%

# Format the partition with ext4 filesystem
sudo mkfs.ext4 /dev/sda1

# Create mount point for the SSD
sudo mkdir -p /mnt/storage

# Get the UUID of the SSD partition for persistent mounting
sudo blkid /dev/sda1

# Add to fstab for automatic mounting on boot
# Replace YOUR_UUID with the actual UUID from blkid command
echo "UUID=YOUR_UUID /mnt/storage ext4 defaults,noatime 0 2" | sudo tee -a /etc/fstab

# Mount the SSD
sudo mount -a

# Verify mount is successful
df -h | grep storage

# Set proper ownership and permissions
sudo chown pi:pi /mnt/storage
sudo chmod 755 /mnt/storage

# Create directories for different services on the SSD
mkdir -p /mnt/storage/{docker_data,pi_hole_data,grafana_data,streamlit_data,backups}

# Create symlinks for easy access
ln -s /mnt/storage /home/pi/storage
```

### 4. Docker Storage Configuration

```bash
# Stop Docker service
sudo systemctl stop docker

# Create new Docker data directory on SSD
sudo mkdir -p /mnt/storage/docker_data

# Copy existing Docker data (if any)
sudo cp -r /var/lib/docker/* /mnt/storage/docker_data/ 2>/dev/null || true

# Configure Docker to use SSD storage
sudo mkdir -p /etc/docker
cat << EOF | sudo tee /etc/docker/daemon.json
{
  "data-root": "/mnt/storage/docker_data",
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

# Start Docker service
sudo systemctl start docker

# Verify Docker is using new location
docker info | grep "Docker Root Dir"
```

### 5. Docker Setup
```bash
# Install Docker using official script (recommended for Pi)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add pi user to docker group
sudo usermod -aG docker pi

# Install Docker Compose
sudo apt install -y docker-compose-plugin

# Enable Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Logout and login again, then verify installation
docker --version
docker compose version
```

### 6. Static IP Configuration
```bash
# Edit dhcpcd.conf for static IP
sudo nano /etc/dhcpcd.conf

# Add these lines (adjust for your network):
# interface eth0
# static ip_address=192.168.3.100/24
# static routers=192.168.3.1
# static domain_name_servers=192.168.3.1

# Reboot to apply changes
sudo reboot
```

### 7. Security Hardening
```bash
# Change default password
passwd

# Configure firewall
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 53  # DNS for pi_hole
sudo ufw allow 80  # Web interfaces
sudo ufw allow 443 # HTTPS

# Configure fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### 8. Repository Setup
```bash
# Clone the project repository to SSD storage for better performance
git clone <your-repo-url> /mnt/storage/animated-couscous

# Create symlink for easy access from home directory
ln -s /mnt/storage/animated-couscous /home/pi/animated-couscous

# Change to project directory
cd /mnt/storage/animated-couscous

# Create service directories following naming convention
mkdir -p pi_hole ntopng streamlit_apps grafana_monitoring ansible

# Create environment files from examples (when available)
find . -name "*.env.example" -exec sh -c 'cp "$1" "${1%.example}"' _ {} \;
```

## Service-Specific Pi Configuration

### Pi-hole + Monitoring Host (192.168.3.10)
- **Minimum 4GB RAM recommended** (combining multiple services)
- Static IP required
- Services: Pi-hole DNS, ntopng, Grafana, Prometheus
- Ports: 53 (DNS), 80 (Pi-hole Web), 3000 (Grafana), 3001 (ntopng), 9090 (Prometheus)

### Streamlit Apps Host (192.168.3.11)
- 2GB+ RAM recommended
- Port range 8501-8510 for multiple apps
- Services: Internal dashboards and parental control apps

## Network Interface Configuration

### For Bridge Networks (Docker)
```bash
# Enable IP forwarding
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf

# Load bridge module
echo 'br_netfilter' | sudo tee -a /etc/modules

# Apply changes
sudo sysctl -p
sudo modprobe br_netfilter
```

## Troubleshooting

### Common Issues
1. **Docker permission denied**: Ensure user is in docker group, logout/login
2. **Port conflicts**: Check with `sudo netstat -tlnp`
3. **Memory issues**: Monitor with `htop`, consider swap file
4. **Network connectivity**: Verify static IP configuration

### Useful Commands
```bash
# Check system resources
htop
df -h
free -h

# Docker status
docker ps
docker stats

# Network status
ip addr show
sudo netstat -tlnp
```

## Next Steps

After completing this setup:
1. Follow service-specific setup instructions
2. Configure network topology (see 02-network-setup.md)
3. Deploy services using Docker Compose
4. Set up monitoring and alerts
