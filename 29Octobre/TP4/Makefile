PROD = -f compose.yml -f compose.prod.yml

.PHONY: secret up down prod-up prod-down tools migrate test logs

secret:
	@test -f secrets/db_password.txt || (openssl rand -hex 24 | tr -d '\n' > secrets/db_password.txt)

up: secret
	docker compose up -d --build --wait

down:
	docker compose down

prod-up: secret
	docker compose $(PROD) up -d --wait

prod-down:
	docker compose $(PROD) down

tools:
	docker compose --profile tools up -d --wait adminer

migrate:
	MIGRATION=$(M) docker compose run --rm migrate

test:
	./smoke-test.sh

logs:
	docker compose logs -f --tail=50
