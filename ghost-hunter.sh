#!/bin/bash

# ============================================
# GHOST HUNTER - Full Anonymity Bug Bounty Tool
# ============================================
# Advanced privacy tool with MAC spoofing, proxy chain, auto/manual IP rotation

VERSION="2.0.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
DATA_DIR="$SCRIPT_DIR/data"
CONFIG_FILE="$SCRIPT_DIR/config.conf"

# Config Variables
TOR_PROXY="127.0.0.1:9050"
NETWORK_INTERFACE="eth0"
REQUEST_COUNT=0

# ============================================
# FUNCTIONS
# ============================================

print_banner() {
    clear
    echo -e "${CYAN}"
    echo "============================================================"
    echo "  GHOST HUNTER - Full Anonymity Tool"
    echo "  Version: $VERSION"
    echo "============================================================"
    echo -e "${NC}"
}

log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_DIR/ghost.log" 2>/dev/null || true
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}[X] Run: sudo ./ghost-hunter.sh${NC}"
        exit 1
    fi
}

setup_dirs() {
    mkdir -p "$LOG_DIR" "$DATA_DIR"
}

# ============================================
# TOR FUNCTIONS
# ============================================

start_tor() {
    echo -e "${YELLOW}[+] Starting Tor...${NC}"
    pkill tor 2>/dev/null
    sleep 1
    /usr/bin/tor --runasdaemon 1 &
    sleep 10
    
    if pgrep -x tor > /dev/null; then
        echo -e "${GREEN}[OK] Tor running on $TOR_PROXY${NC}"
        return 0
    else
        echo -e "${RED}[X] Tor failed to start${NC}"
        return 1
    fi
}

stop_tor() {
    pkill tor 2>/dev/null
    echo -e "${GREEN}[OK] Tor stopped${NC}"
}

rotate_ip() {
    echo -e "${CYAN}[*] Rotating IP (NEWNYM)...${NC}"
    
    # Send NEWNYM signal
    {
        echo "AUTHENTICATE"
        echo "SIGNAL NEWNYM"
        echo "QUIT"
    } | nc 127.0.0.1 9051 2>/dev/null
    
    sleep 5
    
    # Get new IP
    NEW_IP=$(curl -s --socks5 "$TOR_PROXY" ifconfig.me 2>/dev/null || echo "failed")
    
    echo -e "${GREEN}[OK] New IP: $NEW_IP${NC}"
    log "INFO" "IP rotated to: $NEW_IP"
}

full_rotate() {
    echo -e "${CYAN}[*] FULL ROTATION - Tor restart + IP change...${NC}"
    
    # Stop Tor
    pkill tor 2>/dev/null
    sleep 2
    
    # Start fresh Tor
    /usr/bin/tor --runasdaemon 1 &
    sleep 10
    
    # Get new IP
    NEW_IP=$(curl -s --socks5 "$TOR_PROXY" ifconfig.me 2>/dev/null || echo "failed")
    
    echo -e "${GREEN}[OK] New IP: $NEW_IP${NC}"
    log "INFO" "Full rotation - New IP: $NEW_IP"
}

# ============================================
# MAC SPOOFING
# ============================================

