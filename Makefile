TAG=etriasnl/dev-php-fpm:7.4.28
MAKEFLAGS += --warn-undefined-variables

lint:
	docker run -it --rm -v "$(shell pwd):/app" -w /app hadolint/hadolint hadolint --ignore DL3059 Dockerfile
release: lint
	docker buildx build -t "${TAG}" .
run: release
	docker run --rm -it "${TAG}" bash
publish: release
	docker push "${TAG}"
