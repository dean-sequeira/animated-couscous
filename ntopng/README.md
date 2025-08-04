# ntopng Traffic Monitoring Service

This directory contains the ntopng traffic monitoring service configuration.

## Documentation

For complete setup instructions, configuration details, and troubleshooting, see:
**[docs/04-ntopng-setup.md](../docs/04-ntopng-setup.md)**

## Quick Reference

- **Web Interface**: http://192.168.3.11:3001
- **Configuration**: Copy `.env.example` to `.env` and customize
- **Start Service**: `docker-compose up -d`
- **Management**: `./scripts/manage.sh [command]`

## Directory Contents

- `docker-compose.yml` - Service definition
- `.env.example` - Environment template
- `config/` - ntopng configuration files
- `scripts/` - Setup, backup, and management scripts
- `data/` - Persistent data storage (created on first run)
- `logs/` - Log files (created on first run)
