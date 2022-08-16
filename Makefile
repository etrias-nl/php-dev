PHP_VERSION=$(shell cat Dockerfile | grep 'FROM php:' | cut -f2 -d':' | cut -f1 -d '-')
NODE_VERSION=$(shell cat Dockerfile | grep 'FROM node:' | cut -f2 -d':' | cut -f1 -d '-')
PATCH_VERSION=14
DOCKER_IMAGE=etriasnl/dev-php-fpm
DOCKER_PROGRESS?=auto
MAKEFLAGS += --warn-undefined-variables --always-make
.DEFAULT_GOAL := _

PHP_TAG=${DOCKER_IMAGE}:${PHP_VERSION}-${PATCH_VERSION}
PHP_LATEST=${DOCKER_IMAGE}:latest
PHP_NODE_TAG=${PHP_TAG}-node-${NODE_VERSION}

lint:
	docker run -it --rm -v "$(shell pwd):/app" -w /app hadolint/hadolint hadolint --ignore DL3059 Dockerfile
release: lint
	docker buildx build --progress "${DOCKER_PROGRESS}" --target php -t "${PHP_TAG}" -t "${PHP_LATEST}" --load .
	docker buildx build --progress "${DOCKER_PROGRESS}" --target php_node -t "${PHP_NODE_TAG}" --load .
publish: release
	docker push "${PHP_TAG}"
	docker push "${PHP_LATEST}"
	docker push "${PHP_NODE_TAG}"
