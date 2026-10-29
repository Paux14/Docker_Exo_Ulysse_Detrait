#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib.sh"

dump="${1:-$(ls -1t "$BACKUP_DIR"/shop-*.dump | head -n 1)}"
[ -f "$dump" ] || { echo "dump introuvable : $dump"; exit 1; }
echo "restauration depuis $dump"

docker compose up -d --wait db
docker compose exec -T db psql -U shop -d postgres -c "DROP DATABASE IF EXISTS shop WITH (FORCE)"
docker compose exec -T db psql -U shop -d postgres -c "CREATE DATABASE shop OWNER shop"
docker compose exec -T db pg_restore -U shop -d shop --no-owner < "$dump"

echo "checksum après restauration : $(checksum)"
