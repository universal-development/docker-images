#!/bin/bash
# Nginx Logrotate Manager Script
# Handles archiving and remote transfer of rotated nginx logs

set -e

# Default configuration (can be overridden via environment variables)
ARCHIVE_DIR=${LOGROTATE_ARCHIVE_DIR:-/var/log/nginx/archive}
REMOTE_HOST=${LOGROTATE_REMOTE_HOST:-}
REMOTE_USER=${LOGROTATE_REMOTE_USER:-}
REMOTE_PATH=${LOGROTATE_REMOTE_PATH:-/var/log/nginx-archive}
REMOTE_METHOD=${LOGROTATE_REMOTE_METHOD:-scp}  # scp, rsync, s3, etc.
COMPRESS_ARCHIVE=${LOGROTATE_COMPRESS_ARCHIVE:-true}
CLEANUP_AFTER_REMOTE=${LOGROTATE_CLEANUP_AFTER_REMOTE:-false}
ENABLE_ARCHIVE=${LOGROTATE_ENABLE_ARCHIVE:-true}
ENABLE_REMOTE=${LOGROTATE_ENABLE_REMOTE:-false}

# S3 configuration (if using S3 as remote method)
AWS_ACCESS_KEY_ID=${LOGROTATE_AWS_ACCESS_KEY_ID:-}
AWS_SECRET_ACCESS_KEY=${LOGROTATE_AWS_SECRET_ACCESS_KEY:-}
AWS_DEFAULT_REGION=${LOGROTATE_AWS_DEFAULT_REGION:-us-east-1}
S3_BUCKET=${LOGROTATE_S3_BUCKET:-}
S3_PREFIX=${LOGROTATE_S3_PREFIX:-nginx-logs}

# SSH configuration for scp/rsync
SSH_KEY_PATH=${LOGROTATE_SSH_KEY_PATH:-/root/.ssh/id_rsa}
SSH_PORT=${LOGROTATE_SSH_PORT:-22}

# Logging
LOG_FILE="/var/log/nginx/logrotate-manager.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to create archive directory
create_archive_dir() {
    if [ ! -d "$ARCHIVE_DIR" ]; then
        mkdir -p "$ARCHIVE_DIR"
        chown www-data:www-data "$ARCHIVE_DIR"
        log_message "Created archive directory: $ARCHIVE_DIR"
    fi
}

# Function to archive rotated logs
archive_logs() {
    if [ "$ENABLE_ARCHIVE" != "true" ]; then
        return 0
    fi
    
    log_message "Starting log archiving process"
    
    # Find recently rotated logs (compressed files from today)
    local rotated_logs=$(find /var/log/nginx -name "*.log.*" -type f -mtime -1 2>/dev/null || true)
    
    if [ -z "$rotated_logs" ]; then
        log_message "No rotated logs found to archive"
        return 0
    fi
    
    create_archive_dir
    
    # Move rotated logs to archive directory
    for log_file in $rotated_logs; do
        if [ -f "$log_file" ]; then
            local filename=$(basename "$log_file")
            local archive_file="$ARCHIVE_DIR/${filename}.$(date +%Y%m%d_%H%M%S)"
            
            # Move the file to archive directory
            mv "$log_file" "$archive_file"
            chown www-data:www-data "$archive_file"
            
            log_message "Archived: $log_file -> $archive_file"
        fi
    done
    
    # Create compressed archive if enabled
    if [ "$COMPRESS_ARCHIVE" = "true" ]; then
        local archive_name="nginx-logs-$(date +%Y%m%d).tar.gz"
        local archive_path="$ARCHIVE_DIR/$archive_name"
        
        # Create compressed archive of today's logs
        cd "$ARCHIVE_DIR"
        tar -czf "$archive_path" *.$(date +%Y%m%d_*) 2>/dev/null || true
        
        if [ -f "$archive_path" ]; then
            chown www-data:www-data "$archive_path"
            log_message "Created compressed archive: $archive_path"
        fi
    fi
}

# Function to transfer logs to remote location
transfer_to_remote() {
    if [ "$ENABLE_REMOTE" != "true" ]; then
        return 0
    fi
    
    if [ -z "$REMOTE_HOST" ] && [ -z "$S3_BUCKET" ]; then
        log_message "Remote transfer enabled but no remote host or S3 bucket configured"
        return 1
    fi
    
    log_message "Starting remote transfer process"
    
    case "$REMOTE_METHOD" in
        "scp")
            transfer_via_scp
            ;;
        "rsync")
            transfer_via_rsync
            ;;
        "s3")
            transfer_via_s3
            ;;
        *)
            log_message "Unknown remote method: $REMOTE_METHOD"
            return 1
            ;;
    esac
}

