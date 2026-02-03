#!/bin/bash
# PM2 Log Backup Script
# This script backs up PM2 logs to a backup directory and restarts PM2 processes

# Set variables
PM2_LOGS_DIR="/root/.pm2/logs"
BACKUP_DIR="/root/.pm2backup/logs"
LAST_RUN_FILE="/root/.pm2backup/last_run"
LOG_FILE="/root/.pm2backup/backup.log"
THREE_DAYS_IN_SECONDS=$((3 * 24 * 60 * 60))  # 3 days in seconds

# Create backup directory and log file if they don't exist
mkdir -p "$(dirname "$LAST_RUN_FILE")"
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$message"
    echo "$message" >> "$LOG_FILE"
}

# Error logging function
log_error() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1"
    echo "$message" >&2
    echo "$message" >> "$LOG_FILE"
}

log "=========================================="
log "PM2 Log Backup Script Started"
log "=========================================="

# Check if 3 days have passed since last run
log "Checking if 3 days have passed since last run..."
if [ -f "$LAST_RUN_FILE" ]; then
    LAST_RUN=$(cat "$LAST_RUN_FILE")
    CURRENT_TIME=$(date +%s)
    TIME_DIFF=$((CURRENT_TIME - LAST_RUN))
    DAYS_SINCE_LAST_RUN=$(echo "scale=2; $TIME_DIFF / 86400" | bc)
    
    log "Last backup was performed at: $(date -d @$LAST_RUN '+%Y-%m-%d %H:%M:%S')"
    log "Time since last backup: $DAYS_SINCE_LAST_RUN days"
    
    if [ $TIME_DIFF -lt $THREE_DAYS_IN_SECONDS ]; then
        log "Skipping backup - need 3 days interval (only $DAYS_SINCE_LAST_RUN days have passed)"
        log "Next backup scheduled after: $(date -d @$((LAST_RUN + THREE_DAYS_IN_SECONDS)) '+%Y-%m-%d %H:%M:%S')"
        exit 0
    fi
else
    log "No previous backup found. This is the first run."
fi

log "Proceeding with backup..."

# Step 1: Delete old backup folder contents if exists
log "Step 1: Cleaning up old backup..."
if [ -d "$BACKUP_DIR" ]; then
    log "Removing contents of $BACKUP_DIR"
    if rm -rf "$BACKUP_DIR"/* 2>> "$LOG_FILE"; then
        log "Old backup contents removed successfully"
    else
        log_error "Failed to remove old backup contents"
    fi
else
    log "Backup directory does not exist, creating it..."
    if mkdir -p "$BACKUP_DIR" 2>> "$LOG_FILE"; then
        log "Backup directory created: $BACKUP_DIR"
    else
        log_error "Failed to create backup directory"
        exit 1
    fi
fi

# Step 2: Move logs to backup folder
log "Step 2: Moving logs to backup folder..."
if [ -d "$PM2_LOGS_DIR" ]; then
    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"
    
    # Copy all log files to backup
    if [ "$(ls -A "$PM2_LOGS_DIR" 2>/dev/null)" ]; then
        # Count files before backup
        FILE_COUNT=$(find "$PM2_LOGS_DIR" -mindepth 1 -maxdepth 1 | wc -l)
        log "Found $FILE_COUNT file(s) to backup"
        
        # Use find for more reliable copying
        if find "$PM2_LOGS_DIR" -mindepth 1 -maxdepth 1 -exec cp -r {} "$BACKUP_DIR"/ \; 2>> "$LOG_FILE"; then
            log "Logs successfully copied to $BACKUP_DIR"
            
            # Clear the original logs after copying
            if find "$PM2_LOGS_DIR" -mindepth 1 -delete 2>> "$LOG_FILE"; then
                log "Original logs cleared from $PM2_LOGS_DIR"
            else
                log_error "Failed to clear original logs"
            fi
        else
            log_error "Failed to copy logs to backup directory"
            exit 1
        fi
    else
        log "No logs found in $PM2_LOGS_DIR - nothing to backup"
    fi
else
    log_error "PM2 logs directory does not exist: $PM2_LOGS_DIR"
    exit 1
fi

# Step 3: Restart all PM2 processes
log "Step 3: Restarting all PM2 processes..."
if command -v pm2 &> /dev/null; then
    log "PM2 command found, executing restart..."
    
    # Capture PM2 output for logging
    PM2_OUTPUT=$(pm2 restart all 2>&1)
    PM2_EXIT_CODE=$?
    
    # Log the PM2 output
    echo "$PM2_OUTPUT" >> "$LOG_FILE"
    
    if [ $PM2_EXIT_CODE -eq 0 ]; then
        log "PM2 processes restarted successfully"
        
        # Log PM2 status
        log "Current PM2 process status:"
        pm2 list 2>&1 | tee -a "$LOG_FILE"
    else
        log_error "PM2 restart failed with exit code: $PM2_EXIT_CODE"
        log_error "PM2 output: $PM2_OUTPUT"
        
        # Try to get PM2 status even on failure
        log "Attempting to get PM2 status..."
        pm2 list 2>&1 | tee -a "$LOG_FILE"
        
        # Don't exit on PM2 failure, but log it
        log "Warning: Continuing despite PM2 restart failure"
    fi
else
    log_error "pm2 command not found in PATH. Please ensure PM2 is installed and accessible."
    log "PATH: $PATH"
fi

log "Backup completed at $(date '+%Y-%m-%d %H:%M:%S')"
log "=========================================="

# Save the current timestamp for next run check
date +%s > "$LAST_RUN_FILE"
log "Last run timestamp saved to $LAST_RUN_FILE"
log "Log file location: $LOG_FILE"
