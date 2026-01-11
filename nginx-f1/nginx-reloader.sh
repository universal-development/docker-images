#!/bin/bash
set -uo pipefail

# script to poll WATCH_DIR for .conf file changes and reload nginx

WATCH_DIR="${WATCH_DIR:-/etc/nginx}"
RELOADER_LOG="${RELOADER_LOG:-/var/log/nginx/reloader.log}"
RELOADER_INTERVAL="${RELOADER_INTERVAL:-5}"
LAST_HASH=""

log() {
 local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
 echo "$msg"
 echo "$msg" >> "${RELOADER_LOG}" 2>/dev/null || true
}

error_exit() {
 log "ERROR: $1"
 exit 1
}

# compute hash of all .conf files
compute_hash() {
 find "${WATCH_DIR}" -name '*.conf' -type f -exec md5sum {} \; 2>/dev/null | sort | md5sum | awk '{print $1}'
}

# pre-flight checks
command -v nginx >/dev/null 2>&1 || error_exit "nginx not found"
[[ -d "${WATCH_DIR}" ]] || error_exit "WATCH_DIR does not exist: ${WATCH_DIR}"

# ensure log directory exists
LOG_DIR=$(dirname "${RELOADER_LOG}")
[[ -d "${LOG_DIR}" ]] || mkdir -p "${LOG_DIR}"

# compute initial hash
LAST_HASH=$(compute_hash)

log "Starting nginx-reloader v4"
log "Config: WATCH_DIR=${WATCH_DIR} INTERVAL=${RELOADER_INTERVAL}s"
log "Initial hash: ${LAST_HASH}"

while true
do
 sleep "${RELOADER_INTERVAL}"

 NEW_HASH=$(compute_hash)
 log "Scan: hash=${NEW_HASH}"

 [[ "${NEW_HASH}" == "${LAST_HASH}" ]] && continue

 log "Config changed: ${LAST_HASH} -> ${NEW_HASH}"
 LAST_HASH="${NEW_HASH}"

 TEST_OUTPUT=$(nginx -t 2>&1)
 if [[ $? -eq 0 ]]; then
  log "Config valid, reloading nginx"
  nginx -s reload 2>/dev/null || log "Reload failed"
 else
  log "Config test failed, skipping reload"
  log "Error: ${TEST_OUTPUT}"
 fi
done
