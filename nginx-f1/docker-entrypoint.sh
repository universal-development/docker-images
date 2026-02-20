#!/bin/bash

# Function to setup logrotate cron job
setup_logrotate_cron() {
    if [ "${ENABLE_LOGROTATE:-true}" = "true" ]; then
        # Create logrotate cron job
        echo "0 0 * * * /usr/sbin/logrotate -f /etc/logrotate.d/nginx >> /var/log/nginx/logrotate-cron.log 2>&1" > /etc/cron.d/nginx-logrotate

        echo "Logrotate cron job configured"
    fi
}

# Function to enable logrotate-daemon when LOGROTATE_INTERVAL is set
setup_logrotate_daemon() {
    if [ -n "${LOGROTATE_INTERVAL}" ] && [ "${LOGROTATE_INTERVAL}" != "86400" ]; then
        echo "Logrotate daemon enabled (interval: ${LOGROTATE_INTERVAL}s)"
        if [ -f /etc/supervisor/conf.d/supervisord.conf ]; then
            sed -i '/\[program:logrotate-daemon\]/,/priority=175/{s/autostart=false/autostart=true/}' /etc/supervisor/conf.d/supervisord.conf
        fi
        # Remove cron job to prevent double rotation
        rm -f /etc/cron.d/nginx-logrotate
    fi
}

# Function to setup disk cleanup daemon
setup_disk_cleanup() {
    if [ "${ENABLE_DISK_CLEANUP:-false}" = "true" ]; then
        echo "Disk cleanup enabled (threshold: ${DISK_CLEANUP_THRESHOLD_MB:-500}MB, target: ${DISK_CLEANUP_TARGET_MB:-1000}MB)"
        # Enable disk-cleanup autostart in supervisord config
        if [ -f /etc/supervisor/conf.d/supervisord.conf ]; then
            sed -i '/\[program:disk-cleanup\]/,/priority=180/{s/autostart=false/autostart=true/}' /etc/supervisor/conf.d/supervisord.conf
        fi
    fi
}

# Function to setup log directories and permissions
setup_log_directories() {
    # Ensure log directories exist with proper permissions
    mkdir -p /var/log/nginx/archive
    mkdir -p /var/log/supervisor
    chown -R www-data:www-data /var/log/nginx
    
    # Create log files if they don't exist
    touch /var/log/nginx/access.log /var/log/nginx/error.log
    chown www-data:www-data /var/log/nginx/access.log /var/log/nginx/error.log
}

# Function to configure logrotate with environment variables
configure_logrotate() {
    if [ -x /usr/bin/logrotate-manager.sh ]; then
        /usr/bin/logrotate-manager.sh configure
    fi
}

# Function to check logrotate method
get_logrotate_method() {
    # Check environment variable for logrotate method
    case "${LOGROTATE_METHOD:-supervisord}" in
        "supervisord")
            return 0
            ;;
        "daemon")
            return 1
            ;;
        "cron")
            return 2
            ;;
        "disabled")
            return 3
            ;;
        *)
            return 0  # Default to supervisord
            ;;
    esac
}

# Function to check if we should use supervisord or direct execution
should_use_supervisord() {
    # Use supervisord if ENABLE_LOGROTATE is true or if no specific command is provided
    if [ "${ENABLE_LOGROTATE:-true}" = "true" ] || [ "$#" -eq 0 ]; then
        return 0
    fi
    return 1
}

# Main setup
setup_log_directories
configure_logrotate
setup_logrotate_cron
setup_logrotate_daemon
setup_disk_cleanup

# Determine logrotate method and start accordingly
if [ "${ENABLE_LOGROTATE:-true}" != "true" ]; then
    echo "Logrotate disabled, starting nginx directly..."
    # Start nginx reloader in background
    sh -c "nginx-reloader.sh &"
    # Execute the main command directly
    exec "$@"
else
    get_logrotate_method
    case $? in
        0)  # supervisord
            echo "Starting with supervisord for process management..."
            echo "Nginx, cron, and nginx-reloader will be managed by supervisord"
            exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
            ;;
        1)  # daemon
            echo "Starting with logrotate daemon..."
            # Start nginx reloader in background
            sh -c "nginx-reloader.sh &"
            # Start logrotate daemon in background
            sh -c "logrotate-daemon.sh &"
            # Start nginx in foreground
            exec nginx -g "daemon off;"
            ;;
        2)  # cron
            echo "Starting with cron-based logrotate..."
            # Start cron service
            service cron start
            # Start nginx reloader in background
            sh -c "nginx-reloader.sh &"
            # Start nginx in foreground
            exec nginx -g "daemon off;"
            ;;
        3)  # disabled
            echo "Logrotate method set to disabled..."
            # Start nginx reloader in background
            sh -c "nginx-reloader.sh &"
            # Execute the main command directly
            exec "$@"
            ;;
    esac
fi
