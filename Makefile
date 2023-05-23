export WWWGROUP=${WWWGROUP:-$(id -g)}
export WWWUSER=${WWWUSER:-$UID}
BACKEND_ENV=docker run --rm -i --user $(shell id -u):$(shell id -g) -v $(shell git rev-parse --show-superproject-working-tree --show-toplevel | head -1):/var/www/html -w /var/www/html laravelsail/php82-composer:latest
SAIL=$(shell git rev-parse --show-superproject-working-tree --show-toplevel | head -1)/vendor/bin/sail
COMPOSER=docker run --rm -i --user `id -u`:`id -g` -v `pwd`:/app composer:2.3.10

setup-local:
	@make backend-setup

setup-ci:
	@make backend-setup

# swagger-ui:
# 	(cd utils && docker compose up swagger_ui -d --no-recreate )
# 	open http://localhost:8080/

backend-setup:
	(cp .env.example .env)
	(${BACKEND_ENV} composer install --ignore-platform-reqs)
	(${BACKEND_ENV} php artisan key:generate)
	@make backend-up
	@make backend-generate
	(${SAIL} pint)

backend-build:
	(${BACKEND_ENV} composer install --ignore-platform-reqs)
	(${SAIL} build ${BUILD_OPTIONS})

backend-generate:
	(${BACKEND_ENV} php artisan ide-helper:generate)
	@make backend-migrate
	@make backend-annotation
	@make backend-oas-generate

backend-up:
	(${SAIL} up -d --build && \
	sleep 10)

backend-down:
	(${SAIL} down)

backend-destroy:
	(${SAIL} down -v)

backend-test:
	(${SAIL} test --coverage --coverage-clover clover.xml  )

backend-lint:
	(${SAIL} pint)
	@make backend-phpstan

backend-oas-generate:
	(${SAIL} artisan openapi:generate > $(shell pwd)/documents/api/schema.json)

backend-route-check:
	(${SAIL} artisan route:list)

all-containers-build:
	@make backend-build
#	(cd utils && docker compose build)

trivy:
	trivy image $(shell docker images --format "{{.Repository}}:{{.Tag}}" | grep -v "<none>:<none>")

tinker:
	(${SAIL} tinker)

backend-bash:
	(${SAIL} bash)

backend-migrate:
	(${SAIL} artisan migrate)

backend-annotation:
	(${SAIL} artisan ide-helper:model --write)

backend-phpstan:
	(${BACKEND_ENV} vendor/bin/phpstan analyse -c phpstan.neon --memory-limit=2G)

backend-infra-deploy:
	(cd packages/infra/ec2 && cp setup_base.sh setup.sh && cat .credentials/cf_tunnel.sh >> setup.sh && terraform apply)

backend-infra-plan:
	(cd packages/infra/ec2 && cp setup_base.sh setup.sh && cat .credentials/cf_tunnel.sh >> setup.sh && terraform plan)

backend-infra-plan-ci:
	(cd packages/infra/ec2 && cp setup_base.sh setup.sh && terraform plan -no-color -input=false)

backend-infra-destroy:
	(cd packages/infra/ec2 && terraform destroy)

backend-composer-update:
	(${COMPOSER} update)
