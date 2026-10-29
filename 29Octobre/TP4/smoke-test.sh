#!/usr/bin/env bash
set -euo pipefail

BASE="${BASE:-http://127.0.0.1}"
HOST="${HOST_HEADER:-api.localhost}"
COMPOSE="${COMPOSE:-docker compose}"

req() { curl -fsS -H "Host: $HOST" "$@"; }

confirmed() {
  $COMPOSE exec -T db psql -U shop -d shop -tAc "SELECT count(*) FROM orders WHERE status='confirmed'"
}

echo "-> /ready"
for _ in $(seq 1 30); do
  req "$BASE/ready" 2>/dev/null | grep -q '"status":"ready"' && break
  sleep 1
done
req "$BASE/ready" | grep -q '"status":"ready"'

echo "-> /products"
req "$BASE/products" -o /dev/null
hit=$(req -D - -o /dev/null "$BASE/products" | tr -d '\r' | awk -F': ' 'tolower($1)=="x-cache"{print $2}')
[ "$hit" = "HIT" ] || { echo "cache attendu HIT, reçu '$hit'"; exit 1; }

echo "-> commande"
before=$(confirmed)
req -X POST -H 'Content-Type: application/json' -d '{"productId":1,"quantity":2}' "$BASE/orders" | grep -q '"status":"pending"'

for _ in $(seq 1 20); do
  now=$(confirmed)
  [ "$now" -gt "$before" ] && { echo "commande confirmée par le worker"; echo OK; exit 0; }
  sleep 1
done

echo "la commande n'a pas été confirmée"
exit 1
