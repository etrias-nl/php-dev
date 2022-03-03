TAG=etriasnl/dev-php-fpm:7.4.28

build:
	docker build -t ${TAG} .
run:
	docker run -it ${TAG} bash
fresh-run: build run
release: build
	docker push ${TAG}
