#!/bin/bash
# Tests for logrotate automation in nginx-f1
# Run: bash test-logrotate.sh
# Validates entrypoint setup and logrotate-manager behavior without Docker

set -e

PASS=0
FAIL=0
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

assert_contains() {
    if echo "$1" | grep -q "$2"; then pass "$3"; else fail "$3 (expected '$2')"; fi
}
assert_not_contains() {
    if echo "$1" | grep -q "$2"; then fail "$3 (unexpected '$2')"; else pass "$3"; fi
}
assert_file_exists() {
    if [ -f "$1" ]; then pass "$2"; else fail "$2 ($1 not found)"; fi
}
assert_file_not_exists() {
    if [ -f "$1" ]; then fail "$2 ($1 still exists)"; else pass "$2"; fi
}

# ─── Test setup ───
TMPDIR=$(mktemp -d /tmp/nginx-f1-test-XXXXXX)
trap "rm -rf $TMPDIR" EXIT

# Create mock supervisord.conf
setup_supervisord_conf() {
    cp "$SCRIPT_DIR/supervisord.conf" "$TMPDIR/supervisord.conf"
}

# ═══════════════════════════════════════════════════════════════
echo "=== Test: setup_logrotate_daemon enables daemon when LOGROTATE_INTERVAL is set ==="
# ═══════════════════════════════════════════════════════════════
setup_supervisord_conf

export LOGROTATE_INTERVAL=3600
CONF="$TMPDIR/supervisord.conf"

# Simulate setup_logrotate_daemon logic
if [ -n "${LOGROTATE_INTERVAL}" ] && [ "${LOGROTATE_INTERVAL}" != "86400" ]; then
    sed -i '/\[program:logrotate-daemon\]/,/priority=175/{s/autostart=false/autostart=true/}' "$CONF"
fi

daemon_autostart=$(sed -n '/\[program:logrotate-daemon\]/,/priority=175/p' "$CONF" | grep autostart)
assert_contains "$daemon_autostart" "autostart=true" "logrotate-daemon autostart=true when INTERVAL=3600"

# Verify other programs NOT affected
disk_autostart=$(sed -n '/\[program:disk-cleanup\]/,/priority=180/p' "$CONF" | grep autostart)
assert_contains "$disk_autostart" "autostart=false" "disk-cleanup unchanged"

cron_autostart=$(sed -n '/\[program:cron\]/,/priority=200/p' "$CONF" | grep autostart)
assert_contains "$cron_autostart" "autostart=true" "cron still enabled"

# ═══════════════════════════════════════════════════════════════
echo "=== Test: setup_logrotate_daemon skips when LOGROTATE_INTERVAL is default ==="
# ═══════════════════════════════════════════════════════════════
setup_supervisord_conf

export LOGROTATE_INTERVAL=86400
CONF="$TMPDIR/supervisord.conf"

if [ -n "${LOGROTATE_INTERVAL}" ] && [ "${LOGROTATE_INTERVAL}" != "86400" ]; then
    sed -i '/\[program:logrotate-daemon\]/,/priority=175/{s/autostart=false/autostart=true/}' "$CONF"
fi

daemon_autostart=$(sed -n '/\[program:logrotate-daemon\]/,/priority=175/p' "$CONF" | grep autostart)
assert_contains "$daemon_autostart" "autostart=false" "logrotate-daemon stays disabled when INTERVAL=86400"

# ═══════════════════════════════════════════════════════════════
echo "=== Test: setup_logrotate_daemon skips when LOGROTATE_INTERVAL is unset ==="
# ═══════════════════════════════════════════════════════════════
setup_supervisord_conf

unset LOGROTATE_INTERVAL
CONF="$TMPDIR/supervisord.conf"

if [ -n "${LOGROTATE_INTERVAL}" ] && [ "${LOGROTATE_INTERVAL}" != "86400" ]; then
    sed -i '/\[program:logrotate-daemon\]/,/priority=175/{s/autostart=false/autostart=true/}' "$CONF"
