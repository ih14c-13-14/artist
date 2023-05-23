export WWWGROUP=${WWWGROUP:-$(id -g)}
export WWWUSER=${WWWUSER:-$UID}
BACKEND_ENV=docker run --rm -i --user $(shell id -u):$(shell id -g) -v $(shell git rev-parse --show-superproject-working-tree --show-toplevel | head -1):/var/www/html -w /var/www/html laravelsail/php82-composer:latest
SAIL=$(shell git rev-parse --show-superproject-working-tree --show-toplevel | head -1)/vendor/bin/sail
COMPOSER=docker run --rm -i --user `id -u`:`id -g` -v `git rev-parse --show-superproject-working-tree --show-toplevel | head -1`:/app composer:2.3.10

setup-local:
	@make setup

setup-ci:
	@make setup

# swagger-ui:
# 	(cd utils && docker compose up swagger_ui -d --no-recreate )
# 	open http://localhost:8080/

setup:
	(cp .env.example .env)
	(${BACKEND_ENV} composer install --ignore-platform-reqs)
	(${BACKEND_ENV} php artisan key:generate)
	@make up
	@make generate
	(${SAIL} pint)

build:
	(${BACKEND_ENV} composer install --ignore-platform-reqs)
	(${SAIL} build ${BUILD_OPTIONS})

generate:
	(${BACKEND_ENV} php artisan ide-helper:generate)
	@make migrate
	@make annotation
    # TODO: OpenAPI スキーマ
	# @make oas-generate

up:
	(${SAIL} up -d --build && \
	sleep 10)

down:
	(${SAIL} down)

destroy:
	(${SAIL} down -v)

test:
	(${SAIL} test --coverage --coverage-clover clover.xml  )

lint:
	(${SAIL} pint)
	@make phpstan

oas-generate:
	(${SAIL} artisan openapi:generate > $(shell pwd)/documents/api/schema.json)

route-check:
	(${SAIL} artisan route:list)

all-containers-build:
	@make build

trivy:
	trivy image $(shell docker images --format "{{.Repository}}:{{.Tag}}" | grep -v "<none>:<none>")

tinker:
	(${SAIL} tinker)

bash:
	(${SAIL} bash)

migrate:
	(${SAIL} artisan migrate)

annotation:
	(${SAIL} artisan ide-helper:model --write)

phpstan:
	(${BACKEND_ENV} vendor/bin/phpstan analyse -c phpstan.neon --memory-limit=2G)

# make require package=<package name>で利用可能
require:
	@if [ -z "$(package)" ]; then \
		echo "package variable is not set"; \
		exit 1; \
	fi
	$(COMPOSER) require $(package)
