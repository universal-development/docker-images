# Nginx-F1 Example Configuration

This directory contains a complete example setup demonstrating how to use the nginx-f1 Docker image with advanced logrotate functionality.

## 📁 Directory Structure

```
example/
├── README.md                           # This file
├── docker-compose.yml                  # Docker Compose configuration
├── nginx-with-logrotate.conf           # Nginx config with logrotate-optimized logging
├── nginx.conf                          # Basic nginx configuration
├── logrotate.env                       # Environment variables for logrotate
├── html/
│   └── index.html                      # Sample HTML page
├── logs/                               # Persistent log storage
│   ├── access.log                      # Main access log
│   ├── error.log                       # Main error log
│   ├── archive/                        # Rotated log archives
│   ├── backend-access.log              # Backend proxy access log
│   ├── backend-error.log               # Backend proxy error log
│   ├── backend2-access.log             # Backend2 proxy access log
│   ├── backend2-error.log              # Backend2 proxy error log
│   ├── status-access.log               # Status page access log
│   ├── status-error.log                # Status page error log
│   └── logrotate-manager.log           # Logrotate manager log
└── ssh-keys/                           # SSH keys for remote log archiving
```

## 🚀 Quick Start

### 1. Basic Setup

```bash
# Clone or download this example
cd nginx-f1/example

# Start the nginx container with logrotate
docker-compose up -d

# Check if the container is running
docker-compose ps

# View logs
docker-compose logs -f nginx
```

### 2. Access the Services

- **Main nginx**: http://localhost:80
- **Status page**: http://localhost:80/status
- **Upstream status**: http://localhost:80/upstream-status
- **Backend proxy (port 81)**: http://localhost:81
- **Backend proxy (port 82)**: http://localhost:82

## 🔧 Configuration Files

### docker-compose.yml

The main Docker Compose configuration that:
- Uses the `denis256/nginx-f1:latest` image
- Exposes ports 80, 8080, and 9090
- Mounts nginx configuration and logs for persistence
- Configures logrotate environment variables
- Includes health checks
- Optional backup server for remote log archiving

### nginx-with-logrotate.conf

Enhanced nginx configuration featuring:
- **Multiple log formats**: `main` and `detailed` with timing information
- **Separate log files**: Different logs for different services
- **Status monitoring**: Built-in status page with vhost traffic status
- **Upstream health checks**: Backend server monitoring
- **Performance optimizations**: Gzip compression, caching headers
- **Logrotate-friendly paths**: All logs in `/var/log/nginx/`

### logrotate.env

Environment variables for logrotate configuration:
- **Basic settings**: Frequency, retention, compression
- **Archive configuration**: Local archiving options
- **Remote transfer**: SCP, RSYNC, or S3 integration
- **Cleanup options**: Post-transfer cleanup settings

## 📊 Logrotate Features

### Supported Methods

1. **Supervisord** (default): Managed by supervisord process manager
2. **Daemon**: Standalone logrotate daemon process
3. **Cron**: Traditional cron-based log rotation
4. **Disabled**: No log rotation (logs grow indefinitely)

### Configuration Options

```bash
# Enable/disable logrotate
ENABLE_LOGROTATE=true

# Choose method
LOGROTATE_METHOD=supervisord  # supervisord, daemon, cron, disabled

# Rotation frequency
LOGROTATE_FREQUENCY=daily     # daily, weekly, monthly

# Retention
LOGROTATE_KEEP_DAYS=30        # Number of rotated files to keep

# Compression
LOGROTATE_COMPRESS=compress
LOGROTATE_COMPRESS_ARCHIVE=true

# Local archiving
LOGROTATE_ENABLE_ARCHIVE=true
LOGROTATE_ARCHIVE_DIR=/var/log/nginx/archive
```

### Remote Archiving