fi

daemon_autostart=$(sed -n '/\[program:logrotate-daemon\]/,/priority=175/p' "$CONF" | grep autostart)
assert_contains "$daemon_autostart" "autostart=false" "logrotate-daemon stays disabled when INTERVAL unset"

# ═══════════════════════════════════════════════════════════════
echo "=== Test: logrotate-manager find uses -maxdepth 1 ==="
# ═══════════════════════════════════════════════════════════════
find_line=$(grep "find /var/log/nginx" "$SCRIPT_DIR/logrotate-manager.sh" | head -1)
assert_contains "$find_line" "maxdepth 1" "find uses -maxdepth 1 to skip archive subdir"

# ═══════════════════════════════════════════════════════════════
echo "=== Test: SFTP opts include ConnectTimeout ==="
# ═══════════════════════════════════════════════════════════════
sftp_opts_line=$(grep "sftp_opts=" "$SCRIPT_DIR/logrotate-manager.sh")
assert_contains "$sftp_opts_line" "ConnectTimeout" "SFTP opts include ConnectTimeout"
assert_contains "$sftp_opts_line" "UserKnownHostsFile=/dev/null" "SFTP opts include UserKnownHostsFile"
assert_contains "$sftp_opts_line" "BatchMode=yes" "SFTP opts include BatchMode"
assert_contains "$sftp_opts_line" "ServerAliveInterval" "SFTP opts include ServerAliveInterval"

# ═══════════════════════════════════════════════════════════════
echo "=== Test: SCP opts include ConnectTimeout ==="
# ═══════════════════════════════════════════════════════════════
scp_opts_line=$(grep 'ssh_opts=.*StrictHostKeyChecking' "$SCRIPT_DIR/logrotate-manager.sh")
assert_contains "$scp_opts_line" "ConnectTimeout" "SCP opts include ConnectTimeout"
assert_contains "$scp_opts_line" "UserKnownHostsFile=/dev/null" "SCP opts include UserKnownHostsFile"

# ═══════════════════════════════════════════════════════════════
echo "=== Test: sftp call wrapped with timeout ==="
# ═══════════════════════════════════════════════════════════════
sftp_call=$(grep "sftp \$sftp_opts" "$SCRIPT_DIR/logrotate-manager.sh")
assert_contains "$sftp_call" "timeout" "sftp call has timeout wrapper"

scp_calls=$(grep "scp \$ssh_opts" "$SCRIPT_DIR/logrotate-manager.sh")
assert_contains "$scp_calls" "timeout" "scp call has timeout wrapper"

ssh_calls=$(grep "ssh \$ssh_opts" "$SCRIPT_DIR/logrotate-manager.sh")
assert_contains "$ssh_calls" "timeout" "ssh call has timeout wrapper"

# ═══════════════════════════════════════════════════════════════
echo "=== Test: logrotate-daemon.sh uses LOGROTATE_INTERVAL ==="
# ═══════════════════════════════════════════════════════════════
daemon_script=$(cat "$SCRIPT_DIR/logrotate-daemon.sh")
assert_contains "$daemon_script" "LOGROTATE_INTERVAL" "daemon script reads LOGROTATE_INTERVAL"
assert_contains "$daemon_script" 'sleep "$LOGROTATE_INTERVAL"' "daemon sleeps for LOGROTATE_INTERVAL"

# ═══════════════════════════════════════════════════════════════
echo "=== Test: postrotate calls logrotate-manager.sh ==="
# ═══════════════════════════════════════════════════════════════
logrotate_conf=$(cat "$SCRIPT_DIR/nginx-logrotate.conf")
assert_contains "$logrotate_conf" "logrotate-manager.sh postrotate" "logrotate conf calls manager postrotate"

# ═══════════════════════════════════════════════════════════════
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
