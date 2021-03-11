#!/usr/bin/env bash

set -euxo pipefail

DOCKER_REPO="${DOCKER_REPO:-denis256}"
PUSH=${PUSH:-0}
IMAGE="$1"

cd "$IMAGE"

source config.sh

docker build . -t "$DOCKER_REPO/$IMAGE:$TAG"

if [[ "${PUSH}" == "1" ]]; then
	docker push "$DOCKER_REPO/$IMAGE:$TAG"
fi

