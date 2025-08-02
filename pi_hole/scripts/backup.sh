#!/bin/bash
# Pi-hole configuration backup script

set -e

BACKUP_DIR="/home/pi/backups/pihole"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="pihole_backup_${DATE}.tar.gz"

echo "Starting Pi-hole backup..."

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Stop Pi-hole service for consistent backup
echo "Stopping Pi-hole service..."
cd /home/pi/animated-couscous/pi_hole
docker compose stop pihole

# Create backup archive
echo "Creating backup archive..."
tar -czf "$BACKUP_DIR/$BACKUP_FILE" \
    --exclude='*.log' \
    --exclude='*.db-shm' \
    --exclude='*.db-wal' \
    config/ \
    .env \
    docker-compose.yml

# Restart Pi-hole service
echo "Restarting Pi-hole service..."
docker compose start pihole

# Clean up old backups (keep last 7 days)
find "$BACKUP_DIR" -name "pihole_backup_*.tar.gz" -mtime +7 -delete

echo "Backup completed: $BACKUP_DIR/$BACKUP_FILE"

# Verify backup
if [ -f "$BACKUP_DIR/$BACKUP_FILE" ]; then
    echo "Backup verification: OK"
    ls -lh "$BACKUP_DIR/$BACKUP_FILE"
else
    echo "Backup verification: FAILED"
    exit 1
fi
