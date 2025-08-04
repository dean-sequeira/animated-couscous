import streamlit as st
import psutil
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from datetime import datetime, timedelta
import time
import subprocess
import json
import socket
import struct
from collections import defaultdict, deque
import threading
import os

# Page config
st.set_page_config(
    page_title="Network Traffic Monitor",
    page_icon="📊",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Initialize session state
if 'network_data' not in st.session_state:
    st.session_state.network_data = deque(maxlen=100)
if 'device_data' not in st.session_state:
    st.session_state.device_data = defaultdict(lambda: {'bytes_sent': 0, 'bytes_recv': 0, 'last_seen': datetime.now()})

class NetworkMonitor:
    def __init__(self):
        self.interface = self.get_default_interface()

    def get_default_interface(self):
        """Get the default network interface"""
        try:
            # Get default route interface
            result = subprocess.run(['ip', 'route', 'show', 'default'],
                                  capture_output=True, text=True)
            if result.stdout:
                return result.stdout.split()[4]  # Extract interface name
        except:
            pass
        return 'eth0'  # fallback

    def get_network_stats(self):
        """Get current network interface statistics"""
        stats = psutil.net_io_counters(pernic=True)
        if self.interface in stats:
            return stats[self.interface]
        return None

    def get_network_connections(self):
        """Get active network connections"""
        connections = []
        try:
            for conn in psutil.net_connections(kind='inet'):
                if conn.status == 'ESTABLISHED' and conn.raddr:
                    connections.append({
                        'local_ip': conn.laddr.ip if conn.laddr else 'N/A',
                        'local_port': conn.laddr.port if conn.laddr else 0,
                        'remote_ip': conn.raddr.ip if conn.raddr else 'N/A',
                        'remote_port': conn.raddr.port if conn.raddr else 0,
                        'pid': conn.pid,
                        'process': self.get_process_name(conn.pid)
                    })
        except:
            pass
        return connections

    def get_process_name(self, pid):
        """Get process name from PID"""
        try:
            if pid:
                return psutil.Process(pid).name()
        except:
            pass
        return 'Unknown'

    def scan_local_devices(self):
        """Scan for devices on local network"""
        devices = []
        try:
            # Get local network range
            result = subprocess.run(['ip', 'route', 'show'],
                                  capture_output=True, text=True)
            network_range = "192.168.3.0/24"  # Default from your config

            # Use arp table for faster device discovery
            arp_result = subprocess.run(['arp', '-a'],
                                      capture_output=True, text=True)

            for line in arp_result.stdout.split('\n'):
                if '(' in line and ')' in line:
                    parts = line.split()
                    if len(parts) >= 4:
                        hostname = parts[0] if parts[0] != '?' else 'Unknown'
                        ip = parts[1].strip('()')
                        mac = parts[3] if len(parts) > 3 else 'Unknown'

                        devices.append({
                            'hostname': hostname,
                            'ip': ip,
                            'mac': mac,
                            'status': 'Active'
                        })
        except:
            pass
        return devices

def main():
    st.title("🌐 Network Traffic Monitor")
    st.sidebar.title("Settings")

    # Initialize monitor
    monitor = NetworkMonitor()

    # Sidebar controls
    auto_refresh = st.sidebar.checkbox("Auto Refresh", value=True)
    refresh_interval = st.sidebar.slider("Refresh Interval (seconds)", 1, 30, 5)
    interface_override = st.sidebar.text_input("Network Interface",
                                             value=monitor.interface,
                                             help="Override default network interface")

    if interface_override:
        monitor.interface = interface_override

    # Auto refresh
    if auto_refresh:
        time.sleep(refresh_interval)
        st.rerun()

    # Main dashboard
    col1, col2, col3, col4 = st.columns(4)

    # Get current network stats
    stats = monitor.get_network_stats()

    if stats:
        with col1:
            st.metric("Bytes Sent", f"{stats.bytes_sent / (1024**2):.1f} MB")
        with col2:
            st.metric("Bytes Received", f"{stats.bytes_recv / (1024**2):.1f} MB")
        with col3:
            st.metric("Packets Sent", f"{stats.packets_sent:,}")
        with col4:
            st.metric("Packets Received", f"{stats.packets_recv:,}")

        # Store data for historical tracking
        current_time = datetime.now()
        st.session_state.network_data.append({
            'time': current_time,
            'bytes_sent': stats.bytes_sent,
            'bytes_recv': stats.bytes_recv,
            'packets_sent': stats.packets_sent,
            'packets_recv': stats.packets_recv
        })

    # Tabs for different views
    tab1, tab2, tab3, tab4 = st.tabs(["📈 Traffic Graph", "🖥️ Active Connections",
                                     "📱 Local Devices", "⚙️ Interface Info"])

    with tab1:
        st.subheader("Network Traffic Over Time")

        if len(st.session_state.network_data) > 1:
            df = pd.DataFrame(list(st.session_state.network_data))

            # Calculate rates (bytes per second)
            df['send_rate'] = df['bytes_sent'].diff() / refresh_interval
            df['recv_rate'] = df['bytes_recv'].diff() / refresh_interval

            # Convert to Mbps
            df['send_mbps'] = df['send_rate'] / (1024**2) * 8
            df['recv_mbps'] = df['recv_rate'] / (1024**2) * 8

            fig = go.Figure()
            fig.add_trace(go.Scatter(x=df['time'], y=df['send_mbps'],
                                   name='Upload (Mbps)', line=dict(color='blue')))
            fig.add_trace(go.Scatter(x=df['time'], y=df['recv_mbps'],
                                   name='Download (Mbps)', line=dict(color='red')))

            fig.update_layout(title="Network Speed (Mbps)",
                            xaxis_title="Time", yaxis_title="Speed (Mbps)")
            st.plotly_chart(fig, use_container_width=True)
        else:
            st.info("Collecting data... Please wait for more data points.")

    with tab2:
        st.subheader("Active Network Connections")

        connections = monitor.get_network_connections()
        if connections:
            df_conn = pd.DataFrame(connections)
            st.dataframe(df_conn, use_container_width=True)
        else:
            st.info("No active connections found.")

    with tab3:
        st.subheader("Local Network Devices")

        if st.button("Scan Network"):
            with st.spinner("Scanning local network..."):
                devices = monitor.scan_local_devices()

                if devices:
                    df_devices = pd.DataFrame(devices)
                    st.dataframe(df_devices, use_container_width=True)

                    # Device count by status
                    if len(devices) > 0:
                        status_counts = pd.DataFrame(devices)['status'].value_counts()
                        fig_pie = px.pie(values=status_counts.values,
                                       names=status_counts.index,
                                       title="Device Status Distribution")
                        st.plotly_chart(fig_pie)
                else:
                    st.warning("No devices found on local network.")

    with tab4:
        st.subheader("Network Interface Information")

        # Interface details
        all_stats = psutil.net_io_counters(pernic=True)

        if all_stats:
            interface_data = []
            for interface, stat in all_stats.items():
                interface_data.append({
                    'Interface': interface,
                    'Bytes Sent': f"{stat.bytes_sent / (1024**2):.1f} MB",
                    'Bytes Received': f"{stat.bytes_recv / (1024**2):.1f} MB",
                    'Packets Sent': f"{stat.packets_sent:,}",
                    'Packets Received': f"{stat.packets_recv:,}",
                    'Errors In': stat.errin,
                    'Errors Out': stat.errout,
                    'Drops In': stat.dropin,
                    'Drops Out': stat.dropout
                })

            df_interfaces = pd.DataFrame(interface_data)
            st.dataframe(df_interfaces, use_container_width=True)

        # Network addresses
        st.subheader("Network Addresses")
        addresses = psutil.net_if_addrs()

        for interface, addrs in addresses.items():
            if interface == monitor.interface:
                st.write(f"**{interface}** (monitoring)")
                for addr in addrs:
                    if addr.family == socket.AF_INET:
                        st.write(f"  • IPv4: {addr.address}")
                    elif addr.family == socket.AF_INET6:
                        st.write(f"  • IPv6: {addr.address}")

    # Status bar
    st.sidebar.markdown("---")
    st.sidebar.subheader("System Status")

    if stats:
        st.sidebar.success(f"✅ Monitoring {monitor.interface}")
        st.sidebar.write(f"**Data Points:** {len(st.session_state.network_data)}")
        st.sidebar.write(f"**Last Update:** {datetime.now().strftime('%H:%M:%S')}")
    else:
        st.sidebar.error(f"❌ Interface {monitor.interface} not found")

    # Manual refresh button
    if st.sidebar.button("🔄 Refresh Now"):
        st.rerun()

if __name__ == "__main__":
    main()
