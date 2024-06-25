SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c

export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
export PROJECT=api

targets: help

build: ## Build the application
	docker-compose build api

push: ## Push the application to docker hub
	docker push gluck0101/motqin:latest

up: ## Run the application
	docker-compose up --build api

done: lint test ## Prepare for a commit
test: utest itest  ## Run unit and integration tests

ci-docker-compose := docker-compose -f .ci/docker-compose.yml

utest: cleantest ## Run unit tests
	$(ci-docker-compose) run --rm unit pytest -m unit .

itest: cleantest ## Run integration tests
	$(ci-docker-compose) run --rm integration pytest -m integration .

check: ## Check the code base
	$(ci-docker-compose) run --rm unit black ./$(PROJECT) --check --diff
	$(ci-docker-compose) run --rm unit isort ./$(PROJECT) --check --diff
	$(ci-docker-compose) run --rm -v mypycache:/home/user/.mypy_cache unit mypy ./$(PROJECT)

lint: ## Check the code base, and fix it
	$(ci-docker-compose) run --rm unit black ./$(PROJECT)
	$(ci-docker-compose) run --rm unit isort ./$(PROJECT)
	$(ci-docker-compose) run --rm -v mypycache:/home/user/.mypy_cache unit mypy ./$(PROJECT)

cleantest:  ## Clean up test containers
	$(ci-docker-compose) build
	$(ci-docker-compose) down --remove-orphans

help: ## Display this help message
	@awk -F '##' '/^[a-z_]+:[a-z ]+##/ { print "\033[34m"$$1"\033[0m" "\n" $$2 }' Makefile
