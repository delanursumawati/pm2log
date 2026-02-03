# pm2log

Automated PM2 log backup system using systemd. This script automatically backs up PM2 logs every 3 days to prevent log files from growing too large.

## Features

- Automatic backup of `/root/.pm2/logs` to `/root/.pm2backup/logs` every 3 days
- Cleans up old backup before creating new one
- Restarts all PM2 processes after backup
- Runs as a systemd service and timer

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

### Stop the timer
```bash
sudo systemctl stop pm2-log-backup.timer
sudo systemctl disable pm2-log-backup.timer
```

## How It Works

The backup process follows these steps:

1. **Delete old backup**: Removes all files in `/root/.pm2backup/logs` if the directory exists
2. **Move logs to backup**: Copies all log files from `/root/.pm2/logs` to `/root/.pm2backup/logs`, then clears the original logs
3. **Restart PM2 processes**: Executes `pm2 restart all` to restart all PM2-managed processes

The timer is configured to:
- Run every 3 days at 00:00 WIB (17:00 UTC)
- The timer checks daily at 00:00 WIB, but only executes if 3 days have passed since the last run
- Persist across reboots (if a scheduled backup was missed, it will run on next boot)

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

### Test the backup script manually
```bash
sudo /usr/local/bin/pm2-log-backup.sh
```