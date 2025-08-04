#!/bin/bash

# Script to install Pi-hole as a systemd service for auto-start on boot
# Run this script with: sudo ./install-systemd-service.sh

set -e

# Define variables
SERVICE_NAME="pihole"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
PROJECT_DIR="/mnt/storage/animated-couscous/pi_hole"
USER="pi"

echo "Installing Pi-hole systemd service..."

# Create the systemd service file
cat << EOF > "${SERVICE_FILE}"
[Unit]
Description=Pi-hole DNS and DHCP Server
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
User=${USER}
Group=${USER}
WorkingDirectory=${PROJECT_DIR}
ExecStartPre=/usr/bin/docker compose -f ${PROJECT_DIR}/docker-compose.yml down
ExecStart=/usr/bin/docker compose -f ${PROJECT_DIR}/docker-compose.yml up -d
ExecStop=/usr/bin/docker compose -f ${PROJECT_DIR}/docker-compose.yml down
ExecReload=/usr/bin/docker compose -f ${PROJECT_DIR}/docker-compose.yml restart
TimeoutStartSec=300
TimeoutStopSec=60

[Install]
WantedBy=multi-user.target
EOF

echo "Systemd service file created at ${SERVICE_FILE}"

# Set proper permissions
chmod 644 "${SERVICE_FILE}"

# Reload systemd and enable the service
systemctl daemon-reload
systemctl enable "${SERVICE_NAME}.service"

echo "Pi-hole service installed and enabled for auto-start"
echo "Service status: $(systemctl is-enabled ${SERVICE_NAME})"

# Show service management commands
echo ""
echo "Service management commands:"
echo "  Start:   sudo systemctl start ${SERVICE_NAME}"
echo "  Stop:    sudo systemctl stop ${SERVICE_NAME}"
echo "  Restart: sudo systemctl restart ${SERVICE_NAME}"
echo "  Status:  sudo systemctl status ${SERVICE_NAME}"
echo "  Logs:    sudo journalctl -u ${SERVICE_NAME} -f"
