MAKEFLAGS += --warn-undefined-variables --always-make
.DEFAULT_GOAL := _

DOCKERFILE?=Dockerfile
DOCKER_IMAGE=etriasnl/dev-php-fpm
PHP_VERSION=$(shell cat "${DOCKERFILE}" | grep 'FROM php:' | cut -f2 -d':' | cut -f1 -d '-')
PHP_VERSION_MAJOR=$(shell echo "${PHP_VERSION}" | cut -f1 -d '.')
PHP_VERSION_MINOR=$(shell echo "${PHP_VERSION}" | cut -f2 -d '.')
PATCH_VERSION=$$(($(shell curl -sS "https://hub.docker.com/v2/repositories/${DOCKER_IMAGE}/tags/?page_size=1&page=1&name=${PHP_VERSION_MAJOR}.${PHP_VERSION_MINOR}.&ordering=last_updated" | jq -r '.results[0].name' | cut -f2 -d '-') + 1))
PHP_TAG=${DOCKER_IMAGE}:${PHP_VERSION}-${PATCH_VERSION}

exec_docker=docker run $(shell [ "$$CI" = true ] && echo "-t" || echo "-it") -u "$(shell id -u):$(shell id -g)" --rm -v "$(shell pwd):/app" -w /app

composer-cli:
	${exec_docker} composer bash
composer-update:
	${exec_docker} composer --working-dir="tools/php-${PHP_VERSION_MAJOR}.${PHP_VERSION_MINOR}" update
	${exec_docker} composer --working-dir="tools/php-${PHP_VERSION_MAJOR}.${PHP_VERSION_MINOR}" bump
	${exec_docker} composer --working-dir="tools/php-${PHP_VERSION_MAJOR}.${PHP_VERSION_MINOR}" normalize
lint-yaml:
	${exec_docker} cytopia/yamllint .
lint-dockerfile:
	${exec_docker} hadolint/hadolint hadolint --ignore DL3008 --ignore DL3059 "${DOCKERFILE}"
lint: lint-yaml lint-dockerfile

# @deprecated see other dockerfile repos, needs single version per branch first
release: lint
	docker buildx build --file "${DOCKERFILE}" --load --tag "${PHP_TAG}" .
publish: release
	docker push "${PHP_TAG}"
	git tag "${PHP_VERSION}-${PATCH_VERSION}"
	git push --tags

# upcoming version 8.1
# @deprecated use git branches for future upcoming versions

81-composer-update: DOCKERFILE=Dockerfile_81
81-composer-update: composer-update

81-publish: DOCKERFILE=Dockerfile_81
81-publish: publish
