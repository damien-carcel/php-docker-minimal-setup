SHELL = bash

.PHONY: help
help:
	@echo "-----------------"
	@echo "- Main commands -"
	@echo "-----------------"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?#main# .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?#main# "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "----------------------"
	@echo "- Secondary commands -"
	@echo "----------------------"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help

# Initialize environment Variables

IO=

# Build Docker images

.PHONY: pull
pull: ## Pull all Docker images used in docker-compose.yaml.
	@docker-compose pull

.PHONY: build
build: pull ## Build the PHP Docker image.
	@COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker-compose build --pull

# Use the application

.PHONY: php
php: ## Execute anything in the PHP container. For example, use "make php IO='php -a'" to access the PHP interactive shell. Use "XDEBUG_MODE=debug make php" to activate the debugger.
	@docker-compose run --rm php ${IO}

.PHONY: serve
serve: #main# Run the API using the PHP development server. Use "XDEBUG_MODE=debug make serve" to activate the debugger.
	@echo "..."
	@echo "Starting the application"
	@echo "..."
	@docker-compose up -d nginx fpm
	@echo "..."
	@echo "The application is now running, you can access it through http://localhost:8080"
	@echo "..."

.PHONY: down
down: #main# Stop the application and remove all containers, networks and volumes.
	@docker-compose down -v
