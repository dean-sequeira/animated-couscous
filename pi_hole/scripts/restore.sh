#!/bin/bash
# Pi-hole restore script

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <backup_file.tar.gz>"
    echo "Available backups:"
    ls -la /home/pi/backups/pihole/pihole_backup_*.tar.gz 2>/dev/null || echo "No backups found"
    exit 1
fi

BACKUP_FILE="$1"
RESTORE_DIR="/tmp/pihole_restore_$(date +%Y%m%d_%H%M%S)"

echo "Restoring Pi-hole from backup: $BACKUP_FILE"

# Verify backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file not found: $BACKUP_FILE"
    exit 1
fi

# Create temporary restore directory
mkdir -p "$RESTORE_DIR"

# Extract backup
echo "Extracting backup..."
tar -xzf "$BACKUP_FILE" -C "$RESTORE_DIR"

# Stop Pi-hole service
echo "Stopping Pi-hole service..."
cd /home/pi/animated-couscous/pi_hole
docker compose stop pihole

# Backup current configuration
echo "Backing up current configuration..."
mv config config.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Restore configuration
echo "Restoring configuration..."
cp -r "$RESTORE_DIR/config" .
cp "$RESTORE_DIR/.env" . 2>/dev/null || echo "Warning: .env file not found in backup"

# Set proper permissions
sudo chown -R pi:pi config/
chmod 755 config/

# Start Pi-hole service
echo "Starting Pi-hole service..."
docker compose up -d pihole

# Clean up
rm -rf "$RESTORE_DIR"

echo "Pi-hole restore completed successfully!"
echo "Please verify service is running: docker compose ps"
