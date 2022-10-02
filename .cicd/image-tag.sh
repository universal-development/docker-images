#!/usr/bin/env bash
# Script to print last Git tag correlated with image variable
# Example usage:
# image=aws-cli ./.cicd/image-tag.sh

RELEASE_TAG=$(git describe --match "${image}*" --abbrev=0 --tags $(git rev-list --tags --max-count=1))
echo ${RELEASE_TAG/${image}-/}