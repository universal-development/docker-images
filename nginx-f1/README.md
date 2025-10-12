# nginx-f1

Container image for nginx f1 project with advanced logrotate capabilities

Basic nginx setup for handling requests, generating statistics, and automatic log rotation with remote archiving support.

## Features

- **Nginx with PageSpeed**: Optimized nginx with Google PageSpeed module
- **Automatic Log Rotation**: Configurable logrotate with archiving and remote transfer
- **Remote Log Archiving**: Support for SCP, RSYNC, and S3 remote storage
- **Health Monitoring**: Upstream health checks and traffic statistics
- **Configuration Reloading**: Automatic nginx reload on configuration changes

## Important Modules

- nginx_upstream_check_module (https://github.com/yaoweibin/nginx_upstream_check_module)
- nginx-module-stream-sts (https://github.com/vozlt/nginx-module-stream-sts)
- Google PageSpeed module
- VTS (Virtual Host Traffic Status) module
- Various caching and optimization modules

## Logrotate Configuration

The image includes comprehensive logrotate functionality that can be configured via environment variables:

### Basic Usage

```bash
# Run with default logrotate settings
docker run -p 8181:80 denis256/nginx-f1:latest

# Run with custom logrotate configuration
docker run -p 8181:80 \
  -e ENABLE_LOGROTATE=true \
  -e LOGROTATE_FREQUENCY=daily \
  -e LOGROTATE_KEEP_DAYS=30 \
  denis256/nginx-f1:latest
```

### Advanced Logrotate with Remote Archiving

```bash
# SCP remote archiving
docker run -p 8181:80 \
  -e LOGROTATE_ENABLE_REMOTE=true \
  -e LOGROTATE_REMOTE_METHOD=scp \
  -e LOGROTATE_REMOTE_HOST=backup.example.com \
  -e LOGROTATE_REMOTE_USER=nginx-logs \
  -e LOGROTATE_REMOTE_PATH=/var/log/nginx-archive \
  -v /path/to/ssh/key:/root/.ssh/id_rsa:ro \
  denis256/nginx-f1:latest

# S3 remote archiving
docker run -p 8181:80 \
  -e LOGROTATE_ENABLE_REMOTE=true \
  -e LOGROTATE_REMOTE_METHOD=s3 \
  -e LOGROTATE_S3_BUCKET=my-nginx-logs \
  -e LOGROTATE_AWS_ACCESS_KEY_ID=your-key \
  -e LOGROTATE_AWS_SECRET_ACCESS_KEY=your-secret \
  denis256/nginx-f1:latest
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ENABLE_LOGROTATE` | `true` | Enable/disable logrotate functionality |
| `LOGROTATE_METHOD` | `supervisord` | Logrotate method (supervisord, daemon, cron, disabled) |
| `LOGROTATE_FREQUENCY` | `daily` | Rotation frequency (daily, weekly, monthly) |
| `LOGROTATE_KEEP_DAYS` | `30` | Number of rotated logs to keep |
| `LOGROTATE_ENABLE_ARCHIVE` | `true` | Enable local archiving |
| `LOGROTATE_ARCHIVE_DIR` | `/var/log/nginx/archive` | Local archive directory |
| `LOGROTATE_ENABLE_REMOTE` | `false` | Enable remote transfer |
| `LOGROTATE_REMOTE_METHOD` | `scp` | Remote method (scp, rsync, s3) |
| `LOGROTATE_COMPRESS_ARCHIVE` | `true` | Compress archived logs |
| `LOGROTATE_CLEANUP_AFTER_REMOTE` | `false` | Clean local archives after remote transfer |
| `LOGROTATE_INTERVAL` | `86400` | Interval in seconds for daemon method (24 hours) |

### Logrotate Methods

The image supports multiple ways to run logrotate:

#### 1. Supervisord (Default - Recommended)
- **Method**: `LOGROTATE_METHOD=supervisord`
- **Pros**: Process management, automatic restart, logging
- **Cons**: Requires supervisord package
- **Best for**: Production environments

```bash
docker run -e LOGROTATE_METHOD=supervisord denis256/nginx-f1:latest
```

#### 2. Daemon Script
- **Method**: `LOGROTATE_METHOD=daemon`
- **Pros**: Lightweight, no additional packages
- **Cons**: Simple process management
- **Best for**: Lightweight deployments

```bash
docker run -e LOGROTATE_METHOD=daemon denis256/nginx-f1:latest
```

#### 3. Cron-based
- **Method**: `LOGROTATE_METHOD=cron`
- **Pros**: Standard cron scheduling
- **Cons**: May not restart if cron fails
- **Best for**: Traditional Unix environments

```bash
docker run -e LOGROTATE_METHOD=cron denis256/nginx-f1:latest
```

#### 4. Disabled
- **Method**: `LOGROTATE_METHOD=disabled` or `ENABLE_LOGROTATE=false`
- **Use case**: When you want to handle log rotation externally

```bash
docker run -e LOGROTATE_METHOD=disabled denis256/nginx-f1:latest
```

### Remote Transfer Methods

#### SCP
```bash
LOGROTATE_REMOTE_HOST=backup.example.com
LOGROTATE_REMOTE_USER=nginx-logs
LOGROTATE_REMOTE_PATH=/var/log/nginx-archive
LOGROTATE_SSH_KEY_PATH=/root/.ssh/id_rsa
LOGROTATE_SSH_PORT=22
```

#### RSYNC
```bash
LOGROTATE_REMOTE_METHOD=rsync
LOGROTATE_REMOTE_HOST=backup.example.com
LOGROTATE_REMOTE_USER=nginx-logs
LOGROTATE_REMOTE_PATH=/var/log/nginx-archive
```

#### S3
```bash
LOGROTATE_REMOTE_METHOD=s3
LOGROTATE_S3_BUCKET=my-nginx-logs
LOGROTATE_AWS_ACCESS_KEY_ID=your-key
LOGROTATE_AWS_SECRET_ACCESS_KEY=your-secret
LOGROTATE_AWS_DEFAULT_REGION=us-east-1
LOGROTATE_S3_PREFIX=nginx-logs
```

## Examples

### Basic Usage
```bash
docker run -p 8181:80 denis256/nginx-f1:latest

docker run -v $(pwd)/example-simple/nginx.conf:/etc/nginx/nginx.conf -p 8080:8080 -p 9090:9090 denis256/nginx-f1:latest

docker run -v $(pwd)/example/nginx.conf:/etc/nginx/nginx.conf -p 8080:8080 -p 9090:9090 denis256/nginx-f1:latest
```

### With Logrotate Configuration
```bash
# Use the example configuration with logrotate
docker run -v $(pwd)/example/nginx-with-logrotate.conf:/etc/nginx/nginx.conf \
  -v $(pwd)/example/logrotate.env:/etc/nginx/logrotate.env \
  --env-file $(pwd)/example/logrotate.env \
  -p 8080:8080 -p 9090:9090 denis256/nginx-f1:latest
```

### Docker Compose Example
```yaml
version: '3.8'
services:
  nginx:
    image: denis256/nginx-f1:latest
    ports:
      - "80:80"
      - "8080:8080"
      - "9090:9090"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./logs:/var/log/nginx
      - ./ssh-keys:/root/.ssh:ro
    environment:
      - ENABLE_LOGROTATE=true
      - LOGROTATE_ENABLE_REMOTE=true
      - LOGROTATE_REMOTE_METHOD=scp
      - LOGROTATE_REMOTE_HOST=backup.example.com
      - LOGROTATE_REMOTE_USER=nginx-logs
      - LOGROTATE_REMOTE_PATH=/var/log/nginx-archive
```

## Monitoring Endpoints

- **Upstream status check**: http://0.0.0.0:9090/status
- **Upstream health check**: http://0.0.0.0:9090/upstream-status
- **Client access**: http://0.0.0.0:9091

## Log Files

With logrotate enabled, logs are stored in:
- `/var/log/nginx/access.log` - Main access log
- `/var/log/nginx/error.log` - Main error log
- `/var/log/nginx/archive/` - Archived rotated logs
- `/var/log/nginx/logrotate-manager.log` - Logrotate manager logs
- `/var/log/nginx/logrotate-cron.log` - Cron job logs

## Manual Log Rotation

You can manually trigger log rotation:
```bash
# Inside the container
logrotate -f /etc/logrotate.d/nginx

# Or use the manager script
/usr/bin/logrotate-manager.sh postrotate
```

## Logrotate Implementation Details

### Process Management Solutions

The logrotate implementation addresses the critical challenge of running logrotate in a Docker container where nginx is typically the main process (PID 1). Four different approaches are provided:

#### 1. Supervisord Method (Default - Recommended)
- **How it works**: Supervisord becomes PID 1 and manages all processes (nginx, cron, nginx-reloader)
- **Benefits**: Process supervision, automatic restart, centralized logging, production-grade reliability
- **Best for**: Production environments
- **Resource usage**: Medium

#### 2. Daemon Script Method (Lightweight)
- **How it works**: Nginx is PID 1, logrotate runs as background daemon with sleep loop
- **Benefits**: Lightweight, no additional packages, configurable interval
- **Best for**: Development/lightweight deployments
- **Resource usage**: Low

#### 3. Cron Method (Traditional)
- **How it works**: Nginx is PID 1, cron runs as background service
- **Benefits**: Standard Unix approach, precise scheduling, familiar to sysadmins
- **Limitations**: Less reliable, no automatic restart if cron crashes
- **Best for**: Traditional Unix environments
- **Resource usage**: Low

#### 4. Disabled Method
- **How it works**: Only nginx runs, no logrotate
- **Use cases**: External log rotation, testing environments, custom log handling

### Process Comparison

| Method | Reliability | Resource Usage | Complexity | Restart on Failure |
|--------|-------------|----------------|------------|-------------------|
| **supervisord** | ⭐⭐⭐⭐⭐ | Medium | Medium | ✅ Yes |
| **daemon** | ⭐⭐⭐⭐ | Low | Low | ⚠️ Limited |
| **cron** | ⭐⭐⭐ | Low | Low | ❌ No |
| **disabled** | N/A | Lowest | Lowest | N/A |

### Implementation Files

The logrotate functionality is implemented through several key files:

- **`nginx-logrotate.conf`**: Logrotate configuration with environment variable support
- **`logrotate-manager.sh`**: Management script with remote transfer capabilities (SCP, RSYNC, S3)
- **`docker-entrypoint.sh`**: Enhanced entrypoint with logrotate setup and method selection
- **`supervisord.conf`**: Process management configuration for supervisord method
- **`logrotate-daemon.sh`**: Daemon script for lightweight method

### Key Features

1. **Automatic Log Rotation**: Daily rotation by default with configurable frequency and retention
2. **Local Archiving**: Organized storage in `/var/log/nginx/archive` with optional compression
3. **Remote Transfer**: Support for SCP, RSYNC, and S3 with SSH key authentication
4. **Configuration Management**: Environment variable driven configuration with runtime updates
5. **Comprehensive Logging**: All operations logged with timestamps and detailed status

### Benefits

- **Automated Log Management**: No manual intervention required
- **Flexible Configuration**: Easy customization via environment variables
- **Multiple Remote Options**: Choose the best storage method for your infrastructure
- **Production Ready**: Comprehensive error handling and logging
- **Resource Efficient**: Configurable compression and cleanup options
- **Security**: SSH key authentication for remote transfers

### Monitoring

- Logrotate operations are logged to `/var/log/nginx/logrotate-manager.log`
- Cron job execution logged to `/var/log/nginx/logrotate-cron.log`
- Supervisord logs available in `/var/log/supervisor/`
- All operations include timestamps and detailed status information
