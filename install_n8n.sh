#!/bin/bash

#===============================================================================
# n8n Installation Script for Ubuntu 22.04 (Linode)
#===============================================================================
# Description: Automated installation script for n8n workflow automation tool
# Author: Abhijeet Verma
# Date: July 2025
# OS: Ubuntu 22.04 LTS
# Platform: Linode VPS
#
# This script will:
# 1. Update system packages
# 2. Install Node.js (via NodeSource repository)
# 3. Install n8n globally via npm
# 4. Create a dedicated n8n user
# 5. Set up n8n as a systemd service
# 6. Configure basic firewall rules
# 7. Provide SSL certificate setup guidance
#
# Prerequisites:
# - Ubuntu 22.04 LTS server
# - Root or sudo access
# - Internet connectivity
# - At least 1GB RAM recommended
#
# Usage:
#   chmod +x install_n8n.sh
#   sudo ./install_n8n.sh
#
# Post-installation:
#   Access n8n at http://your-server-ip:5678
#   Default credentials will be set during first run
#===============================================================================

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
N8N_USER="n8n"
N8N_HOME="/home/${N8N_USER}"
N8N_PORT="5678"
NODE_VERSION="18"  # LTS version recommended for n8n

#===============================================================================
# Helper Functions
#===============================================================================

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root or with sudo"
        exit 1
    fi
}

