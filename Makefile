SHELL := /bin/bash
current_dir = $(shell pwd)
DOCKER_REPO := universaldevelopment
IMAGE_TAG=$(shell image=$(image) ./.cicd/image-tag.sh)

container:
	echo "Image Tag: $(IMAGE_TAG)"
	cd $(image) && docker build . -t $(image):local --squash;

push:
	echo "Image Tag: $(IMAGE_TAG)"
	docker tag $(image):local "$(DOCKER_REPO)/$(image):$(IMAGE_TAG)"
	docker push "$(DOCKER_REPO)/$(image):$(IMAGE_TAG)"
