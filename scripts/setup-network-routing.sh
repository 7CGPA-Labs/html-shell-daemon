#!/bin/bash
# ==============================================================================
# WebOS Appliance - Dual-Wireless Network policy-based routing tables configuration
# ==============================================================================
# Separates Wi-Fi Direct screen-casting streams from cellular 4G mobile data.
# ==============================================================================

set -euo pipefail

# Configuration parameters
CELLULAR_IF="${1:-wwan0}"      # Mobile data gateway interface, e.g. rmnet0 or wwan0
WIFI_DIRECT_IF="${2:-wlan1}"   # Wi-Fi Direct interface, e.g. p2p-wlan0-0 or wlan1
WIFI_DIRECT_SUBNET="192.168.49.0/24"  # Default Wi-Fi Direct P2P subnet
ROUTING_TABLE_ID="100"
ROUTING_TABLE_NAME="casting"

# Ensure script is running as root
if [ "$EUID" -ne 0 ]; then
    echo "[-] ERROR: This script must be run as root (sudo)." >&2
    exit 1
fi

echo "[*] Configuring dual-wireless network policy routing..."

# 1. Ensure the custom routing table is registered in /etc/iproute2/rt_tables
if ! grep -q "$ROUTING_TABLE_NAME" /etc/iproute2/rt_tables; then
    echo "[*] Registering table '$ROUTING_TABLE_NAME' (ID: $ROUTING_TABLE_ID) in rt_tables..."
    echo "$ROUTING_TABLE_ID $ROUTING_TABLE_NAME" >> /etc/iproute2/rt_tables
else
    echo "[+] Routing table '$ROUTING_TABLE_NAME' is already registered."
fi

# 2. Clear old rules and routes for clean initialization
echo "[*] Cleaning old casting rules..."
ip rule del table "$ROUTING_TABLE_NAME" 2>/dev/null || true
ip route flush table "$ROUTING_TABLE_NAME" 2>/dev/null || true

# 3. Create route table rules for casting subnet
echo "[*] Adding routing policies for local casting subnet ($WIFI_DIRECT_SUBNET)..."
# Route local P2P subnet requests through the Wi-Fi Direct interface inside the casting table
ip route add "$WIFI_DIRECT_SUBNET" dev "$WIFI_DIRECT_IF" src "192.168.49.100" table "$ROUTING_TABLE_NAME" 2>/dev/null || \
ip route add "$WIFI_DIRECT_SUBNET" dev "$WIFI_DIRECT_IF" table "$ROUTING_TABLE_NAME"

# 4. Bind rules linking source IP and interfaces to the casting table
echo "[*] Binding policy rules mapping interfaces to tables..."
# Rule: Any packets originating from or headed to the Wi-Fi Direct interface must use table 'casting'
ip rule add from "$WIFI_DIRECT_SUBNET" table "$ROUTING_TABLE_NAME"
ip rule add to "$WIFI_DIRECT_SUBNET" table "$ROUTING_TABLE_NAME"
ip rule add iif "$WIFI_DIRECT_IF" table "$ROUTING_TABLE_NAME"

# 5. Configure Default Main table rules for Cellular Modem
echo "[*] Setting cellular interface '$CELLULAR_IF' as default outbound WAN gateway..."
# Ensure default outbound internet traffic goes through the mobile gateway (rmnet0/wwan0)
# This keeps default web requests inside container tabs routed to 4G LTE
ip route replace default dev "$CELLULAR_IF" table main

# 6. Enable routing and disable reverse path filtering on dual-homed interfaces
echo "[*] Optimizing kernel sysctl routing parameters..."
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv4.conf.all.rp_filter=2
sysctl -w net.ipv4.conf.default.rp_filter=2
sysctl -w net.ipv4.conf."$WIFI_DIRECT_IF".rp_filter=2
sysctl -w net.ipv4.conf."$CELLULAR_IF".rp_filter=2

echo "[+] Policy Routing configuration complete."
echo "--------------------------------------------------"
echo " Outbound WAN:       $CELLULAR_IF (4G cellular data)"
echo " Casting Subnet:     $WIFI_DIRECT_IF ($WIFI_DIRECT_SUBNET)"
echo " Policy Table Name:  $ROUTING_TABLE_NAME"
echo "--------------------------------------------------"
echo "[*] Active routing rules:"
ip rule show
echo "[*] Active main routes:"
ip route show
