.DEFAULT_GOAL := help

up: ## Run Docker compose with latest image
	docker compose -f docker/docker-compose.yaml up -d

down: ## Same Docker compose down
	docker compose -f docker/docker-compose.yaml down --remove-orphans

prune:
	docker image rm ghcr.io/coral-land/atoll-mistserver-docker:latest-amd64

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
