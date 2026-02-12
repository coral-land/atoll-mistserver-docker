.DEFAULT_GOAL := help

up: ## Run Docker compose with latest image
	docker compose -f docker/docker-compose.yaml up -d

down: ## Same Docker compose down
	docker compose -f docker/docker-compose.yaml down --remove-orphans

prune: ## Remove docker latest odcker image
	docker image rm ghcr.io/coral-land/atoll-mistserver-docker:latest-amd64

logs: ## Logs for Mist Server Container
	docker compose -f docker/docker-compose.yaml logs mist-server

updev: ## Run docker comopse dev
	docker compose -f docker/docker-compose-dev.yaml up -d

downdev: ## Stop docker compose for dev
	docker compose -f docker/docker-compose-dev.yaml down -v --remove-orphans

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
