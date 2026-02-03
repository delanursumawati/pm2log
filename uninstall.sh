#!/bin/bash
# Uninstallation script for PM2 Log Backup System

set -e

echo "Uninstalling PM2 Log Backup System..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Stop and disable the timer
echo "Stopping and disabling timer..."
if systemctl is-active --quiet pm2-log-backup.timer; then
    systemctl stop pm2-log-backup.timer
fi
if systemctl is-enabled --quiet pm2-log-backup.timer 2>/dev/null; then
    systemctl disable pm2-log-backup.timer
fi

# Stop and disable the service
echo "Stopping and disabling service..."
if systemctl is-active --quiet pm2-log-backup.service; then
    systemctl stop pm2-log-backup.service
fi
if systemctl is-enabled --quiet pm2-log-backup.service 2>/dev/null; then
    systemctl disable pm2-log-backup.service
fi

# Remove systemd files
echo "Removing systemd files..."
rm -f /etc/systemd/system/pm2-log-backup.service
rm -f /etc/systemd/system/pm2-log-backup.timer

# Reload systemd
echo "Reloading systemd daemon..."
systemctl daemon-reload
systemctl reset-failed 2>/dev/null || true

# Remove backup script
echo "Removing backup script..."
rm -f /usr/local/bin/pm2-log-backup.sh

# Ask about removing backup data
echo ""
echo "Do you want to remove the backup data at /root/.pm2backup/? (y/N)"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "Removing backup data..."
    rm -rf /root/.pm2backup/
    echo "Backup data removed."
else
    echo "Backup data preserved at /root/.pm2backup/"
fi

echo ""
echo "Uninstallation completed successfully!"
echo ""
echo "The PM2 Log Backup System has been completely removed."
echo ""
echo "To run backups manually, you have these options:"
echo "  1. Keep the repository and run: sudo ./pm2-log-backup.sh"
echo "  2. Reinstall the automated system: sudo ./install.sh"
echo "  3. Copy pm2-log-backup.sh to any location and run it with sudo"
echo ""
