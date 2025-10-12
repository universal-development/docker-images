#!/bin/bash
# Simple logrotate daemon script
# This script runs logrotate periodically without requiring cron or supervisord

set -e

# Configuration
LOGROTATE_INTERVAL=${LOGROTATE_INTERVAL:-86400}  # Default: 24 hours in seconds
LOGROTATE_CONFIG="/etc/logrotate.d/nginx"
LOG_FILE="/var/log/nginx/logrotate-daemon.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to run logrotate
run_logrotate() {
    log_message "Starting logrotate process"
    
    if [ -f "$LOGROTATE_CONFIG" ]; then
        # Run logrotate
        /usr/sbin/logrotate -f "$LOGROTATE_CONFIG" >> /var/log/nginx/logrotate-cron.log 2>&1
        
        # Check if logrotate was successful
        if [ $? -eq 0 ]; then
            log_message "Logrotate completed successfully"
        else
            log_message "Logrotate failed with exit code $?"
        fi
    else
        log_message "Logrotate config file not found: $LOGROTATE_CONFIG"
    fi
}

# Main daemon loop
log_message "Logrotate daemon started with interval: ${LOGROTATE_INTERVAL} seconds"

while true; do
    # Sleep for the specified interval
    sleep "$LOGROTATE_INTERVAL"
    
    # Run logrotate
    run_logrotate
done

