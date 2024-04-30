MAKEFLAGS += --warn-undefined-variables --always-make
.DEFAULT_GOAL := _

exec_docker=docker run $(shell [ "$$CI" = true ] && echo "-t" || echo "-it") -e CI -e GITHUB_ACTIONS -e RUNNER_DEBUG -u "$(shell id -u):$(shell id -g)" --rm -v "$(shell pwd):/app" -w /app
exec_app=${exec_docker} "$(shell docker build -q .)"

composer-update:
	${exec_app} sh -c "composer update --no-progress -n && composer bump && composer normalize"
cli:
	${exec_app} bash
