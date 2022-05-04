IMAGE=etriasnl/dev-php-fpm
VERSION=7.4.29-2

TAG=${IMAGE}:${VERSION}
LATEST=${IMAGE}:latest

MAKEFLAGS += --warn-undefined-variables

DEFAULT_GOAL := help
help:
	@LC_ALL=C $(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

lint:
	docker run -it --rm -v "$(shell pwd):/app" -w /app hadolint/hadolint hadolint --ignore DL3059 Dockerfile
release: lint
	docker build -t "${TAG}" -t "${LATEST}" .
run: release
	docker run --rm -it "${TAG}" bash
publish: release
	docker push "${TAG}"
	docker push "${LATEST}"
