#!/bin/bash
# script to watch changes in WATCH_DIR and reload nginx on .conf file changes

export WATCH_DIR=${WATCH_DIR:-/etc/nginx}
export RELOADER_LOG=${RELOADER_LOG:-/var/log/nginx/reloader.log}

log() {
 local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
 echo "$msg"
 echo "$msg" >> "${RELOADER_LOG}"
}

log "Starting nginx-reloader, watching: ${WATCH_DIR} for *.conf files"

while true
do
 FILE=$(inotifywait --recursive --format '%f' -e create -e modify -e delete -e move "${WATCH_DIR}" 2>/dev/null)

 if [[ "${FILE}" == *.conf ]]; then
  log "Detected change in: ${FILE}"
  nginx -t
  if [[ $? -eq 0 ]]; then
   log "Config valid, executing: nginx -s reload"
   nginx -s reload
  else
   log "Config test failed, skipping reload"
  fi
 else
  log "Ignored non-conf file: ${FILE}"
 fi
done
