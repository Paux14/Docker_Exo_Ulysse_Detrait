#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib.sh"

OLD=(-f compose.yml)
NEW=(-f compose.yml -f compose.pg16.yml)

if [ "${1:-}" = "rollback" ]; then
  docker compose "${NEW[@]}" stop db
  docker compose "${OLD[@]}" up -d --wait db
  echo "retour sur PostgreSQL 14, checksum : $(checksum "${OLD[@]}")"
  exit 0
fi

start=$(date +%s)
mkdir -p "$BACKUP_DIR"
ts=$(date +%Y%m%d-%H%M%S)

before=$(checksum "${OLD[@]}")
echo "checksum avant : $before"

docker compose "${OLD[@]}" exec -T db pg_dumpall -U shop > "$BACKUP_DIR/upgrade-$ts-all.sql"
docker compose "${OLD[@]}" exec -T db pg_dump -U shop -Fc shop > "$BACKUP_DIR/upgrade-$ts.dump"

docker compose "${OLD[@]}" stop db
docker compose "${NEW[@]}" up -d --wait db
docker compose "${NEW[@]}" exec -T db psql -U shop -d shop -tAc "SHOW server_version"

docker compose "${NEW[@]}" exec -T db pg_restore -U shop -d shop --no-owner < "$BACKUP_DIR/upgrade-$ts.dump"

after=$(checksum "${NEW[@]}")
echo "checksum après : $after"
echo "durée : $(( $(date +%s) - start ))s"

if [ "$before" = "$after" ]; then
  echo "VERDICT : OK, aucune perte"
else
  echo "VERDICT : ECHEC, checksums différents"
  exit 1
fi
