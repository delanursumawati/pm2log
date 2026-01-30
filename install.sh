#!/bin/bash
# Installation script for PM2 Log Backup System

set -e

echo "Installing PM2 Log Backup System..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Copy backup script
echo "Copying backup script to /usr/local/bin/..."
cp "$SCRIPT_DIR/pm2-log-backup.sh" /usr/local/bin/
chmod +x /usr/local/bin/pm2-log-backup.sh

# Copy systemd files
echo "Copying systemd service and timer files..."
cp "$SCRIPT_DIR/pm2-log-backup.service" /etc/systemd/system/
cp "$SCRIPT_DIR/pm2-log-backup.timer" /etc/systemd/system/

# Reload systemd
echo "Reloading systemd daemon..."
systemctl daemon-reload

# Enable and start timer
echo "Enabling and starting the timer..."
systemctl enable pm2-log-backup.timer
systemctl start pm2-log-backup.timer

echo ""
echo "Installation completed successfully!"
echo ""
echo "The backup timer is now active and will run every 3 days."
echo ""
echo "Useful commands:"
echo "  - Check timer status: systemctl status pm2-log-backup.timer"
echo "  - List timers: systemctl list-timers pm2-log-backup.timer"
echo "  - Manual backup: systemctl start pm2-log-backup.service"
echo "  - View logs: journalctl -u pm2-log-backup.service"
echo ""
