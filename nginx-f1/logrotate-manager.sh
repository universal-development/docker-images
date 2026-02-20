#!/bin/bash
# Nginx Logrotate Manager Script
# Handles archiving and remote transfer of rotated nginx logs

set -e

# Default configuration (can be overridden via environment variables)
ARCHIVE_DIR=${LOGROTATE_ARCHIVE_DIR:-/var/log/nginx/archive}
REMOTE_HOST=${LOGROTATE_REMOTE_HOST:-}
REMOTE_USER=${LOGROTATE_REMOTE_USER:-}
REMOTE_PATH=${LOGROTATE_REMOTE_PATH:-/var/log/nginx-archive}
REMOTE_METHOD=${LOGROTATE_REMOTE_METHOD:-scp}  # scp, sftp, rsync, s3
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
    
    # Find recently rotated logs (top-level only, skip archive dir)
    local rotated_logs=$(find /var/log/nginx -maxdepth 1 -name "*.log.*" -type f -mtime -1 2>/dev/null || true)
    
    if [ -z "$rotated_logs" ]; then
        log_message "No rotated logs found to archive"
        return 0
    fi
    
    create_archive_dir
    
    # Move and gzip rotated logs individually to archive directory
    for log_file in $rotated_logs; do
        if [ -f "$log_file" ]; then
            local filename=$(basename "$log_file")
            local archive_file="$ARCHIVE_DIR/${filename}.$(date +%Y%m%d_%H%M%S)"

            mv "$log_file" "$archive_file"
            gzip "$archive_file"
            chown www-data:www-data "${archive_file}.gz"

            log_message "Archived: $log_file -> ${archive_file}.gz"
        fi
    done
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
        "sftp")
            transfer_via_sftp
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
    
    local ssh_opts="-i $SSH_KEY_PATH -p $SSH_PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=30"
    local date_subdir="$(date +%Y-%m)/$(date +%d)"
    local remote_dest="$REMOTE_PATH/$date_subdir"

    # Create remote date-based directory
    timeout 30 ssh $ssh_opts "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $remote_dest"

    # Transfer archived files
    for f in "$ARCHIVE_DIR"/*.gz; do
        if [ -f "$f" ]; then
            timeout 120 scp $ssh_opts "$f" "$REMOTE_USER@$REMOTE_HOST:$remote_dest/"
            log_message "Transferred: $remote_dest/$(basename $f)"
        fi
    done
}

# Function to transfer via SFTP (batch mode — works with SFTP-only servers)
transfer_via_sftp() {
    if [ -z "$REMOTE_HOST" ] || [ -z "$REMOTE_USER" ]; then
        log_message "SFTP transfer requires REMOTE_HOST and REMOTE_USER"
        return 1
    fi

    local sftp_opts="-P $SSH_PORT -i $SSH_KEY_PATH -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=30 -o ServerAliveInterval=10 -o ServerAliveCountMax=3"
    local batch_file=$(mktemp /tmp/sftp-batch-XXXXXX)
    local date_subdir="$(date +%Y-%m)/$(date +%d)"
    local remote_dest="$REMOTE_PATH/$date_subdir"

    # Create remote date-based directories (dash prefix = ignore errors if already exists)
    local parent_dir=$(dirname "$REMOTE_PATH")
    if [ "$parent_dir" != "/" ] && [ "$parent_dir" != "." ]; then
        echo "-mkdir $parent_dir" >> "$batch_file"
    fi
    echo "-mkdir $REMOTE_PATH" >> "$batch_file"
    echo "-mkdir $REMOTE_PATH/$(date +%Y-%m)" >> "$batch_file"
    echo "-mkdir $remote_dest" >> "$batch_file"

    # Add archived files to upload
    local file_count=0
    for f in "$ARCHIVE_DIR"/*.gz; do
        if [ -f "$f" ]; then
            echo "put $f $remote_dest/" >> "$batch_file"
            file_count=$((file_count + 1))
        fi
    done

    if [ "$file_count" -eq 0 ]; then
        log_message "No files to transfer via SFTP"
        rm -f "$batch_file"
        return 0
    fi

    # Execute sftp batch
    if timeout 120 sftp $sftp_opts -b "$batch_file" "$REMOTE_USER@$REMOTE_HOST" >> "$LOG_FILE" 2>&1; then
        log_message "Transferred $file_count files to remote via SFTP"
    else
        log_message "SFTP transfer failed (exit code $?)"
        rm -f "$batch_file"
        return 1
    fi

    rm -f "$batch_file"
}

# Function to transfer via rsync
transfer_via_rsync() {
    if [ -z "$REMOTE_HOST" ] || [ -z "$REMOTE_USER" ]; then
        log_message "Rsync transfer requires REMOTE_HOST and REMOTE_USER"
        return 1
    fi
    
    local rsync_opts="-avz -e 'ssh -i $SSH_KEY_PATH -p $SSH_PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=30'"
    local date_subdir="$(date +%Y-%m)/$(date +%d)"
    local remote_dest="$REMOTE_PATH/$date_subdir"

    eval "timeout 120 rsync $rsync_opts $ARCHIVE_DIR/ $REMOTE_USER@$REMOTE_HOST:$remote_dest/"
    log_message "Synchronized logs to remote via rsync: $remote_dest/"
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
    
    for f in "$ARCHIVE_DIR"/*.gz; do
        if [ -f "$f" ]; then
            aws s3 cp "$f" "$s3_path"
            log_message "Uploaded to S3: $s3_path$(basename $f)"
        fi
    done
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

