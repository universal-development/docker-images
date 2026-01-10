#!/bin/bash
# Disk Space Cleanup Daemon
# Monitors disk space and aggressively cleans logs when space is low

set -e

# Configuration from environment
THRESHOLD_MB=${DISK_CLEANUP_THRESHOLD_MB:-500}
TARGET_MB=${DISK_CLEANUP_TARGET_MB:-1000}
INTERVAL=${DISK_CLEANUP_INTERVAL:-60}
EMERGENCY_MB=${DISK_CLEANUP_EMERGENCY_MB:-100}
DRY_RUN=${DISK_CLEANUP_DRY_RUN:-false}

# Directories
LOG_DIR="/var/log/nginx"
ARCHIVE_DIR="${LOGROTATE_ARCHIVE_DIR:-/var/log/nginx/archive}"
SUPERVISOR_DIR="/var/log/supervisor"
LOG_FILE="/var/log/nginx/disk-cleanup.log"

log_msg() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

get_free_space_mb() {
    df -BM /var/log | tail -1 | awk '{print $4}' | tr -d 'M'
}

get_file_size() {
    stat -c%s "$1" 2>/dev/null || echo 0
}

delete_file() {
    local file="$1"
    local size=$(get_file_size "$file")
    local size_mb=$((size / 1024 / 1024))

    if [ "$DRY_RUN" = "true" ]; then
        log_msg "[DRY-RUN] Would delete: $file (${size_mb}MB)"
    else
        rm -f "$file"
        log_msg "Deleted: $file (${size_mb}MB freed)"
    fi
}

clean_archives() {
    if [ ! -d "$ARCHIVE_DIR" ]; then
        return 0
    fi

    log_msg "Cleaning archive directory: $ARCHIVE_DIR"

    find "$ARCHIVE_DIR" -type f \( -name "*.tar.gz" -o -name "*.gz" \) -printf '%T@ %p\n' 2>/dev/null | \
        sort -n | cut -d' ' -f2- | while read file; do

        if [ $(get_free_space_mb) -ge "$TARGET_MB" ]; then
            log_msg "Target space reached, stopping archive cleanup"
            break
        fi

        if [ -f "$file" ]; then
            delete_file "$file"
        fi
    done
}

clean_rotated_logs() {
    log_msg "Cleaning rotated nginx logs"

    # Main log directory
    find "$LOG_DIR" -maxdepth 1 -type f -name "*.log.*" -printf '%T@ %p\n' 2>/dev/null | \
        sort -n | cut -d' ' -f2- | while read file; do

        if [ $(get_free_space_mb) -ge "$TARGET_MB" ]; then
            log_msg "Target space reached"
            break
        fi

        if [ -f "$file" ]; then
            delete_file "$file"
        fi
    done

    # Nested directories
    find "$LOG_DIR" -mindepth 2 -type f -name "*.log.*" -printf '%T@ %p\n' 2>/dev/null | \
        sort -n | cut -d' ' -f2- | while read file; do

        if [ $(get_free_space_mb) -ge "$TARGET_MB" ]; then
            break
        fi

        if [ -f "$file" ]; then
            delete_file "$file"
        fi
    done
}

clean_supervisor_logs() {
    if [ ! -d "$SUPERVISOR_DIR" ]; then
        return 0
    fi

    log_msg "Cleaning supervisor backup logs"

    find "$SUPERVISOR_DIR" -type f -name "*.log.*" -printf '%T@ %p\n' 2>/dev/null | \
        sort -n | cut -d' ' -f2- | while read file; do

        if [ $(get_free_space_mb) -ge "$TARGET_MB" ]; then
            break
        fi

        if [ -f "$file" ]; then
            delete_file "$file"
        fi
    done
}

emergency_cleanup() {
    log_msg "EMERGENCY: Truncating active log files"

    if [ "$DRY_RUN" = "true" ]; then
        log_msg "[DRY-RUN] Would truncate active logs"
        return 0
    fi

    for log in "$LOG_DIR/access.log" "$LOG_DIR/error.log"; do
        if [ -f "$log" ]; then
            local size=$(get_file_size "$log")
            : > "$log"
            log_msg "TRUNCATED: $log (was $((size/1024/1024))MB)"
        fi
    done

    if [ -f /var/run/nginx.pid ]; then
        kill -USR1 $(cat /var/run/nginx.pid) 2>/dev/null || true
        log_msg "Signaled nginx to reopen log files"
    fi
}

run_cleanup() {
    local free_mb=$(get_free_space_mb)

    log_msg "Cleanup triggered. Free: ${free_mb}MB, Threshold: ${THRESHOLD_MB}MB, Target: ${TARGET_MB}MB"

    # Priority 1: Archives
    clean_archives
    free_mb=$(get_free_space_mb)

    if [ "$free_mb" -ge "$TARGET_MB" ]; then
        log_msg "Cleanup complete. Free: ${free_mb}MB"
        return 0
    fi

    # Priority 2: Rotated logs
    clean_rotated_logs
    free_mb=$(get_free_space_mb)

    if [ "$free_mb" -ge "$TARGET_MB" ]; then
        log_msg "Cleanup complete. Free: ${free_mb}MB"
        return 0
    fi

    # Priority 3: Supervisor logs
    clean_supervisor_logs
    free_mb=$(get_free_space_mb)

    if [ "$free_mb" -ge "$TARGET_MB" ]; then
        log_msg "Cleanup complete. Free: ${free_mb}MB"
        return 0
    fi

    # Emergency: Truncate if below emergency threshold
    if [ "$free_mb" -lt "$EMERGENCY_MB" ]; then
        emergency_cleanup
    fi

    log_msg "Cleanup finished. Final free: $(get_free_space_mb)MB"
}

# Main
log_msg "Disk cleanup daemon started"
log_msg "Config: threshold=${THRESHOLD_MB}MB target=${TARGET_MB}MB interval=${INTERVAL}s emergency=${EMERGENCY_MB}MB dry_run=${DRY_RUN}"

# Run cleanup immediately on startup
free_mb=$(get_free_space_mb)
log_msg "Initial check: ${free_mb}MB free"
if [ "$free_mb" -lt "$THRESHOLD_MB" ]; then
    run_cleanup
fi

# Main daemon loop
while true; do
    sleep "$INTERVAL"

    free_mb=$(get_free_space_mb)
    if [ "$free_mb" -lt "$THRESHOLD_MB" ]; then
        run_cleanup
    fi
done
