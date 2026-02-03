#!/bin/bash
# PM2 Log Backup Script
# This script backs up PM2 logs to a backup directory and restarts PM2 processes

# Set variables
PM2_LOGS_DIR="/root/.pm2/logs"
BACKUP_DIR="/root/.pm2backup/logs"
LAST_RUN_FILE="/root/.pm2backup/last_run"

# Check if 3 days have passed since last run
if [ -f "$LAST_RUN_FILE" ]; then
    LAST_RUN=$(cat "$LAST_RUN_FILE")
    CURRENT_TIME=$(date +%s)
    TIME_DIFF=$((CURRENT_TIME - LAST_RUN))
    THREE_DAYS_IN_SECONDS=259200  # 3 days * 24 hours * 60 minutes * 60 seconds
    
    if [ $TIME_DIFF -lt $THREE_DAYS_IN_SECONDS ]; then
        echo "Last backup was $(($TIME_DIFF / 86400)) days ago. Skipping (need 3 days interval)."
        exit 0
    fi
fi

# Step 1: Delete old backup folder contents if exists
echo "Step 1: Cleaning up old backup..."
if [ -d "$BACKUP_DIR" ]; then
    echo "Removing contents of $BACKUP_DIR"
    rm -rf "$BACKUP_DIR"/*
else
    echo "Backup directory does not exist, creating it..."
    mkdir -p "$BACKUP_DIR"
fi

# Step 2: Move logs to backup folder
echo "Step 2: Moving logs to backup folder..."
if [ -d "$PM2_LOGS_DIR" ]; then
    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"
    
    # Copy all log files to backup
    if [ "$(ls -A "$PM2_LOGS_DIR" 2>/dev/null)" ]; then
        # Use find for more reliable copying
        find "$PM2_LOGS_DIR" -mindepth 1 -maxdepth 1 -exec cp -r {} "$BACKUP_DIR"/ \;
        echo "Logs successfully copied to $BACKUP_DIR"
        
        # Clear the original logs after copying
        find "$PM2_LOGS_DIR" -mindepth 1 -delete
        echo "Original logs cleared"
    else
        echo "No logs found in $PM2_LOGS_DIR"
    fi
else
    echo "PM2 logs directory does not exist: $PM2_LOGS_DIR"
    exit 1
fi

# Step 3: Restart all PM2 processes
echo "Step 3: Restarting all PM2 processes..."
if command -v pm2 &> /dev/null; then
    pm2 restart all
    echo "PM2 processes restarted successfully"
else
    echo "Warning: pm2 command not found. Skipping restart."
fi

echo "Backup completed successfully at $(date)"

# Save the current timestamp for next run check
mkdir -p "$(dirname "$LAST_RUN_FILE")"
date +%s > "$LAST_RUN_FILE"
