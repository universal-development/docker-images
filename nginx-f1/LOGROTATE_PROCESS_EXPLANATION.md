# Logrotate Process Management Explanation

## The Problem You Identified

You were absolutely correct to question how logrotate would run! The original implementation had a critical flaw:

### ❌ **Original Issue:**
```bash
# In docker-entrypoint.sh
service cron start          # Start cron
exec nginx -g "daemon off;" # nginx becomes PID 1
# If nginx dies, container stops, cron dies too!
```

**Problems:**
1. **Cron runs as background service** but nginx is the main process (PID 1)
2. **When nginx exits, the container stops** - killing cron with it
3. **No process supervision** - if cron crashes, it won't restart
4. **No logging** - hard to debug cron issues

## ✅ **Solutions Implemented**

I've implemented **4 different approaches** to solve this problem:

### 1. **Supervisord Method (Default - Recommended)**

**How it works:**
```bash
# supervisord becomes PID 1 and manages all processes
/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
├── nginx (managed by supervisord)
├── cron (managed by supervisord) 
└── nginx-reloader (managed by supervisord)
```

**Benefits:**
- ✅ **Process supervision** - all processes are monitored and restarted if they crash
- ✅ **Centralized logging** - all process logs in `/var/log/supervisor/`
- ✅ **Reliable** - production-grade process management
- ✅ **Easy monitoring** - can check status of all processes

**Usage:**
```bash
docker run -e LOGROTATE_METHOD=supervisord denis256/nginx-f1:latest
```

### 2. **Daemon Script Method (Lightweight)**

**How it works:**
```bash
# nginx is PID 1, but logrotate runs as background daemon
nginx -g "daemon off;" &
logrotate-daemon.sh &     # Runs logrotate every 24 hours
nginx-reloader.sh &       # Watches for config changes
```

**Benefits:**
- ✅ **Lightweight** - no additional packages like supervisord
- ✅ **Simple** - just a bash script with sleep loop
- ✅ **Configurable interval** - via `LOGROTATE_INTERVAL` (default 24h)

**Usage:**
```bash
docker run -e LOGROTATE_METHOD=daemon denis256/nginx-f1:latest
```

### 3. **Cron Method (Traditional)**

**How it works:**
```bash
# nginx is PID 1, cron runs as background service
service cron start        # Start cron daemon
nginx -g "daemon off;" &  # nginx runs in background
nginx-reloader.sh &       # Config watcher
```

**Benefits:**
- ✅ **Standard Unix approach** - familiar to sysadmins
- ✅ **Precise scheduling** - uses standard cron expressions
- ✅ **No additional packages** - just cron (already installed)

**Limitations:**
- ⚠️ **Less reliable** - if cron crashes, it won't restart automatically

**Usage:**
```bash
docker run -e LOGROTATE_METHOD=cron denis256/nginx-f1:latest
```

### 4. **Disabled Method**

**How it works:**
```bash
# Only nginx runs, no logrotate
nginx -g "daemon off;" &
nginx-reloader.sh &       # Just config watching
```

**Use cases:**
- External log rotation (host-based or external tool)
- Testing environments
- When you handle logs differently

**Usage:**
```bash
docker run -e LOGROTATE_METHOD=disabled denis256/nginx-f1:latest
```

## 🔧 **Configuration Examples**

### Production Setup (Recommended)
```bash
docker run -p 80:80 \
  -e LOGROTATE_METHOD=supervisord \
  -e LOGROTATE_ENABLE_REMOTE=true \
  -e LOGROTATE_REMOTE_METHOD=s3 \
  -e LOGROTATE_S3_BUCKET=my-logs \
  denis256/nginx-f1:latest
```

### Lightweight Setup
```bash
docker run -p 80:80 \
  -e LOGROTATE_METHOD=daemon \
  -e LOGROTATE_INTERVAL=43200 \
  denis256/nginx-f1:latest
```

### Traditional Setup
```bash
docker run -p 80:80 \
  -e LOGROTATE_METHOD=cron \
  -e LOGROTATE_FREQUENCY=daily \
  denis256/nginx-f1:latest
```

## 📊 **Process Comparison**

| Method | Reliability | Resource Usage | Complexity | Restart on Failure |
|--------|-------------|----------------|------------|-------------------|
| **supervisord** | ⭐⭐⭐⭐⭐ | Medium | Medium | ✅ Yes |
| **daemon** | ⭐⭐⭐⭐ | Low | Low | ⚠️ Limited |
| **cron** | ⭐⭐⭐ | Low | Low | ❌ No |
| **disabled** | N/A | Lowest | Lowest | N/A |

## 🚀 **Recommendation**

**For Production:** Use `supervisord` method
- Most reliable and feature-complete
- Automatic process restart
- Comprehensive logging
- Easy monitoring and debugging

**For Development/Lightweight:** Use `daemon` method
- Minimal resource usage
- Simple and straightforward
- Easy to understand and debug

**For Traditional Environments:** Use `cron` method
- Familiar to Unix/Linux administrators
- Standard scheduling approach
- No additional dependencies

The key insight is that **process management in Docker containers is critical** - you can't just start background services and expect them to survive container lifecycle events. The solutions I've implemented ensure that logrotate will continue running regardless of how nginx behaves.

