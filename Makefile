MAKEFLAGS += --warn-undefined-variables --always-make
.DEFAULT_GOAL := _

IMAGE=$(shell docker run -i --rm mikefarah/yq '.env.DOCKER_IMAGE' < .github/workflows/docker-build.yaml)
IMAGE_TAG=${IMAGE}:$(shell (git describe --tags --exact-match || git symbolic-ref --short HEAD || git rev-parse --short HEAD) | sed 's\/\-\')

exec_docker=docker run $(shell [ "$$CI" = true ] && echo "-t" || echo "-it") -e CI -e GITHUB_ACTIONS -e RUNNER_DEBUG -u "$(shell id -u):$(shell id -g)" --rm -v "$(shell pwd):/app" -w /app
exec_docker_app=${exec_docker} ${IMAGE_TAG}

composer-update: build
	${exec_docker_app} sh -c "composer update --no-progress -n && composer bump && composer normalize"
composer-cli: build
	${exec_docker_app} bash
build:
	docker buildx build --load --tag "${IMAGE_TAG}" .
cli: clean build
	docker run -it --rm "${IMAGE_TAG}" bash
clean:
	docker rm $(shell docker ps -aq -f "ancestor=${IMAGE_TAG}") --force || true
	docker rmi $(shell docker images -q "${IMAGE}") --force || true
