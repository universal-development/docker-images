#!/bin/bash
set -euo pipefail

# script to watch changes in WATCH_DIR and reload nginx on .conf file changes

WATCH_DIR="${WATCH_DIR:-/etc/nginx}"
RELOADER_LOG="${RELOADER_LOG:-/var/log/nginx/reloader.log}"
RELOADER_DELAY="${RELOADER_DELAY:-2}"
FAIL_COUNT=0
MAX_FAILS=5

log() {
 local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
 echo "$msg"
 echo "$msg" >> "${RELOADER_LOG}" 2>/dev/null || true
}

error_exit() {
 log "ERROR: $1"
 exit 1
}

# pre-flight checks
command -v inotifywait >/dev/null 2>&1 || error_exit "inotifywait not found, install inotify-tools"
command -v nginx >/dev/null 2>&1 || error_exit "nginx not found"
[[ -d "${WATCH_DIR}" ]] || error_exit "WATCH_DIR does not exist: ${WATCH_DIR}"

# ensure log directory exists
LOG_DIR=$(dirname "${RELOADER_LOG}")
[[ -d "${LOG_DIR}" ]] || mkdir -p "${LOG_DIR}"

log "Starting nginx-reloader"
log "Config: WATCH_DIR=${WATCH_DIR} DELAY=${RELOADER_DELAY}s LOG=${RELOADER_LOG}"

while true
do
 sleep "${RELOADER_DELAY}"

 # run inotifywait and capture both output and exit code
 set +e
 OUTPUT=$(inotifywait --recursive --include '\.conf$' --format '%w%f %e' \
   -e create -e modify -e delete -e move "${WATCH_DIR}" 2>&1)
 EXIT_CODE=$?
 set -e

 # handle inotifywait errors
 if [[ ${EXIT_CODE} -ne 0 ]]; then
  FAIL_COUNT=$((FAIL_COUNT + 1))
  log "inotifywait failed (exit=${EXIT_CODE}, count=${FAIL_COUNT}): ${OUTPUT}"
  if [[ ${FAIL_COUNT} -ge ${MAX_FAILS} ]]; then
   error_exit "inotifywait failed ${MAX_FAILS} times, giving up"
  fi
  sleep 5
  continue
 fi

 # reset fail count on success
 FAIL_COUNT=0

 # parse output - format is "path event"
 FILE=$(echo "${OUTPUT}" | awk '{print $1}')
 EVENT=$(echo "${OUTPUT}" | awk '{print $2}')

 # skip if empty
 [[ -z "${FILE}" ]] && continue

 # only process .conf files (double check)
 [[ "${FILE}" != *.conf ]] && continue

 log "Detected: ${FILE} (${EVENT})"

 # test nginx config
 set +e
 TEST_OUTPUT=$(nginx -t 2>&1)
 TEST_CODE=$?
 set -e

 if [[ ${TEST_CODE} -eq 0 ]]; then
  log "Config valid, reloading nginx"
  nginx -s reload || log "Reload failed"
 else
  log "Config test failed: ${TEST_OUTPUT}"
 fi
done
