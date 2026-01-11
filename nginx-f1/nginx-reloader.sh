#!/bin/bash
set -uo pipefail

# script to watch changes in WATCH_DIR and reload nginx on .conf file changes

WATCH_DIR="${WATCH_DIR:-/etc/nginx}"
RELOADER_LOG="${RELOADER_LOG:-/var/log/nginx/reloader.log}"
RELOADER_DELAY="${RELOADER_DELAY:-2}"
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
command -v inotifywait >/dev/null 2>&1 || error_exit "inotifywait not found, install inotify-tools"
command -v nginx >/dev/null 2>&1 || error_exit "nginx not found"
[[ -d "${WATCH_DIR}" ]] || error_exit "WATCH_DIR does not exist: ${WATCH_DIR}"

# ensure log directory exists
LOG_DIR=$(dirname "${RELOADER_LOG}")
[[ -d "${LOG_DIR}" ]] || mkdir -p "${LOG_DIR}"

# compute initial hash
LAST_HASH=$(compute_hash)

log "Starting nginx-reloader v3"
log "Config: WATCH_DIR=${WATCH_DIR} DELAY=${RELOADER_DELAY}s"
log "Initial config hash: ${LAST_HASH}"

while true
do
 sleep "${RELOADER_DELAY}"

 # wait for any file event in watch dir
 inotifywait --recursive --format '%w%f' \
   -e create -e modify -e delete -e move \
   "${WATCH_DIR}" >/dev/null 2>&1 || true

 # compute new hash of all .conf files
 NEW_HASH=$(compute_hash)

 # skip if hash unchanged
 if [[ "${NEW_HASH}" == "${LAST_HASH}" ]]; then
  continue
 fi

 log "Config changed: ${LAST_HASH} -> ${NEW_HASH}"
 LAST_HASH="${NEW_HASH}"

 # test nginx config
 if nginx -t 2>/dev/null; then
  log "Config valid, reloading nginx"
  nginx -s reload 2>/dev/null || log "Reload command failed"
 else
  log "Config test failed, skipping reload"
 fi
done
