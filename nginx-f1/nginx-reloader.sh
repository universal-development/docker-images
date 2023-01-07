#!/bin/bash
# script to watch changes in WATCH_DIR and reload nginx

export WATCH_DIR=${WATCH_DIR:-/tmp/nginx-reloader}

while true
do
 inotifywait --exclude .swp -e create -e modify -e delete -e move "${WATCH_DIR}"
 nginx -t
 if [[ $? -eq 0 ]]; then
  echo "Detected Nginx Configuration Change"
  echo "Executing: nginx -s reload"
  nginx -s reload
 fi
done