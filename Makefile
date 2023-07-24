MAKEFLAGS += --warn-undefined-variables --always-make
.DEFAULT_GOAL := _

IMAGE=$(shell docker run -i --rm mikefarah/yq '.env.DOCKER_IMAGE' < .github/workflows/publish.yaml)
IMAGE_TAG=${IMAGE}:$(shell (git describe --tags --exact-match || git symbolic-ref --short HEAD || git rev-parse --short HEAD) | sed 's\/\-\')

DOCKERFILE?=Dockerfile
PHP_VERSION=$(shell cat "${DOCKERFILE}" | grep 'FROM php:' | cut -f2 -d':' | cut -f1 -d '-')
PHP_VERSION_MAJOR=$(shell echo "${PHP_VERSION}" | cut -f1 -d '.')
PHP_VERSION_MINOR=$(shell echo "${PHP_VERSION}" | cut -f2 -d '.')
PATCH_VERSION=$$(($(shell curl -sS "https://hub.docker.com/v2/repositories/${IMAGE}/tags/?page_size=1&page=1&name=${PHP_VERSION_MAJOR}.${PHP_VERSION_MINOR}.&ordering=last_updated" | jq -r '.results[0].name' | cut -f2 -d '-') + 1))
PHP_TAG=${IMAGE}:${PHP_VERSION}-${PATCH_VERSION}

exec_docker=docker run $(shell [ "$$CI" = true ] && echo "-t" || echo "-it") -e CI -u "$(shell id -u):$(shell id -g)" --rm -v "$(shell pwd):/app" -w /app

# @todo move composer.json to root after single version per branch
# @todo remove config.platform version from composer.json
composer-cli: # @todo ${exec_docker} bash
	${exec_docker} composer bash
composer-update: # @todo ${exec_docker} composer ...
	${exec_docker} composer --working-dir="tools/php-7.4" update
	${exec_docker} composer --working-dir="tools/php-7.4" bump
	${exec_docker} composer --working-dir="tools/php-7.4" normalize
	${exec_docker} composer --working-dir="tools/php-8.1" update
	${exec_docker} composer --working-dir="tools/php-8.1" bump
	${exec_docker} composer --working-dir="tools/php-8.1" normalize
lint:
	${exec_docker} hadolint/hadolint hadolint --ignore DL3008 --ignore DL3059 --ignore DL4006 "${DOCKERFILE}"
build: lint
	docker buildx build --file "${DOCKERFILE}" --load --tag "${PHP_TAG}" .
cli: clean build
	docker run -it --rm "${PHP_TAG}" bash
clean:
	docker rm $(shell docker ps -aq -f "ancestor=${IMAGE_TAG}") --force || true
	docker rmi $(shell docker images -q "${IMAGE}") --force || true
test: IMAGE_TAG=php-tmp-test
test: PHP_TAG=php-tmp-test
test: build
	docker run --rm "${IMAGE_TAG}" node --version
	docker run --rm "${IMAGE_TAG}" yarn --version
	docker run --rm "${IMAGE_TAG}" pt-online-schema-change --version
	docker run --rm "${IMAGE_TAG}" php -v
	docker run --rm "${IMAGE_TAG}" php -m | paste -sd ","
	docker run --rm "${IMAGE_TAG}" composer --version
	docker run --rm "${IMAGE_TAG}" composer --working-dir=/usr/local/etc/tools normalize --dry-run
	docker run --rm "${IMAGE_TAG}" phplint --version
	docker run --rm "${IMAGE_TAG}" php-cs-fixer --version --version
	docker run --rm "${IMAGE_TAG}" phpunit --version
	docker run --rm "${IMAGE_TAG}" psalm --version
	docker run --rm "${IMAGE_TAG}" rector --version

# @deprecated see other dockerfile repos "release" target, needs single version per branch first
publish: build
	git fetch --all --prune --tags --prune-tags --force --quiet
	@[ "$$(git status --porcelain)" ] && echo "Commit your changes" && exit 1 || true
	@[ "$$(git log --branches --not --remotes)" ] && echo "Push your commits" && exit 1 || true
	@[ "$$(git describe --tags --abbrev=0 --exact-match)" ] && echo "Commit already tagged" && exit 1 || true
	git tag "${PHP_VERSION}-${PATCH_VERSION}"
	@read -p "Continue? (y/N) " REPLY && [ "$$REPLY" = "y" ] || [ "$$REPLY" = "Y" ] || exit
	docker push "${PHP_TAG}"
	git push --tags

# upcoming version 8.1
# @deprecated use git branches for future upcoming versions

81-cli: DOCKERFILE=Dockerfile_81
81-cli: cli

81-test: DOCKERFILE=Dockerfile_81
81-test: test

81-publish: DOCKERFILE=Dockerfile_81
81-publish: publish
