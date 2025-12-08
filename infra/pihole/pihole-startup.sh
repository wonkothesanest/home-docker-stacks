#!/bin/bash
set -e

# Custom Pi-hole startup script
# Creates dnsmasq config for homelab.local before starting Pi-hole

echo "[Custom Startup] Creating homelab.local DNS configuration..."

# Create dnsmasq.d directory if it doesn't exist
mkdir -p /etc/dnsmasq.d

# Create custom DNS config for *.homelab.local -> SERVER_IP
SERVER_IP="${SERVER_IP:-10.0.0.192}"
echo "address=/homelab.local/${SERVER_IP}" > /etc/dnsmasq.d/02-homelab-local.conf

echo "[Custom Startup] homelab.local -> ${SERVER_IP}"
echo "[Custom Startup] Config file created: /etc/dnsmasq.d/02-homelab-local.conf"
cat /etc/dnsmasq.d/02-homelab-local.conf

# Execute the original Pi-hole entrypoint
echo "[Custom Startup] Starting Pi-hole..."
exec /usr/bin/start.sh
