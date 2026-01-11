# nginx-f1 🚀

A production-ready Nginx Docker image with advanced logrotate capabilities and comprehensive monitoring features.

[![Docker Image](https://img.shields.io/badge/docker-nginx--f1-blue.svg)](https://hub.docker.com/r/denis256/nginx-f1)
[![Ubuntu](https://img.shields.io/badge/ubuntu-20.04%20LTS-orange.svg)](https://ubuntu.com)
[![Nginx](https://img.shields.io/badge/nginx-1.29.2-green.svg)](https://nginx.org)

## ✨ Features

- **🚀 High Performance**: Nginx 1.29.2 built from source with tuned upstream health checks and caching helpers
- **📊 Advanced Monitoring**: Built-in VTS (Virtual Host Traffic Status) and upstream health checks
- **🔄 Smart Log Rotation**: Configurable logrotate with local archiving and remote transfer (SCP/RSYNC/S3)
- **🗑️ Disk Space Protection**: Optional aggressive cleanup daemon prevents disk exhaustion
- **⚡ Auto-Reload**: Automatic configuration reloading on `*.conf` file changes (watches `/etc/nginx` by default)
- **🛡️ Production Ready**: Multiple process management options with comprehensive error handling
- **🔧 Highly Configurable**: Environment-driven configuration with extensive customization options

## 📋 Version Information

| Component      | Version          | Description                                      |
|----------------|------------------|--------------------------------------------------|
| **Base Image** | Ubuntu 20.04 LTS | Focal Fossa with long-term support until 2025    |
| **Nginx**      | 1.29.2           | Latest mainline release with custom module stack |
| **libpng**     | 1.6.43           | Latest PNG library with security patches         |
| **VTS Module** | v0.1.18          | Virtual Host Traffic Status monitoring           |

## 🔧 Included Modules

- **nginx_upstream_check_module**: Upstream server health monitoring
- **nginx-module-vts**: Real-time traffic statistics
- **ngx_devel_kit**: Development utilities
- **ngx_cache_purge**: Cache purging capabilities
- **echo-nginx-module**: Enhanced echo functionality
- **set-misc-nginx-module**: Additional set operations
- **ngx_http_geoip2_module**: GeoIP2 support with MaxMindDB
- **headers-more-nginx-module**: Advanced header manipulation
- **ngx_http_substitutions_filter_module**: Response substitution

## ⚠️ Compatibility Notes

- **Ubuntu 20.04**: Chosen for OpenSSL 1.1.1 compatibility with Nginx 1.29.2
- **OpenSSL 3.0**: Ubuntu 24.04's OpenSSL 3.0 has deprecated functions that cause compilation failures
- **Module Compatibility**: The bundled third-party modules have been validated against Nginx 1.29.2
- **Future Upgrades**: Review third-party modules when moving to newer Nginx releases

## 🚀 Quick Start

### Basic Usage

```bash
# Run with default configuration
docker run -d --name nginx-f1 -p 80:80 denis256/nginx-f1:latest

# Run with custom nginx configuration
docker run -d --name nginx-f1 \
  -p 80:80 -p 8080:8080 -p 9090:9090 \
  -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro \
  denis256/nginx-f1:latest
```

### Docker Compose (Recommended)

```yaml
version: '3.8'
services:
  nginx:
    image: denis256/nginx-f1:latest
    container_name: nginx-f1
    ports:
      - "80:80"
      - "8080:8080"
      - "9090:9090"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./logs:/var/log/nginx
    environment:
      - ENABLE_LOGROTATE=true
      - LOGROTATE_METHOD=supervisord
    restart: unless-stopped
    healthcheck:
      test: [ "CMD", "curl", "-f", "http://localhost:9090/status" ]
      interval: 30s
      timeout: 10s
      retries: 3
```

### Access Points

- **Main Application**: http://localhost:80
- **Status Dashboard**: http://localhost:9090/status
- **Upstream Health**: http://localhost:9090/upstream-status

## 🔄 Advanced Logrotate Configuration

The image includes comprehensive logrotate functionality with multiple process management options and remote archiving
capabilities.

### Basic Logrotate Setup

```bash
# Default logrotate (recommended for production)
docker run -d --name nginx-f1 \
  -p 80:80 \
  -e ENABLE_LOGROTATE=true \
  -e LOGROTATE_METHOD=supervisord \
  denis256/nginx-f1:latest

# Custom retention and frequency
docker run -d --name nginx-f1 \
  -p 80:80 \
  -e ENABLE_LOGROTATE=true \
  -e LOGROTATE_FREQUENCY=daily \
  -e LOGROTATE_KEEP_DAYS=7 \
  -e LOGROTATE_COMPRESS_ARCHIVE=true \
  denis256/nginx-f1:latest
```

### Remote Archiving Examples

#### SCP Archiving

```bash
docker run -d --name nginx-f1 \
  -p 80:80 \
  -v ./ssh-keys:/root/.ssh:ro \
  -e LOGROTATE_ENABLE_REMOTE=true \
  -e LOGROTATE_REMOTE_METHOD=scp \
  -e LOGROTATE_REMOTE_HOST=backup.example.com \
  -e LOGROTATE_REMOTE_USER=nginx-logs \
  -e LOGROTATE_REMOTE_PATH=/var/log/nginx-archive \
  denis256/nginx-f1:latest
```

#### S3 Archiving

```bash
docker run -d --name nginx-f1 \
  -p 80:80 \
  -e LOGROTATE_ENABLE_REMOTE=true \
  -e LOGROTATE_REMOTE_METHOD=s3 \
  -e LOGROTATE_S3_BUCKET=my-nginx-logs \
  -e LOGROTATE_AWS_ACCESS_KEY_ID=your-access-key \
  -e LOGROTATE_AWS_SECRET_ACCESS_KEY=your-secret-key \
  -e LOGROTATE_AWS_DEFAULT_REGION=us-east-1 \
  denis256/nginx-f1:latest
```

### Configuration Options

| Variable                     | Default                  | Description                            | Options                                     |
|------------------------------|--------------------------|----------------------------------------|---------------------------------------------|
| `ENABLE_LOGROTATE`           | `true`                   | Enable/disable logrotate functionality | `true`, `false`                             |
| `LOGROTATE_METHOD`           | `supervisord`            | Process management method              | `supervisord`, `daemon`, `cron`, `disabled` |
| `LOGROTATE_FREQUENCY`        | `daily`                  | Rotation frequency                     | `daily`, `weekly`, `monthly`                |
| `LOGROTATE_KEEP_DAYS`        | `30`                     | Number of rotated logs to keep         | `1-365`                                     |
| `LOGROTATE_ENABLE_ARCHIVE`   | `true`                   | Enable local archiving                 | `true`, `false`                             |
| `LOGROTATE_ARCHIVE_DIR`      | `/var/log/nginx/archive` | Local archive directory                | Any valid path                              |
| `LOGROTATE_COMPRESS_ARCHIVE` | `true`                   | Compress archived logs                 | `true`, `false`                             |

### Remote Transfer Options

| Variable                         | Default | Description                         | Required for       |
|----------------------------------|---------|-------------------------------------|--------------------|
| `LOGROTATE_ENABLE_REMOTE`        | `false` | Enable remote transfer              | All remote methods |
| `LOGROTATE_REMOTE_METHOD`        | `scp`   | Remote transfer method              | All remote methods |
| `LOGROTATE_CLEANUP_AFTER_REMOTE` | `false` | Clean local archives after transfer | All remote methods |

### SCP/RSYNC Configuration

| Variable                 | Default             | Description                    |
|--------------------------|---------------------|--------------------------------|
| `LOGROTATE_REMOTE_HOST`  | -                   | Remote server hostname/IP      |
| `LOGROTATE_REMOTE_USER`  | -                   | SSH username for remote server |
| `LOGROTATE_REMOTE_PATH`  | -                   | Remote directory path          |
| `LOGROTATE_SSH_KEY_PATH` | `/root/.ssh/id_rsa` | Path to SSH private key        |
| `LOGROTATE_SSH_PORT`     | `22`                | SSH port number                |

### S3 Configuration

| Variable                          | Default | Description           |
|-----------------------------------|---------|-----------------------|
| `LOGROTATE_S3_BUCKET`             | -       | S3 bucket name        |
| `LOGROTATE_AWS_ACCESS_KEY_ID`     | -       | AWS access key ID     |
| `LOGROTATE_AWS_SECRET_ACCESS_KEY` | -       | AWS secret access key |
| `LOGROTATE_AWS_DEFAULT_REGION`    | -       | AWS region            |
| `LOGROTATE_S3_PREFIX`             | -       | S3 object key prefix  |

### Process Management Methods

The image supports multiple process management approaches for logrotate:

| Method            | Reliability | Resource Usage | Auto Restart | Best For                      |
|-------------------|-------------|----------------|--------------|-------------------------------|
| **supervisord** ⭐ | ⭐⭐⭐⭐⭐       | Medium         | ✅ Yes        | Production environments       |
| **daemon**        | ⭐⭐⭐⭐        | Low            | ⚠️ Limited   | Lightweight deployments       |
| **cron**          | ⭐⭐⭐         | Low            | ❌ No         | Traditional Unix environments |
| **disabled**      | N/A         | Lowest         | N/A          | External log rotation         |

#### 1. Supervisord (Recommended for Production)

```bash
docker run -d --name nginx-f1 \
  -p 80:80 \
  -e LOGROTATE_METHOD=supervisord \
  denis256/nginx-f1:latest
```

- ✅ **Process supervision** with automatic restart
- ✅ **Centralized logging** in `/var/log/supervisor/`
- ✅ **Production-grade reliability**
- ✅ **Easy monitoring** with `supervisorctl status`

#### 2. Daemon Script (Lightweight)

```bash
docker run -d --name nginx-f1 \
  -p 80:80 \
  -e LOGROTATE_METHOD=daemon \
  -e LOGROTATE_INTERVAL=43200 \
  denis256/nginx-f1:latest
```

- ✅ **Minimal resource usage**
- ✅ **No additional packages**
- ✅ **Configurable interval** (default: 24 hours)

#### 3. Cron-based (Traditional)

```bash
docker run -d --name nginx-f1 \
  -p 80:80 \
  -e LOGROTATE_METHOD=cron \
  denis256/nginx-f1:latest
```

- ✅ **Standard Unix approach**
- ✅ **Precise scheduling**
- ⚠️ **No automatic restart** if cron fails

#### 4. Disabled (External Management)

```bash
docker run -d --name nginx-f1 \
  -p 80:80 \
  -e LOGROTATE_METHOD=disabled \
  denis256/nginx-f1:latest
```

- ✅ **External log rotation** (host-based or other tools)
- ✅ **Minimal overhead**

## 🗑️ Disk Space Cleanup

The image includes an optional disk-space monitoring daemon that proactively cleans old logs when disk space gets low. This prevents disk exhaustion in high-traffic environments.

### How It Works

The `disk-cleanup` daemon runs as a background process (managed by supervisord) that:

1. **Monitors disk space** every N seconds (default: 60s)
2. **Triggers cleanup** when free space drops below threshold (default: 500MB)
3. **Deletes old files** in priority order until target free space reached (default: 1000MB)
4. **Emergency mode** truncates active logs if space critically low (default: <100MB)

### Cleanup Priority Order

When cleanup triggers, files are deleted in this order (oldest first within each category):

| Priority | Location | Files | Description |
|----------|----------|-------|-------------|
| 1 | `/var/log/nginx/archive/` | `*.tar.gz`, `*.gz` | Archived rotated logs |
| 2 | `/var/log/nginx/` | `*.log.*` | Rotated nginx logs |
| 3 | `/var/log/nginx/*/` | `*.log.*` | Nested rotated logs |
| 4 | `/var/log/supervisor/` | `*.log.*` | Supervisor backup logs |
| 5 | **EMERGENCY** | `access.log`, `error.log` | Truncate active logs + signal nginx |

### Enable Disk Cleanup

```bash
docker run -d --name nginx-f1 \
  -p 80:80 \
  -e ENABLE_DISK_CLEANUP=true \
  -e DISK_CLEANUP_THRESHOLD_MB=500 \
  -e DISK_CLEANUP_TARGET_MB=1000 \
  denis256/nginx-f1:latest
```

### Configuration Options

| Variable | Default | Description |
|----------|---------|-------------|
| `ENABLE_DISK_CLEANUP` | `false` | Enable disk cleanup daemon |
| `DISK_CLEANUP_THRESHOLD_MB` | `500` | Start cleanup when free space below this (MB) |
| `DISK_CLEANUP_TARGET_MB` | `1000` | Target free space after cleanup (MB) |
| `DISK_CLEANUP_INTERVAL` | `60` | Check interval in seconds |
| `DISK_CLEANUP_EMERGENCY_MB` | `100` | Emergency threshold - truncates active logs |
| `DISK_CLEANUP_DRY_RUN` | `false` | Log what would be deleted without deleting |

### Docker Compose Example

```yaml
version: '3.8'
services:
  nginx:
    image: denis256/nginx-f1:latest
    ports:
      - "80:80"
    volumes:
      - ./logs:/var/log/nginx
    environment:
      - ENABLE_LOGROTATE=true
      - LOGROTATE_KEEP_DAYS=7
      - ENABLE_DISK_CLEANUP=true
      - DISK_CLEANUP_THRESHOLD_MB=500
      - DISK_CLEANUP_TARGET_MB=1000
      - DISK_CLEANUP_INTERVAL=60
```

### Monitoring Disk Cleanup

```bash
# Check disk cleanup daemon status
docker exec nginx-f1 supervisorctl status disk-cleanup

# View cleanup logs
docker exec nginx-f1 tail -f /var/log/nginx/disk-cleanup.log

# Test with dry-run mode (logs actions without deleting)
docker run -d --name nginx-test \
  -e ENABLE_DISK_CLEANUP=true \
  -e DISK_CLEANUP_DRY_RUN=true \
  denis256/nginx-f1:latest
```

### Example Log Output

```
2024-01-15 10:30:00 - Disk cleanup daemon started
2024-01-15 10:30:00 - Config: threshold=500MB target=1000MB interval=60s emergency=100MB dry_run=false
2024-01-15 10:30:00 - Initial check: 450MB free
2024-01-15 10:30:00 - Cleanup triggered. Free: 450MB, Threshold: 500MB, Target: 1000MB
2024-01-15 10:30:00 - Cleaning archive directory: /var/log/nginx/archive
2024-01-15 10:30:00 - Deleted: /var/log/nginx/archive/nginx-logs-20240110.tar.gz (150MB freed)
2024-01-15 10:30:01 - Deleted: /var/log/nginx/archive/nginx-logs-20240111.tar.gz (200MB freed)
2024-01-15 10:30:01 - Target space reached, stopping archive cleanup
2024-01-15 10:30:01 - Cleanup complete. Free: 1050MB
```

## ⚡ Auto-Reload Configuration

The `nginx-reloader` daemon watches for configuration file changes and automatically reloads nginx when `*.conf` files are modified.

### How It Works

1. **Computes hash** of all `*.conf` files on startup (MD5 checksum)
2. **Watches directory** using `inotifywait` for any file events
3. **Recomputes hash** after detecting file activity
4. **Compares hashes** - only proceeds if content actually changed
5. **Validates config** - runs `nginx -t` before reloading
6. **Safe reload** - skips reload if config test fails

### Key Features

| Feature | Description |
|---------|-------------|
| **Hash-based detection** | Only reloads when `.conf` file content actually changes |
| **Ignores non-conf files** | Log files, temp files, PIDs don't trigger reload |
| **Ignores file touches** | Timestamp changes without content change are ignored |
| **Batches rapid changes** | Multiple quick edits result in single reload |
| **Pre-flight checks** | Validates `inotifywait`, `nginx`, and `WATCH_DIR` exist |
| **Safe reload** | Always runs `nginx -t` before reload |

### Configuration Options

| Variable | Default | Description |
|----------|---------|-------------|
| `WATCH_DIR` | `/etc/nginx` | Directory to watch for config changes |
| `RELOADER_LOG` | `/var/log/nginx/reloader.log` | Log file path |
| `RELOADER_DELAY` | `2` | Delay in seconds before checking (batches rapid changes) |

### Example Usage

```bash
# Watch only conf.d directory
docker run -d --name nginx-f1 \
  -p 80:80 \
  -e WATCH_DIR=/etc/nginx/conf.d \
  denis256/nginx-f1:latest

# Faster response (1 second delay)
docker run -d --name nginx-f1 \
  -p 80:80 \
  -e RELOADER_DELAY=1 \
  denis256/nginx-f1:latest
```

### Monitoring Reloader

```bash
# Check reloader status
docker exec nginx-f1 supervisorctl status nginx-reloader

# View reloader logs
docker exec nginx-f1 tail -f /var/log/nginx/reloader.log

# Or supervisor logs
docker exec nginx-f1 tail -f /var/log/supervisor/nginx-reloader.log
```

### Example Log Output

```
[2024-01-15 10:30:00] Starting nginx-reloader v3
[2024-01-15 10:30:00] Config: WATCH_DIR=/etc/nginx DELAY=2s
[2024-01-15 10:30:00] Initial config hash: a1b2c3d4e5f67890
[2024-01-15 10:35:22] Config changed: a1b2c3d4e5f67890 -> 0987f6e5d4c3b2a1
[2024-01-15 10:35:22] Config valid, reloading nginx
```

### Troubleshooting

| Issue | Solution |
|-------|----------|
| Reloader not starting | Check logs: `docker exec nginx-f1 cat /var/log/supervisor/nginx-reloader.log` |
| Changes not detected | Verify `WATCH_DIR` is correct and contains `.conf` files |
| Too many reloads | Increase `RELOADER_DELAY` to batch rapid changes |
| No reloads happening | Check if file content actually changed (hash-based detection) |

## 📊 Monitoring & Logs

### Status Endpoints

- **Main Application**: http://localhost:80
- **Status Dashboard**: http://localhost:9090/status
- **Upstream Health**: http://localhost:9090/upstream-status

### Log Files

| Location                               | Description                                      |
|----------------------------------------|--------------------------------------------------|
| `/var/log/nginx/access.log`            | Main access log                                  |
| `/var/log/nginx/error.log`             | Main error log                                   |
| `/var/log/nginx/archive/`              | Archived rotated logs                            |
| `/var/log/nginx/logrotate-manager.log` | Logrotate manager logs                           |
| `/var/log/nginx/logrotate-cron.log`    | Cron job logs                                    |
| `/var/log/nginx/disk-cleanup.log`      | Disk cleanup daemon logs                         |
| `/var/log/nginx/reloader.log`          | Nginx config reloader logs                       |
| `/var/log/supervisor/`                 | Supervisord logs (when using supervisord method) |

### Manual Operations

```bash
# Check nginx status
docker exec nginx-f1 nginx -t

# Reload nginx configuration
docker exec nginx-f1 nginx -s reload

# Manual log rotation
docker exec nginx-f1 logrotate -f /etc/logrotate.d/nginx

# Check logrotate status
docker exec nginx-f1 tail -f /var/log/nginx/logrotate-manager.log

# Check supervisord status (if using supervisord method)
docker exec nginx-f1 supervisorctl status
```

## 🛠️ Examples & Use Cases

### Production Setup with Remote Archiving

```yaml
version: '3.8'
services:
  nginx:
    image: denis256/nginx-f1:latest
    container_name: nginx-f1-production
    ports:
      - "80:80"
      - "9090:9090"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./logs:/var/log/nginx
      - ./ssh-keys:/root/.ssh:ro
    environment:
      - ENABLE_LOGROTATE=true
      - LOGROTATE_METHOD=supervisord
      - LOGROTATE_ENABLE_REMOTE=true
      - LOGROTATE_REMOTE_METHOD=scp
      - LOGROTATE_REMOTE_HOST=backup.example.com
      - LOGROTATE_REMOTE_USER=nginx-logs
      - LOGROTATE_REMOTE_PATH=/var/log/nginx-archive
      - LOGROTATE_KEEP_DAYS=7
      - LOGROTATE_COMPRESS_ARCHIVE=true
    restart: unless-stopped
    healthcheck:
      test: [ "CMD", "curl", "-f", "http://localhost:9090/status" ]
      interval: 30s
      timeout: 10s
      retries: 3
```

### Development Setup (Minimal)

```yaml
version: '3.8'
services:
  nginx:
    image: denis256/nginx-f1:latest
    ports:
      - "8080:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    environment:
      - ENABLE_LOGROTATE=false
```

### High-Availability Setup

```yaml
version: '3.8'
services:
  nginx-1:
    image: denis256/nginx-f1:latest
    container_name: nginx-f1-ha-1
    ports:
      - "80:80"
    environment:
      - LOGROTATE_METHOD=supervisord
    restart: unless-stopped

  nginx-2:
    image: denis256/nginx-f1:latest
    container_name: nginx-f1-ha-2
    ports:
      - "81:80"
    environment:
      - LOGROTATE_METHOD=supervisord
    restart: unless-stopped
```

## 📁 Project Structure

```
nginx-f1/
├── Dockerfile                    # Main Docker image definition
├── README.md                     # This documentation
├── docker-entrypoint.sh          # Container entrypoint script
├── nginx-logrotate.conf          # Logrotate configuration
├── supervisord.conf              # Supervisord configuration
├── logrotate-manager.sh          # Logrotate management script
├── logrotate-daemon.sh           # Daemon-based logrotate script
├── disk-cleanup.sh               # Disk space cleanup daemon
├── nginx-reloader.sh             # Configuration reloader script
├── example/                      # Comprehensive examples
│   ├── README.md                 # Example documentation
│   ├── docker-compose.yml        # Complete Docker Compose setup
│   ├── nginx-with-logrotate.conf # Enhanced nginx configuration
│   ├── logrotate.env             # Environment configuration template
│   └── html/                     # Sample web content
└── example-simple/               # Basic examples
    └── nginx.conf                # Simple nginx configuration
```

## 🔧 Troubleshooting

### Common Issues

| Issue                        | Solution                                                                 |
|------------------------------|--------------------------------------------------------------------------|
| **Container won't start**    | Check nginx configuration: `docker exec nginx-f1 nginx -t`               |
| **Log rotation not working** | Verify `LOGROTATE_METHOD` and check logs: `docker logs nginx-f1`         |
| **Remote transfer failing**  | Check SSH keys and connectivity: `docker exec nginx-f1 ssh -T user@host` |
| **Permission denied**        | Ensure proper file permissions and ownership                             |
| **High memory usage**        | Consider using `LOGROTATE_METHOD=daemon` for lightweight deployments     |
| **Disk full / logs growing** | Enable `ENABLE_DISK_CLEANUP=true` with appropriate thresholds            |
| **Constant nginx reloads**   | Check reloader log: `tail -f /var/log/nginx/reloader.log`                |

### Debug Commands

```bash
# Check container logs
docker logs nginx-f1

# Check nginx configuration
docker exec nginx-f1 nginx -t

# Check logrotate configuration
docker exec nginx-f1 cat /etc/logrotate.d/nginx

# Check process status
docker exec nginx-f1 ps aux

# Check disk usage
docker exec nginx-f1 df -h

# Check disk cleanup status
docker exec nginx-f1 supervisorctl status disk-cleanup
docker exec nginx-f1 tail -f /var/log/nginx/disk-cleanup.log

# Monitor log files
docker exec nginx-f1 tail -f /var/log/nginx/error.log
```

## 📚 Additional Resources

- **Example Configurations**: See `example/` directory for complete setups
- **Nginx Documentation**: [nginx.org](https://nginx.org/en/docs/)
- **Docker Best Practices**: [docs.docker.com](https://docs.docker.com/develop/best-practices/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is open source. Please check the license file for details.

---

**Ready to deploy?** Start with the [Quick Start](#-quick-start) section above! 🚀
