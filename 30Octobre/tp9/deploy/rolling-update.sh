#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
STACK_DIR="${STACK_DIR:-$HERE/../../../29Octobre/TP4}"
COMPOSE="${COMPOSE:-docker compose -f $STACK_DIR/compose.yml -f $HERE/../compose.rolling.yml}"
DRAIN="${DRAIN:-3}"
export VERSION="${VERSION:?VERSION requis}"

started=$(date +%s)

$COMPOSE up -d --no-recreate --wait traefik db redis worker

old=$($COMPOSE ps -q api)
replicas=$(echo "$old" | grep -c . || true)
[ "$replicas" -gt 0 ] || replicas=2

if [ -z "$old" ]; then
  $COMPOSE up -d --wait --scale api="$replicas" api
else
  count=$replicas
  for id in $old; do
    count=$((count+1))
    $COMPOSE up -d --no-deps --no-recreate --wait --scale api="$count" api
    sleep "$DRAIN"
    docker stop -t 15 "$id" >/dev/null
    docker rm "$id" >/dev/null
    count=$((count-1))
    echo "replica $(docker inspect -f '{{.Name}}' "$id" 2>/dev/null || echo "${id:0:12}") remplace"
  done
fi

$COMPOSE ps api
echo "deploiement $VERSION termine en $(( $(date +%s) - started ))s"
