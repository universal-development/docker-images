# Nginx Logrotate Implementation Summary

## Overview

This implementation adds comprehensive logrotate functionality to the nginx-f1 Docker image, enabling automatic log rotation, archiving, and remote transfer capabilities.

## Files Added/Modified

### 1. Dockerfile
- **Added packages**: `logrotate` and `cron`
- **Modified log handling**: Removed stdout/stderr redirection, created proper log files
- **Added archive directory**: `/var/log/nginx/archive` for storing rotated logs
- **Added script copies**: logrotate configuration and management script

### 2. nginx-logrotate.conf
- **Location**: `/etc/logrotate.d/nginx` in container
- **Features**: 
  - Configurable rotation frequency via environment variables
  - Automatic nginx reload after rotation (USR1 signal)
  - Compression and archiving support
  - Post-rotation script execution for remote transfer

### 3. logrotate-manager.sh
- **Location**: `/usr/bin/logrotate-manager.sh` in container
- **Features**:
  - Configurable via environment variables
  - Multiple remote transfer methods (SCP, RSYNC, S3)
  - Local archiving with compression
  - Comprehensive logging and error handling
  - Dynamic logrotate configuration generation

### 4. docker-entrypoint.sh
- **Enhanced with**:
  - Logrotate cron job setup
  - Directory and permission management
  - Dynamic configuration application

### 5. Example Files
- **nginx-with-logrotate.conf**: Example nginx configuration with proper log file paths
- **logrotate.env**: Environment variable configuration template
- **docker-compose.yml**: Complete Docker Compose setup with logrotate

### 6. README.md
- **Updated with**:
  - Comprehensive logrotate documentation
  - Environment variable reference
  - Usage examples for all remote transfer methods
  - Docker Compose examples

## Key Features

### 1. Automatic Log Rotation
- Daily rotation by default (configurable)
- Configurable retention period
- Compression of rotated logs
- Proper nginx reload handling

### 2. Local Archiving
- Organized storage in `/var/log/nginx/archive`
- Optional compression of archive files
- Configurable archive directory

### 3. Remote Transfer
- **SCP**: Secure copy with SSH key authentication
- **RSYNC**: Efficient synchronization
- **S3**: Cloud storage integration with AWS CLI

### 4. Configuration Management
- Environment variable driven configuration
- Runtime configuration updates
- Comprehensive logging of all operations

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ENABLE_LOGROTATE` | `true` | Enable/disable logrotate |
| `LOGROTATE_FREQUENCY` | `daily` | Rotation frequency |
| `LOGROTATE_KEEP_DAYS` | `30` | Retention period |
| `LOGROTATE_ENABLE_ARCHIVE` | `true` | Enable local archiving |
| `LOGROTATE_ENABLE_REMOTE` | `false` | Enable remote transfer |
| `LOGROTATE_REMOTE_METHOD` | `scp` | Remote method (scp/rsync/s3) |
| `LOGROTATE_COMPRESS_ARCHIVE` | `true` | Compress archives |

## Usage Examples

### Basic Usage
```bash
docker run -p 80:80 denis256/nginx-f1:latest
```

### With Remote SCP Archiving
```bash
docker run -p 80:80 \
  -e LOGROTATE_ENABLE_REMOTE=true \
  -e LOGROTATE_REMOTE_METHOD=scp \
  -e LOGROTATE_REMOTE_HOST=backup.example.com \
  -e LOGROTATE_REMOTE_USER=nginx-logs \
  -v /path/to/ssh/key:/root/.ssh/id_rsa:ro \
  denis256/nginx-f1:latest
```

### With S3 Archiving
```bash
docker run -p 80:80 \
  -e LOGROTATE_ENABLE_REMOTE=true \
  -e LOGROTATE_REMOTE_METHOD=s3 \
  -e LOGROTATE_S3_BUCKET=my-nginx-logs \
  -e LOGROTATE_AWS_ACCESS_KEY_ID=your-key \
  -e LOGROTATE_AWS_SECRET_ACCESS_KEY=your-secret \
  denis256/nginx-f1:latest
```

## Benefits

1. **Automated Log Management**: No manual intervention required
2. **Flexible Configuration**: Easy customization via environment variables
3. **Multiple Remote Options**: Choose the best storage method for your infrastructure
4. **Production Ready**: Comprehensive error handling and logging
5. **Resource Efficient**: Configurable compression and cleanup options
6. **Security**: SSH key authentication for remote transfers

## Monitoring

- Logrotate operations are logged to `/var/log/nginx/logrotate-manager.log`
- Cron job execution logged to `/var/log/nginx/logrotate-cron.log`
- All operations include timestamps and detailed status information

This implementation provides a robust, production-ready log rotation solution that integrates seamlessly with the existing nginx-f1 Docker image.

