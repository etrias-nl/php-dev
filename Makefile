IMAGE=etriasnl/dev-php-fpm
PHP_VERSION=7.4.29-8
NODE_VERSION=16.15.0
MAKEFLAGS += --warn-undefined-variables

PHP_TAG=${IMAGE}:${PHP_VERSION}
PHP_LATEST=${IMAGE}:latest
PHP_NODE_TAG=${IMAGE}:${PHP_VERSION}-node-${NODE_VERSION}

lint:
	docker run -it --rm -v "$(shell pwd):/app" -w /app hadolint/hadolint hadolint --ignore DL3059 Dockerfile
release: lint
	docker build --target php -t "${PHP_TAG}" -t "${PHP_LATEST}" .
	docker build --target php_node -t "${PHP_NODE_TAG}" .
run: release
	docker run --rm -it "${PHP_TAG}" bash
publish: release
	docker push "${PHP_TAG}"
	docker push "${PHP_LATEST}"
	docker push "${PHP_NODE_TAG}"