#### SCP/RSYNC Configuration
```bash
LOGROTATE_ENABLE_REMOTE=true
LOGROTATE_REMOTE_METHOD=scp
LOGROTATE_REMOTE_HOST=backup.example.com
LOGROTATE_REMOTE_USER=nginx-logs
LOGROTATE_REMOTE_PATH=/var/log/nginx-archive
LOGROTATE_SSH_PORT=22
```

#### S3 Configuration
```bash
LOGROTATE_ENABLE_REMOTE=true
LOGROTATE_REMOTE_METHOD=s3
LOGROTATE_S3_BUCKET=my-nginx-logs
LOGROTATE_AWS_ACCESS_KEY_ID=your-access-key
LOGROTATE_AWS_SECRET_ACCESS_KEY=your-secret-key
LOGROTATE_AWS_DEFAULT_REGION=us-east-1
LOGROTATE_S3_PREFIX=nginx-logs
```

## 🔍 Monitoring and Debugging

### View Logrotate Status

```bash
# Check logrotate configuration
docker-compose exec nginx cat /etc/logrotate.d/nginx

# View logrotate manager log
docker-compose exec nginx tail -f /var/log/nginx/logrotate-manager.log

# Check supervisord status (if using supervisord method)
docker-compose exec nginx supervisorctl status

# Manual logrotate execution
docker-compose exec nginx /usr/sbin/logrotate -f /etc/logrotate.d/nginx
```

### Log Files

- **Access logs**: `logs/access.log`, `logs/backend-*.log`, `logs/status-*.log`
- **Error logs**: `logs/error.log`, `logs/backend-*-error.log`, `logs/status-*-error.log`
- **Archive**: `logs/archive/` contains compressed rotated logs
- **Logrotate**: `logs/logrotate-manager.log` for logrotate operations

## 🧪 Testing

### Generate Log Traffic

```bash
# Generate some traffic to create logs
for i in {1..100}; do
  curl -s http://localhost:80/status > /dev/null
  curl -s http://localhost:81/ > /dev/null
  curl -s http://localhost:82/ > /dev/null
done

# Check log file sizes
docker-compose exec nginx ls -lh /var/log/nginx/
```

### Test Log Rotation

```bash
# Force log rotation
docker-compose exec nginx /usr/sbin/logrotate -f /etc/logrotate.d/nginx

# Check if rotation occurred
docker-compose exec nginx ls -la /var/log/nginx/archive/
```

## 🔧 Customization

### Custom Nginx Configuration

1. Edit `nginx-with-logrotate.conf` or `nginx.conf`
2. Restart the container: `docker-compose restart nginx`
3. The nginx-reloader will automatically reload configuration

### Custom Logrotate Settings

1. Edit `logrotate.env` or modify environment variables in `docker-compose.yml`
2. Restart the container: `docker-compose restart nginx`

### Adding Remote Backup

1. Set up SSH keys in `ssh-keys/` directory
2. Configure remote host settings in `docker-compose.yml`
3. Uncomment and configure remote archiving variables
4. Optionally start the backup server: `docker-compose --profile backup up -d`

## 🚨 Troubleshooting

### Common Issues

1. **Permission errors**: Ensure log directories have proper permissions
2. **SSH key issues**: Check SSH key permissions and host connectivity
3. **S3 access denied**: Verify AWS credentials and bucket permissions
4. **Log rotation not working**: Check `LOGROTATE_METHOD` and container logs

### Debug Commands

```bash
# Check container logs
docker-compose logs nginx

# Execute shell in container
docker-compose exec nginx bash

# Check logrotate configuration
docker-compose exec nginx logrotate -d /etc/logrotate.d/nginx

# Check nginx configuration
docker-compose exec nginx nginx -t
```

## 📚 Additional Resources

- [Main nginx-f1 README](../README.md)
- [Logrotate Implementation Guide](../LOGROTATE_IMPLEMENTATION.md)
- [Logrotate Process Explanation](../LOGROTATE_PROCESS_EXPLANATION.md)
- [Simple Example](../example-simple/) - Basic nginx setup without logrotate

## 🤝 Contributing

Feel free to submit issues and enhancement requests for this example configuration!
