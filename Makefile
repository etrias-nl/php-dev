TAG=etriasnl/dev-php-fpm

build:
	docker build -t ${TAG} .
run: build
	docker run -it ${TAG} bash
