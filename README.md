# n8n-ubuntu-linode-file

# n8n-ubuntu22.04-install

I have create a comprehensive shell script to install n8n on Ubuntu 22.04 for Linode. This script will include detailed documentation and handle all the necessary dependencies.I've created a comprehensive shell script for installing n8n on Ubuntu 22.04 (Linode). Here's what the script includes:

## Key Features:

**🔧 Complete Installation Process:**
- System package updates
- Node.js 18 (LTS) installation via NodeSource
- n8n installation via npm
- Dedicated system user creation
- Systemd service configuration

**🛡️ Security Features:**
- Basic authentication enabled by default
- Firewall configuration (UFW)
- Systemd security hardening
- Non-root user execution

**📋 Detailed Documentation:**
- Comprehensive comments explaining each step
- Color-coded output for easy reading
- Error handling and validation
- Post-installation instructions

## Usage:

1. **Save the script:**
   ```bash
   curl -o install_n8n.sh [https://github.com/MaqAnquor/n8n-ubuntu-linode-file/blob/34c3083f3e7ae3c5e05e9fe2c427514b606650e8/install_n8n.sh](https://raw.githubusercontent.com/MaqAnquor/n8n-ubuntu-linode-file/refs/heads/main/install_n8n.sh)
   # or copy-paste the content into a file
   ```

2. **Make it executable:**
   ```bash
   chmod +x install_n8n.sh
   ```

3. **Run the installation:**
   ```bash
   sudo ./install_n8n.sh
   ```

## Post-Installation:

- **Access n8n:** `http://your-server-ip:5678`
- **Default credentials:** admin / changeme123
- **Service management:** Standard systemctl commands
- **Logs:** `sudo journalctl -u n8n -f`

## Important Security Notes:

1. **Change the default password immediately** after first login
2. Consider setting up SSL/TLS with Let's Encrypt
3. Configure a reverse proxy (Nginx/Apache) for production use
4. Set up regular backups of the n8n data directory

The script includes comprehensive error handling and will guide you through the entire installation process with colored output to make it easy to follow.

I've updated the script to include comprehensive systemctl command definitions. Here's what each command does:

## Service Management Commands:

### Basic Service Control:
- **`sudo systemctl start n8n`** - Starts the n8n service immediately
- **`sudo systemctl stop n8n`** - Stops the n8n service immediately  
- **`sudo systemctl restart n8n`** - Stops and then starts the service (useful after config changes)

### Service Status & Information:
- **`sudo systemctl status n8n`** - Shows current service status, recent logs, and basic info
- **`sudo systemctl is-active n8n`** - Returns "active" or "inactive" status
- **`sudo systemctl is-enabled n8n`** - Returns "enabled" or "disabled" auto-start status

### Auto-Start Configuration:
- **`sudo systemctl enable n8n`** - Enables service to start automatically at boot
- **`sudo systemctl disable n8n`** - Disables automatic startup at boot

### Configuration Management:
- **`sudo systemctl daemon-reload`** - Reloads systemd configuration after editing service files
- **`sudo systemctl edit n8n`** - Opens editor to create service overrides

### Log Management:
- **`sudo journalctl -u n8n -f`** - Shows real-time logs (follow mode)
- **`sudo journalctl -u n8n -n 50`** - Shows last 50 log entries
- **`sudo journalctl -u n8n -b`** - Shows logs since last boot
- **`sudo journalctl -u n8n --since "1 hour ago"`** - Shows logs from last hour

### Additional Useful Commands:
- **`sudo systemctl list-units | grep n8n`** - Lists all n8n-related services
- **`sudo systemctl show n8n`** - Shows detailed service properties
- **`sudo systemctl cat n8n`** - Displays the complete service file content

The script now provides a complete reference for managing the n8n service after installation!
