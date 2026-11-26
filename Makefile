# TOSCA platform. `make help` lists the commands.

SHELL := /bin/bash
.DEFAULT_GOAL := help

# versions.local.env exists only after `make build-local`; it then overrides
# the released image names in versions.env with locally built ones.
ENV_FILES := --env-file versions.env $(if $(wildcard versions.local.env),--env-file versions.local.env) $(if $(wildcard .env),--env-file .env)
OVERRIDE  := $(if $(wildcard compose.override.yaml),-f compose.override.yaml)
COMPOSE   := docker compose $(ENV_FILES) -f compose.yaml $(OVERRIDE)
BUILD     := docker compose $(ENV_FILES) -f compose.yaml -f compose.build.yaml

# Component checkouts. `make dev-setup` clones them into components/.
BACKEND_SRC   ?= $(or $(shell sed -n 's/^BACKEND_SRC=//p' .env 2>/dev/null),./components/TOSCA-Backend)
FRONTEND_SRC  ?= $(or $(shell sed -n 's/^FRONTEND_SRC=//p' .env 2>/dev/null),./components/TOSCA-Frontend)
GEOSERVER_SRC ?= $(or $(shell sed -n 's/^GEOSERVER_SRC=//p' .env 2>/dev/null),./components/geoserver_docker)
export BACKEND_SRC FRONTEND_SRC GEOSERVER_SRC

# Development: which components run from source. ONLY=backend or ONLY=frontend
# runs just that one from source and the other from its image.
DEV_FILES := $(if $(filter-out frontend,$(ONLY)),-f compose.dev.backend.yaml) \
             $(if $(filter-out backend,$(ONLY)),-f compose.dev.frontend.yaml) \
             $(if $(ONLY),,-f compose.dev.backend.yaml -f compose.dev.frontend.yaml)
DEV := docker compose $(ENV_FILES) -f compose.yaml $(DEV_FILES)

.PHONY: help
help: ## Show this list
	@awk 'BEGIN{FS=":.*## "} /^##@/{printf "\n%s\n", substr($$0,5)} /^[a-z-]+:.*## /{printf "  make %-14s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

##@ Run TOSCA
.PHONY: init up down restart ps logs config smoke versions
init: ## Create .env with random secrets (first time only)
	@scripts/init-env.sh

up: .env ## Start TOSCA (pulls the images of this release if missing)
	$(COMPOSE) up -d --wait --wait-timeout 900
	@$(MAKE) --no-print-directory urls

down: ## Stop TOSCA. Data volumes are kept
	$(COMPOSE) down

restart: down up ## Stop and start

ps: ## Show the containers
	$(COMPOSE) ps -a

logs: ## Follow the logs (SERVICE=django for one service)
	$(COMPOSE) logs -f --tail 100 $(SERVICE)

config: ## Check the configuration and print the resolved Compose file
	$(COMPOSE) config

smoke: .env ## Check that the running stack works end to end
	@COMPOSE="$(COMPOSE)" scripts/smoke.sh

versions: ## Show which images are running, with their version and commit
	@COMPOSE="$(COMPOSE)" scripts/info.sh versions

.PHONY: urls
urls:
	@COMPOSE="$(COMPOSE)" scripts/info.sh urls

.env:
	@echo "No .env yet. Run: make init" >&2; exit 1

##@ Update and back up
.PHONY: pull update backup
pull: ## Download the images of this release
	$(COMPOSE) pull --ignore-buildable

update: pull backup ## Back up the database, then restart on the images in versions.env
	$(COMPOSE) up -d --wait --wait-timeout 900

backup: .env ## Dump the database to backups/
	@mkdir -p -m 700 backups; f=backups/$$(date -u +%Y%m%dT%H%M%SZ).dump; \
	  ( umask 077; $(COMPOSE) exec -T db sh -c 'pg_dump -U "$$POSTGRES_USER" -d "$$POSTGRES_DB" -Fc' > $$f.tmp ) && mv $$f.tmp $$f && echo "Wrote $$f"

##@ Build from source
.PHONY: build-local
build-local: ## Build the three images from the component checkouts and use them (SERVICE=web for one)
	@scripts/build-local.sh $(SERVICE)

##@ Develop
.PHONY: dev-setup dev-up dev-down dev-logs test lint
dev-setup: ## Clone the component repositories into components/ and create .env
	@scripts/dev-setup.sh

dev-up: .env ## Run backend and frontend from source with hot reload (ONLY=backend|frontend)
	$(DEV) up -d --wait --wait-timeout 900
	@$(MAKE) --no-print-directory urls

dev-down: ## Stop the development stack. Data volumes are kept
	$(DEV) down

dev-logs: ## Follow the development logs (SERVICE=web for one service)
	$(DEV) logs -f --tail 100 $(SERVICE)

test: ## Run the backend and frontend unit tests from the checkouts
	$(MAKE) -C $(BACKEND_SRC) test
	cd $(FRONTEND_SRC) && npm test -- --run

lint: ## Lint backend and frontend
	cd $(BACKEND_SRC) && uvx ruff check .
	cd $(FRONTEND_SRC) && npm run lint
