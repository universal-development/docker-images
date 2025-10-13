#!/bin/bash
# script to watch changes in WATCH_DIR and reload nginx

export WATCH_DIR=${WATCH_DIR:-/etc/nginx}

echo "[nginx-reloader] Watching directory: ${WATCH_DIR}" >&2

EXCLUDES='.*\\.swp$|.*\\.log$|.*\\.tar\\.gz$'

while true
do
 inotifywait --recursive --exclude "${EXCLUDES}" -e create -e modify -e delete -e move "${WATCH_DIR}"
 nginx -t
 if [[ $? -eq 0 ]]; then
  echo "Detected Nginx Configuration Change"
  echo "Executing: nginx -s reload"
  nginx -s reload
 fi
done
