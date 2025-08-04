#!/bin/bash
# ntopng Setup Script
# This script initializes the ntopng service and required directories

set -e

echo "Setting up ntopng traffic monitoring..."

# Detect Docker Compose command (v1 vs v2)
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
elif docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    echo "Error: Neither 'docker-compose' nor 'docker compose' found"
    echo "Please install Docker Compose first."
    exit 1
fi

echo "Using Docker Compose command: $DOCKER_COMPOSE"

# Create required directories
echo "Creating directories..."
mkdir -p data
mkdir -p logs
sudo mkdir -p /var/log/ntopng

# Set proper permissions
echo "Setting permissions..."
sudo chown -R 1000:1000 data
sudo chown -R 1000:1000 /var/log/ntopng
chmod -R 755 data
chmod -R 755 config

# Copy environment file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file from template..."
    cp .env.example .env
    echo "Please edit .env file with your specific configuration"
fi

# Enable promiscuous mode for network interface
INTERFACE=${NETWORK_INTERFACE:-eth0}
echo "Enabling promiscuous mode for interface $INTERFACE..."
sudo ip link set $INTERFACE promisc on

# Install dependencies if needed
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Please install Docker first."
    exit 1
fi

# Pull the latest ntopng image
echo "Pulling ntopng Docker image..."
$DOCKER_COMPOSE pull

# Create systemd service (optional)
read -p "Do you want to create a systemd service? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Detect which docker-compose command to use in systemd service
    COMPOSE_CMD=$(which docker-compose 2>/dev/null || echo "docker compose")

    sudo tee /etc/systemd/system/ntopng.service > /dev/null <<EOF
[Unit]
Description=ntopng Traffic Monitoring
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$(pwd)
ExecStart=${COMPOSE_CMD} up -d
ExecStop=${COMPOSE_CMD} down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable ntopng.service
    echo "Systemd service created and enabled"
fi

echo "Setup complete!"
echo "To start ntopng: $DOCKER_COMPOSE up -d"
echo "Web interface will be available at: http://$(hostname -I | cut -d' ' -f1):3001"
echo "Please ensure your network interface supports promiscuous mode and traffic mirroring is configured on your router."