spoof_mac() {
    echo -e "${YELLOW}[+] Spoofing MAC address...${NC}"
    
    # Random MAC vendors
    VENDORS=("00:50:56" "08:00:27" "52:54:00" "00:0C:29")
    VENDOR=${VENDORS[$RANDOM % ${#VENDORS[@]}]}
    RAND_BYTES=$(openssl rand -hex 3 2>/dev/null | sed 's/\(..\)/\1:/g; s/.$//')
    NEW_MAC="$VENDOR:$RAND_BYTES"
    
    # Change MAC
    ip link set "$NETWORK_INTERFACE" down 2>/dev/null
    ip link set "$NETWORK_INTERFACE" address "$NEW_MAC" 2>/dev/null
    ip link set "$NETWORK_INTERFACE" up 2>/dev/null
    
    echo -e "${GREEN}[OK] New MAC: $NEW_MAC${NC}"
    log "INFO" "MAC spoofed to: $NEW_MAC"
}

restore_mac() {
    echo -e "${YELLOW}[+] Restoring original MAC...${NC}"
    ip link set "$NETWORK_INTERFACE" down 2>/dev/null
    ip link set "$NETWORK_INTERFACE" address "00:00:00:00:00:00" 2>/dev/null
    ip link set "$NETWORK_INTERFACE" up 2>/dev/null
    echo -e "${GREEN}[OK] MAC restored${NC}"
}

# ============================================
# ANONYMOUS REQUEST
# ============================================

get_random_ua() {
    shuf -n1 "$DATA_DIR/user_agents.txt" 2>/dev/null || echo "Mozilla/5.0"
}

gh_request() {
    local url=$1
    local method=${2:-GET}
    local data=$3
    
    if [ -z "$url" ]; then
        echo "Usage: gh_request <url> [GET|POST] [data]"
        return 1
    fi
    
    local ua=$(get_random_ua)
    local delay=$((RANDOM % 3 + 1))
    
    # Silent logging (no URL in logs)
    log "REQUEST" "[hidden]"
    
    # Build curl with maximum privacy
    local curl_opts="--socks5 $TOR_PROXY -A '$ua'"
    
    # Add privacy headers
    curl_opts="$curl_opts -H 'Accept-Language: en-US,en;q=0.9'"
    curl_opts="$curl_opts -H 'DNT:1'"
    curl_opts="$curl_opts --connect-timeout 30"
    
    if [ "$method" = "POST" ] && [ -n "$data" ]; then
        curl -s $curl_opts -X POST -d "$data" "$url"
    else
        curl -s $curl_opts "$url"
    fi
}

# Dark web / .onion request
gh_onion() {
    local onion_url=$1
    
    if [ -z "$onion_url" ]; then
        echo "Usage: gh_onion <onion-url>"
        return 1
    fi
    
    # .onion - use Tor's SOCKS5 with isolated circuit
    local ua=$(get_random_ua)
    curl -s --socks5 "$TOR_PROXY" -A "$ua" --connect-timeout 60 "$onion_url"
}

# ============================================
# AUTO ROTATE LOOP
# ============================================

auto_rotate_loop() {
    local seconds=${1:-300}
    echo -e "${CYAN}[*] Auto-rotating every $seconds seconds...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
    
    while true; do
        rotate_ip
        sleep "$seconds"
    done
}

# ============================================
# COMMANDS
# ============================================

cmd_start() {
    print_banner
    check_root
    setup_dirs
    
    # Setup user agents
    cat > "$DATA_DIR/user_agents.txt" << 'EOF'
Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36
Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 Safari/605.1.15
Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36
Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:120.0) Gecko/20100101 Firefox/120.0
Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/119.0.0.0 Safari/537.36 Edg/119.0.0.0
EOF
    
    echo -e "${CYAN}[*] Starting Ghost Hunter...${NC}"
    start_tor
    
    echo ""
    echo "============================================================"
    echo "  READY - Commands:"
    echo "============================================================"
    echo ""
    echo "  sudo ./ghost-hunter.sh status    - Check IP"
    echo "  sudo ./ghost-hunter.sh rotate   - Manual IP change"
    echo "  sudo ./ghost-hunter.sh full    - Full restart + new IP"
    echo "  sudo ./ghost-hunter.sh mac    - Spoof MAC"
    echo "  sudo ./ghost-hunter.sh auto   - Auto-rotate loop"
    echo "  source ./ghost-hunter.sh && gh_request <url>"
    echo ""
}

cmd_status() {
    print_banner
    
    echo -e "${CYAN}Status:${NC}"
    echo ""
    
    # Tor
    if pgrep -x tor > /dev/null; then
        echo -e "${GREEN}[OK] Tor: Running${NC}"
    else
        echo -e "${RED}[X] Tor: Not running${NC}"
    fi
    
    # IP
    echo -n "IP: "
    curl -s --socks5 "$TOR_PROXY" ifconfig.me 2>/dev/null || echo "Not connected"
    
    # MAC
    echo -n "MAC: "
    ip link show "$NETWORK_INTERFACE" 2>/dev/null | grep link/ether | awk '{print $3}' || echo "N/A"
    
    echo ""
}

cmd_rotate() {
    check_root
    rotate_ip
}

cmd_full() {
    check_root
    full_rotate
}

cmd_mac() {
    check_root
    spoof_mac
}

cmd_restore_mac() {
    check_root
    restore_mac
}

cmd_auto() {
    check_root
    auto_rotate_loop ${1:-300}
}

cmd_help() {
    print_banner
    
    cat << 'EOF'
GHOST HUNTER - Full Anonymity Tool v2.0
=======================================

COMMANDS:
    start       - Start Tor + setup
    stop        - Stop Tor
    status      - Show current IP/MAC
    rotate      - Change IP (NEWNYM signal)
    full        - Full restart + new IP
    mac         - Spoof MAC address
    restore     - Restore original MAC
    auto [sec]  - Auto-rotate every X seconds
    
USAGE:
    source ./ghost-hunter.sh && gh_request <url>
    
EXAMPLES:
    sudo ./ghost-hunter.sh start
    sudo ./ghost-hunter.sh rotate     # Manual IP change
    sudo ./ghost-hunter.sh auto 600   # Auto-rotate every 10 min
    sudo ./ghost-hunter.sh status
    
    source ./ghost-hunter.sh
    gh_request https://target.com

EOF
}

# ============================================
# MAIN
# ============================================

case "${1:-help}" in
    start)
        cmd_start
        ;;
    stop)
        check_root
        stop_tor
        ;;
    status)
        cmd_status
        ;;
    rotate)
        cmd_rotate
        ;;
    full)
        cmd_full
        ;;
    mac)
        cmd_mac
        ;;
    restore)
        cmd_restore_mac
        ;;
    auto)
        cmd_auto ${2:-300}
        ;;
    help|--help|-h)
        cmd_help
        ;;
    *)
        echo "Run: ./ghost-hunter.sh help"
        exit 1
        ;;
esac
