#!/bin/bash

set -e

IMAGE_NAME=${1:-ai-cli}
IMAGE_TAG=${2:-latest}

echo "Building ${IMAGE_NAME}:${IMAGE_TAG}..."
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .

echo "Build complete: ${IMAGE_NAME}:${IMAGE_TAG}"
