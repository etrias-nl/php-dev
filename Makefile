TAG=etriasnl/dev-php-fpm:7.4.28

build:
	docker build -t ${TAG} .
run: build
	docker run -it ${TAG} bash
