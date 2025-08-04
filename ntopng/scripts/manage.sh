#!/bin/bash
# Network Monitor Streamlit App Launcher for Raspberry Pi
# This replaces the problematic ntopng Docker setup

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

start_service() {
    log_info "Starting Network Monitor Streamlit App..."

    # Check if requirements are installed
    if ! python3 -c "import streamlit, psutil, pandas, plotly" 2>/dev/null; then
        log_info "Installing dependencies..."

        # Try different package managers in order of preference
        if command -v pip3 &> /dev/null; then
            pip3 install -r "$PROJECT_DIR/streamlit_apps/requirements_network.txt"
        elif command -v pip &> /dev/null; then
            pip install -r "$PROJECT_DIR/streamlit_apps/requirements_network.txt"
        elif command -v apt &> /dev/null; then
            log_info "Using apt to install Python packages..."
            sudo apt update
            sudo apt install -y python3-pip python3-streamlit python3-psutil python3-pandas python3-plotly
        else
            log_error "No package manager found. Please install pip3 or use apt:"
            log_error "sudo apt update && sudo apt install python3-pip"
            exit 1
        fi
    fi

    # Start the Streamlit app
    cd "$PROJECT_DIR/streamlit_apps"
    log_info "Network Monitor available at: http://$(hostname -I | cut -d' ' -f1):8501"

    # Try different ways to run streamlit
    if command -v streamlit &> /dev/null; then
        streamlit run network_monitor.py --server.port 8501 --server.address 0.0.0.0
    elif python3 -m streamlit --help &> /dev/null; then
        python3 -m streamlit run network_monitor.py --server.port 8501 --server.address 0.0.0.0
    else
        log_error "Streamlit not found. Installing via apt..."
        sudo apt install -y python3-streamlit
        python3 -m streamlit run network_monitor.py --server.port 8501 --server.address 0.0.0.0
    fi
}

stop_service() {
    log_info "Stopping Network Monitor..."
    pkill -f "streamlit run network_monitor.py" || log_warn "No running instances found"
}

status_service() {
    if pgrep -f "streamlit run network_monitor.py" > /dev/null; then
        log_info "✅ Network Monitor is running"
        log_info "Access at: http://$(hostname -I | cut -d' ' -f1):8501"
    else
        log_warn "❌ Network Monitor is not running"
    fi
}

show_help() {
    echo "Network Monitor Management Script"
    echo
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  start       Start the Network Monitor web app"
    echo "  stop        Stop the Network Monitor web app"
    echo "  status      Check if the app is running"
    echo "  install     Install Python dependencies"
    echo "  help        Show this help message"
    echo
}

install_deps() {
    log_info "Installing Network Monitor dependencies..."
    pip install -r "$PROJECT_DIR/streamlit_apps/requirements_network.txt"
    log_info "Dependencies installed successfully"
}

# Main command processing
case "${1:-help}" in
    start)
        start_service
        ;;
    stop)
        stop_service
        ;;
    status)
        status_service
        ;;
    install)
        install_deps
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
