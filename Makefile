TAG=etriasnl/dev-php-fpm:7.4.28

lint:
	docker run -it --rm -v "$(shell pwd):/app" -w /app hadolint/hadolint hadolint --ignore DL3059 Dockerfile
build: lint
	docker buildx build -t ${TAG} .
run:
	docker run --rm -it ${TAG} bash
fresh-run: build run
release: build
	docker push ${TAG}
