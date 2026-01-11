#!/bin/bash
# script to watch changes in WATCH_DIR and reload nginx on .conf file changes

export WATCH_DIR=${WATCH_DIR:-/etc/nginx}

echo "[nginx-reloader] Watching directory: ${WATCH_DIR} for *.conf files" >&2

while true
do
 FILE=$(inotifywait --recursive --format '%f' -e create -e modify -e delete -e move "${WATCH_DIR}" 2>/dev/null)

 if [[ "${FILE}" == *.conf ]]; then
  echo "[nginx-reloader] Detected change in: ${FILE}"
  nginx -t
  if [[ $? -eq 0 ]]; then
   echo "[nginx-reloader] Config valid, executing: nginx -s reload"
   nginx -s reload
  else
   echo "[nginx-reloader] Config test failed, skipping reload"
  fi
 fi
done
