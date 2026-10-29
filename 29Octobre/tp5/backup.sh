#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib.sh"

KEEP="${KEEP:-7}"
mkdir -p "$BACKUP_DIR"
ts=$(date +%Y%m%d-%H%M%S)

docker compose exec -T db pg_dump -U shop -Fc shop > "$BACKUP_DIR/shop-$ts.dump"
echo "dump logique : $BACKUP_DIR/shop-$ts.dump"

if [ "${1:-}" = "--raw" ]; then
  docker compose stop db
  docker run --rm -v "$VOLUME":/data:ro -v "$BACKUP_DIR":/backup alpine \
    tar czf "/backup/pgdata-$ts.tgz" -C /data .
  docker compose up -d --wait db
  echo "sauvegarde brute : $BACKUP_DIR/pgdata-$ts.tgz"
fi

for pattern in 'shop-*.dump' 'pgdata-*.tgz'; do
  ls -1t "$BACKUP_DIR"/$pattern 2>/dev/null | tail -n +$((KEEP + 1)) | xargs -r rm -f --
done
