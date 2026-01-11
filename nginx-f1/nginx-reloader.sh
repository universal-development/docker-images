#!/bin/bash
# script to watch changes in WATCH_DIR and reload nginx on .conf file changes

export WATCH_DIR=${WATCH_DIR:-/etc/nginx}
export RELOADER_LOG=${RELOADER_LOG:-/var/log/nginx/reloader.log}
export RELOADER_DELAY=${RELOADER_DELAY:-2}

log() {
 local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
 echo "$msg"
 echo "$msg" >> "${RELOADER_LOG}"
}

log "Starting nginx-reloader, watching: ${WATCH_DIR} for *.conf files (delay: ${RELOADER_DELAY}s)"

while true
do
 sleep "${RELOADER_DELAY}"
 FILE=$(inotifywait --recursive --include '\.conf$' --format '%f' -e create -e modify -e delete -e move "${WATCH_DIR}" 2>/dev/null)
 log "Detected: ${FILE}"
 nginx -t
 if [[ $? -eq 0 ]]; then
  log "Config valid, reloading nginx"
  nginx -s reload
 else
  log "Config test failed, skipping reload"
 fi
done