# Function to transfer via SCP
transfer_via_scp() {
    if [ -z "$REMOTE_HOST" ] || [ -z "$REMOTE_USER" ]; then
        log_message "SCP transfer requires REMOTE_HOST and REMOTE_USER"
        return 1
    fi
    
    local ssh_opts="-i $SSH_KEY_PATH -p $SSH_PORT -o StrictHostKeyChecking=no"
    
    # Create remote directory if it doesn't exist
    ssh $ssh_opts "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $REMOTE_PATH"
    
    # Transfer archive files
    if [ "$COMPRESS_ARCHIVE" = "true" ]; then
        local archive_name="nginx-logs-$(date +%Y%m%d).tar.gz"
        local archive_path="$ARCHIVE_DIR/$archive_name"
        
        if [ -f "$archive_path" ]; then
            scp $ssh_opts "$archive_path" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/"
            log_message "Transferred compressed archive to remote: $archive_path"
        fi
    else
        # Transfer individual files
        scp $ssh_opts "$ARCHIVE_DIR"/* "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/"
        log_message "Transferred individual log files to remote"
    fi
}

# Function to transfer via rsync
transfer_via_rsync() {
    if [ -z "$REMOTE_HOST" ] || [ -z "$REMOTE_USER" ]; then
        log_message "Rsync transfer requires REMOTE_HOST and REMOTE_USER"
        return 1
    fi
    
    local rsync_opts="-avz -e 'ssh -i $SSH_KEY_PATH -p $SSH_PORT -o StrictHostKeyChecking=no'"
    
    eval "rsync $rsync_opts $ARCHIVE_DIR/ $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/"
    log_message "Synchronized logs to remote via rsync"
}

# Function to transfer via S3
transfer_via_s3() {
    if [ -z "$S3_BUCKET" ]; then
        log_message "S3 transfer requires S3_BUCKET to be configured"
        return 1
    fi
    
    # Check if AWS CLI is available
    if ! command -v aws &> /dev/null; then
        log_message "AWS CLI not found, installing..."
        apt-get update && apt-get install -y awscli
    fi
    
    # Configure AWS credentials if provided
    if [ -n "$AWS_ACCESS_KEY_ID" ] && [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
        aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
        aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
        aws configure set default.region "$AWS_DEFAULT_REGION"
    fi
    
    # Upload to S3
    local s3_path="s3://$S3_BUCKET/$S3_PREFIX/$(date +%Y/%m/%d)/"
    
    if [ "$COMPRESS_ARCHIVE" = "true" ]; then
        local archive_name="nginx-logs-$(date +%Y%m%d).tar.gz"
        local archive_path="$ARCHIVE_DIR/$archive_name"
        
        if [ -f "$archive_path" ]; then
            aws s3 cp "$archive_path" "$s3_path"
            log_message "Uploaded compressed archive to S3: $s3_path$archive_name"
        fi
    else
        aws s3 sync "$ARCHIVE_DIR/" "$s3_path"
        log_message "Synchronized logs to S3: $s3_path"
    fi
}

# Function to cleanup local archives after remote transfer
cleanup_local_archives() {
    if [ "$CLEANUP_AFTER_REMOTE" = "true" ] && [ "$ENABLE_REMOTE" = "true" ]; then
        log_message "Cleaning up local archives after remote transfer"
        rm -f "$ARCHIVE_DIR"/*
        log_message "Local archives cleaned up"
    fi
}

# Function to configure logrotate dynamically
configure_logrotate() {
    local config_file="/etc/logrotate.d/nginx"
    local temp_config="/tmp/nginx-logrotate.conf.tmp"
    
    # Create temporary configuration with environment variable substitutions
    sed -e "s/daily/${LOGROTATE_FREQUENCY:-daily}/g" \
        -e "s/rotate 30/rotate ${LOGROTATE_KEEP_DAYS:-30}/g" \
        -e "s/compress/${LOGROTATE_COMPRESS:-compress}/g" \
        -e "s/missingok/${LOGROTATE_MISSINGOK:-missingok}/g" \
        -e "s/notifempty/${LOGROTATE_NOTIFEMPTY:-notifempty}/g" \
        "$config_file" > "$temp_config"
    
    # Replace the original configuration
    mv "$temp_config" "$config_file"
    
    log_message "Logrotate configuration updated with environment variables"
}

# Main function
main() {
    local action="${1:-postrotate}"
    
    case "$action" in
        "postrotate")
            log_message "Starting post-rotation processing"
            configure_logrotate
            archive_logs
            transfer_to_remote
            cleanup_local_archives
            log_message "Post-rotation processing completed"
            ;;
        "archive")
            archive_logs
            ;;
        "transfer")
            transfer_to_remote
            ;;
        "configure")
            configure_logrotate
            ;;
        "cleanup")
            cleanup_local_archives
            ;;
        *)
            echo "Usage: $0 {postrotate|archive|transfer|configure|cleanup}"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"

