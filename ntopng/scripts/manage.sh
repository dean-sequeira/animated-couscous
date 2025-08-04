#!/bin/bash
# ntopng Service Management Script
# Provides common operations for managing the ntopng service

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Change to project directory
cd "$PROJECT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_status() {
    log_info "ntopng Service Status:"
    docker-compose ps
    echo
    log_info "Service Health:"
    docker-compose exec ntopng ntopng --version 2>/dev/null || log_warn "Service may not be running"
}

start_service() {
    log_info "Starting ntopng service..."
    docker-compose up -d
    log_info "Service started. Web interface available at: http://$(hostname -I | cut -d' ' -f1):3001"
}

stop_service() {
    log_info "Stopping ntopng service..."
    docker-compose down
    log_info "Service stopped"
}

restart_service() {
    log_info "Restarting ntopng service..."
    docker-compose restart
    log_info "Service restarted"
}

update_service() {
    log_info "Updating ntopng service..."
    docker-compose pull
    docker-compose up -d
    log_info "Service updated"
}

view_logs() {
    log_info "Showing ntopng logs (Ctrl+C to exit)..."
    docker-compose logs -f ntopng
}

check_network() {
    log_info "Checking network interface configuration..."

    # Check if .env exists
    if [ ! -f .env ]; then
        log_error ".env file not found. Please copy from .env.example and configure."
        return 1
    fi

    # Source environment variables
    source .env

    # Check interface exists
    if ! ip link show "$NETWORK_INTERFACE" &>/dev/null; then
        log_error "Network interface '$NETWORK_INTERFACE' not found"
        log_info "Available interfaces:"
        ip link show | grep -E '^[0-9]+:' | cut -d':' -f2 | sed 's/^ *//'
        return 1
    fi

    # Check promiscuous mode
    if ip link show "$NETWORK_INTERFACE" | grep -q PROMISC; then
        log_info "Promiscuous mode is enabled on $NETWORK_INTERFACE"
    else
        log_warn "Promiscuous mode is NOT enabled on $NETWORK_INTERFACE"
        log_info "Enable with: sudo ip link set $NETWORK_INTERFACE promisc on"
    fi
}

cleanup_data() {
    read -p "This will remove all ntopng data. Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Cleaning up ntopng data..."
        docker-compose down
        sudo rm -rf data/*
        sudo rm -rf /var/log/ntopng/*
        log_info "Data cleanup completed"
    else
        log_info "Cleanup cancelled"
    fi
}

show_help() {
    echo "ntopng Service Management Script"
    echo
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  start       Start the ntopng service"
    echo "  stop        Stop the ntopng service"
    echo "  restart     Restart the ntopng service"
    echo "  status      Show service status and health"
    echo "  logs        View service logs"
    echo "  update      Update ntopng to latest version"
    echo "  network     Check network interface configuration"
    echo "  backup      Create a backup of configuration and data"
    echo "  cleanup     Remove all data (requires confirmation)"
    echo "  help        Show this help message"
    echo
}

# Main command processing
case "${1:-help}" in
    start)
        start_service
        ;;
    stop)
        stop_service
        ;;
    restart)
        restart_service
        ;;
    status)
        show_status
        ;;
    logs)
        view_logs
        ;;
    update)
        update_service
        ;;
    network)
        check_network
        ;;
    backup)
        ./scripts/backup.sh
        ;;
    cleanup)
        cleanup_data
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