# Check Ubuntu version
check_ubuntu_version() {
    if [[ ! -f /etc/os-release ]]; then
        print_error "Cannot determine OS version"
        exit 1
    fi
    
    source /etc/os-release
    if [[ "$ID" != "ubuntu" ]] || [[ "$VERSION_ID" != "22.04" ]]; then
        print_warning "This script is designed for Ubuntu 22.04. Current OS: $ID $VERSION_ID"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

#===============================================================================
# Installation Functions
#===============================================================================

# Update system packages
update_system() {
    print_status "Updating system packages..."
    apt-get update -y
    apt-get upgrade -y
    apt-get install -y curl wget gnupg2 software-properties-common apt-transport-https ca-certificates
    print_success "System packages updated"
}

# Install Node.js from NodeSource repository
install_nodejs() {
    print_status "Installing Node.js ${NODE_VERSION}..."
    
    # Remove any existing Node.js installations
    if command_exists node; then
        print_warning "Existing Node.js installation found. Removing..."
        apt-get remove -y nodejs npm
    fi
    
    # Add NodeSource repository
    curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
    
    # Install Node.js
    apt-get install -y nodejs
    
    # Verify installation
    node_version=$(node --version)
    npm_version=$(npm --version)
    
    print_success "Node.js ${node_version} and npm ${npm_version} installed"
}

# Create n8n user
create_n8n_user() {
    print_status "Creating n8n user..."
    
    if id "$N8N_USER" &>/dev/null; then
        print_warning "User $N8N_USER already exists"
    else
        useradd --system --create-home --shell /bin/bash "$N8N_USER"
        print_success "User $N8N_USER created"
    fi
}

# Install n8n
install_n8n() {
    print_status "Installing n8n..."
    
    # Install n8n globally
    npm install -g n8n
    
    # Verify installation
    n8n_version=$(n8n --version)
    print_success "n8n ${n8n_version} installed"
    
    # Create n8n configuration directory
    mkdir -p "${N8N_HOME}/.n8n"
    chown -R "${N8N_USER}:${N8N_USER}" "${N8N_HOME}/.n8n"
}

# Create systemd service
create_systemd_service() {
    print_status "Creating systemd service..."
    
    cat > /etc/systemd/system/n8n.service << EOF
[Unit]
Description=n8n - Workflow Automation Tool
After=network.target

[Service]
Type=simple
User=${N8N_USER}
ExecStart=/usr/bin/n8n start
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=N8N_BASIC_AUTH_ACTIVE=true
Environment=N8N_BASIC_AUTH_USER=admin
Environment=N8N_BASIC_AUTH_PASSWORD=changeme123
Environment=N8N_HOST=0.0.0.0
Environment=N8N_PORT=${N8N_PORT}
Environment=N8N_PROTOCOL=http
Environment=WEBHOOK_URL=http://localhost:${N8N_PORT}/
WorkingDirectory=${N8N_HOME}

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=${N8N_HOME}
ProtectHome=true
ProtectControlGroups=true
ProtectKernelModules=true
ProtectKernelTunables=true
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6
RestrictRealtime=true
RestrictSUIDSGID=true
MemoryDenyWriteExecute=true
SystemCallFilter=@system-service
SystemCallErrorNumber=EPERM

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd and enable service
    systemctl daemon-reload
    systemctl enable n8n
    
    print_success "Systemd service created and enabled"
}

# Configure firewall
configure_firewall() {
    print_status "Configuring firewall..."
    
    if command_exists ufw; then
        # Enable UFW if not already enabled
        ufw --force enable
        
        # Allow SSH (important for Linode access)
        ufw allow ssh
        
        # Allow n8n port
        ufw allow ${N8N_PORT}/tcp
        
        # Show status
        ufw status
        print_success "Firewall configured"
    else
        print_warning "UFW not installed. Please configure firewall manually."
    fi
}

# Start n8n service
start_n8n() {
    print_status "Starting n8n service..."
    
    systemctl start n8n
    
    # Wait a moment for service to start
    sleep 5
    
    # Check service status
    if systemctl is-active --quiet n8n; then
        print_success "n8n service started successfully"
    else
        print_error "Failed to start n8n service"
        systemctl status n8n
        exit 1
    fi
}

# Display final information
display_final_info() {
    local server_ip
    server_ip=$(curl -s ifconfig.me || echo "YOUR_SERVER_IP")
    
    echo
    echo "==============================================================================="
    print_success "n8n Installation Complete!"
    echo "==============================================================================="
    echo
    echo "Access Information:"
    echo "  URL: http://${server_ip}:${N8N_PORT}"
    echo "  Default Username: admin"
    echo "  Default Password: changeme123"
    echo
    echo "Service Management Commands:"
    echo "  Start service:           sudo systemctl start n8n"
    echo "  Stop service:            sudo systemctl stop n8n"
    echo "  Restart service:         sudo systemctl restart n8n"
    echo "  Check service status:    sudo systemctl status n8n"
    echo "  Enable auto-start:       sudo systemctl enable n8n"
    echo "  Disable auto-start:      sudo systemctl disable n8n"
    echo "  Reload service config:   sudo systemctl daemon-reload"
    echo "  View real-time logs:     sudo journalctl -u n8n -f"
    echo "  View recent logs:        sudo journalctl -u n8n -n 50"
    echo "  View logs since boot:    sudo journalctl -u n8n -b"
    echo
    echo "Configuration:"
    echo "  Service file: /etc/systemd/system/n8n.service"
    echo "  Data directory: ${N8N_HOME}/.n8n"
    echo "  User: ${N8N_USER}"
    echo
    echo "Security Recommendations:"
    echo "  1. Change the default password immediately"
    echo "  2. Set up SSL/TLS certificate (Let's Encrypt recommended)"
    echo "  3. Configure a reverse proxy (Nginx/Apache)"
    echo "  4. Set up regular backups of ${N8N_HOME}/.n8n"
    echo "  5. Update n8n regularly: npm update -g n8n"
    echo
    echo "SSL Setup (Optional):"
    echo "  sudo apt install certbot"
    echo "  sudo certbot certonly --standalone -d your-domain.com"
    echo "  Update N8N_PROTOCOL=https in /etc/systemd/system/n8n.service"
    echo
    echo "For support and documentation:"
    echo "  https://docs.n8n.io"
    echo "  https://community.n8n.io"
    echo "==============================================================================="
}

#===============================================================================
# Main Installation Process
#===============================================================================

main() {
    echo "==============================================================================="
    echo "n8n Installation Script for Ubuntu 22.04 (Linode)"
    echo "==============================================================================="
    
    # Pre-installation checks
    check_root
    check_ubuntu_version
    
    # Confirm installation
    echo
    print_warning "This script will install n8n with the following configuration:"
    echo "  - Node.js ${NODE_VERSION} (LTS)"
    echo "  - n8n (latest version)"
    echo "  - Systemd service"
    echo "  - Basic firewall rules"
    echo "  - User: ${N8N_USER}"
    echo "  - Port: ${N8N_PORT}"
    echo
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Installation cancelled"
        exit 0
    fi
    
    # Installation steps
    update_system
    install_nodejs
    create_n8n_user
    install_n8n
    create_systemd_service
    configure_firewall
    start_n8n
    display_final_info
    
    print_success "Installation completed successfully!"
}

# Run main function
main "$@"
