# pm2log

Automated PM2 log backup system using systemd. This script automatically backs up PM2 logs every 3 days to prevent log files from growing too large.

## Features

- Automatic backup of `/root/.pm2/logs` to `/root/.pm2backup/logs` every 3 days
- Cleans up old backup before creating new one
- Restarts all PM2 processes after backup
- Runs as a systemd service and timer
- **Detailed logging for debugging** at `/root/.pm2backup/backup.log`
- **Persistent last run tracking** at `/root/.pm2backup/last_run`
- **Enhanced error handling** for PM2 restart operations

## Installation

1. Copy the backup script to a system directory:
```bash
sudo cp pm2-log-backup.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/pm2-log-backup.sh
```

2. Copy the systemd service and timer files:
```bash
sudo cp pm2-log-backup.service /etc/systemd/system/
sudo cp pm2-log-backup.timer /etc/systemd/system/
```

3. Reload systemd to recognize the new service:
```bash
sudo systemctl daemon-reload
```

4. Enable and start the timer:
```bash
sudo systemctl enable pm2-log-backup.timer
sudo systemctl start pm2-log-backup.timer
```

## Usage

### Check timer status
```bash
sudo systemctl status pm2-log-backup.timer
```

### List all timers to see next scheduled run
```bash
sudo systemctl list-timers pm2-log-backup.timer
```

### Manually trigger a backup
```bash
sudo systemctl start pm2-log-backup.service
```

### View backup logs
```bash
sudo journalctl -u pm2-log-backup.service
```

### View detailed backup log file
```bash
sudo cat /root/.pm2backup/backup.log
# Or for continuous monitoring
sudo tail -f /root/.pm2backup/backup.log
```

### Check last run timestamp
```bash
sudo cat /root/.pm2backup/last_run
# To see human-readable format (GNU/Linux)
sudo date -d "@$(cat /root/.pm2backup/last_run)"
# Or on BSD/macOS
sudo date -r "$(cat /root/.pm2backup/last_run)"
```

### Stop the timer
```bash
sudo systemctl stop pm2-log-backup.timer
sudo systemctl disable pm2-log-backup.timer
```

## How It Works

The backup process follows these steps:

1. **Check 3-day interval**: Verifies that at least 3 days (72 hours) have passed since the last backup. If not, the script exits without performing a backup.
2. **Delete old backup**: Removes all files in `/root/.pm2backup/logs` if the directory exists
3. **Move logs to backup**: Copies all log files from `/root/.pm2/logs` to `/root/.pm2backup/logs`, then clears the original logs
4. **Restart PM2 processes**: Executes `pm2 restart all` to restart all PM2-managed processes with proper error handling
5. **Record timestamp**: Saves the current timestamp to track when the backup was performed

The timer is configured to:
- Trigger daily at 00:00 WIB (17:00 UTC)
- The script checks if 3 days have passed since the last backup before executing
- Persist across reboots (if a scheduled backup was missed, it will run on next boot)

### Logging and Debugging

All backup operations are logged to:
- **System journal**: Accessible via `journalctl -u pm2-log-backup.service`
- **Dedicated log file**: `/root/.pm2backup/backup.log` with detailed timestamps and error information
- **Last run file**: `/root/.pm2backup/last_run` contains the Unix timestamp of the last successful backup

Each log entry includes:
- Timestamp of the operation
- Backup status and progress
- PM2 restart status and output
- Any errors encountered during the process
- File counts and operation results

## File Descriptions

- `pm2-log-backup.sh` - The main backup script
- `pm2-log-backup.service` - Systemd service definition
- `pm2-log-backup.timer` - Systemd timer for scheduling backups every 3 days

## Requirements

- PM2 process manager installed
- Root access or sudo privileges
- systemd-based Linux distribution

## Troubleshooting

### Check if timer is active
```bash
sudo systemctl is-active pm2-log-backup.timer
```

### Check service logs for errors
```bash
sudo journalctl -u pm2-log-backup.service -n 50
```

### View detailed backup log
```bash
sudo cat /root/.pm2backup/backup.log
# Or view last 50 lines
sudo tail -n 50 /root/.pm2backup/backup.log
```

### Check when the backup last ran
```bash
# View timestamp file
sudo cat /root/.pm2backup/last_run
# Convert to human-readable format (GNU/Linux)
sudo date -d "@$(cat /root/.pm2backup/last_run)" '+%Y-%m-%d %H:%M:%S'
# Or on BSD/macOS
sudo date -r "$(cat /root/.pm2backup/last_run)" '+%Y-%m-%d %H:%M:%S'
```

### Test the backup script manually
```bash
sudo /usr/local/bin/pm2-log-backup.sh
```

### Common Issues

#### "pm2 command not found"
- Ensure PM2 is installed: `npm install -g pm2`
- Check if PM2 is in the system PATH
- The script will log the PATH variable if PM2 is not found

#### "PM2 restart failed"
- Check the detailed log at `/root/.pm2backup/backup.log`
- Verify PM2 processes are running: `pm2 list`
- The script will attempt to show PM2 status even on failure

#### Cannot find last_run file
- The file is created at `/root/.pm2backup/last_run` on first successful backup
- Check if the backup directory is accessible: `ls -la /root/.pm2backup/`
- Verify permissions on the directory