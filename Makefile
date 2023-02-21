DOCKERFILE?=Dockerfile
DOCKER_PROGRESS?=auto
DOCKER_IMAGE=etriasnl/dev-php-fpm
PHP_VERSION=$(shell cat "${DOCKERFILE}" | grep 'FROM php:' | cut -f2 -d':' | cut -f1 -d '-')
PHP_VERSION_MAJOR=$(shell echo "${PHP_VERSION}" | cut -f1 -d '.')
PHP_VERSION_MINOR=$(shell echo "${PHP_VERSION}" | cut -f2 -d '.')
NODE_VERSION=$(shell cat "${DOCKERFILE}" | grep 'FROM node:' | cut -f2 -d':' | cut -f1 -d '-')
PATCH_VERSION=$$(($(shell curl -sS "https://hub.docker.com/v2/repositories/${DOCKER_IMAGE}/tags/?page_size=1&page=1&name=${PHP_VERSION_MAJOR}.${PHP_VERSION_MINOR}.&ordering=last_updated" | jq -r '.results[0].name' | cut -f2 -d '-') + 1))
MAKEFLAGS += --warn-undefined-variables --always-make
.DEFAULT_GOAL := _

PHP_TAG=${DOCKER_IMAGE}:${PHP_VERSION}-${PATCH_VERSION}
PHP_NODE_TAG=${PHP_TAG}-node-${NODE_VERSION}

exec_docker=docker run -it --rm -v "$(shell pwd):/app" -w /app

composer-cli:
	${exec_docker} composer bash
bump-tools:
	${exec_docker} composer --working-dir="tools/php-${PHP_VERSION_MAJOR}.${PHP_VERSION_MINOR}" update
	${exec_docker} composer --working-dir="tools/php-${PHP_VERSION_MAJOR}.${PHP_VERSION_MINOR}" bump
	${exec_docker} composer --working-dir="tools/php-${PHP_VERSION_MAJOR}.${PHP_VERSION_MINOR}" normalize
lint:
	${exec_docker} hadolint/hadolint hadolint --ignore DL3059 "${DOCKERFILE}"
release: lint
	docker buildx build --progress "${DOCKER_PROGRESS}" --target php -f "${DOCKERFILE}" -t "${PHP_TAG}" --load .
	docker buildx build --progress "${DOCKER_PROGRESS}" --target php_node -f "${DOCKERFILE}" -t "${PHP_NODE_TAG}" --load .
publish: release
	docker push "${PHP_TAG}"
	docker push "${PHP_NODE_TAG}"
	git tag "${PHP_VERSION}-${PATCH_VERSION}"
	git push --tags

# upcoming version 8.1

81-bump-tools: DOCKERFILE=Dockerfile_81
81-bump-tools: bump-tools

81-publish: DOCKERFILE=Dockerfile_81
81-publish: publish
