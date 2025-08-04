#!/bin/bash
# ntopng Data Backup Script
# This script backs up ntopng configuration and data

set -e

# Configuration
BACKUP_DIR="/backup/ntopng"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="ntopng_backup_${DATE}"
RETENTION_DAYS=30

echo "Starting ntopng backup..."

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Create timestamped backup directory
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"
mkdir -p "$BACKUP_PATH"

# Stop ntopng service temporarily
echo "Stopping ntopng service..."
docker-compose down

# Backup data directory
echo "Backing up data directory..."
if [ -d "data" ]; then
    tar -czf "$BACKUP_PATH/data.tar.gz" data/
    echo "Data directory backed up"
else
    echo "No data directory found"
fi

# Backup configuration files
echo "Backing up configuration..."
tar -czf "$BACKUP_PATH/config.tar.gz" config/ .env 2>/dev/null || true

# Backup logs
echo "Backing up logs..."
if [ -d "/var/log/ntopng" ]; then
    sudo tar -czf "$BACKUP_PATH/logs.tar.gz" /var/log/ntopng/
    echo "Logs backed up"
fi

# Create backup manifest
cat > "$BACKUP_PATH/manifest.txt" << EOF
ntopng Backup Manifest
=====================
Backup Date: $(date)
Backup Path: $BACKUP_PATH
Contents:
- Configuration files (config.tar.gz)
- Data directory (data.tar.gz)
- Log files (logs.tar.gz)
- Environment file (.env)

Restore Instructions:
1. Stop ntopng: docker-compose down
2. Extract data: tar -xzf data.tar.gz
3. Extract config: tar -xzf config.tar.gz
4. Extract logs: sudo tar -xzf logs.tar.gz -C /
5. Start ntopng: docker-compose up -d
EOF

# Start ntopng service
echo "Restarting ntopng service..."
docker-compose up -d

# Cleanup old backups
echo "Cleaning up old backups (older than $RETENTION_DAYS days)..."
find "$BACKUP_DIR" -type d -name "ntopng_backup_*" -mtime +$RETENTION_DAYS -exec rm -rf {} + 2>/dev/null || true

# Calculate backup size
BACKUP_SIZE=$(du -sh "$BACKUP_PATH" | cut -f1)

echo "Backup completed successfully!"
echo "Backup location: $BACKUP_PATH"
echo "Backup size: $BACKUP_SIZE"
echo "Manifest file: $BACKUP_PATH/manifest.txt"
