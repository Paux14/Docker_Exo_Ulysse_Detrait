#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
APPS="${APPS:-$HERE/../../29Octobre/TP4}"
REGISTRY="${REGISTRY:-localhost:5000}"
SHA="${GIT_SHA:-$(git -C "$HERE" rev-parse --short HEAD)}"
VERSION="${VERSION:-sha-$SHA}"
PUSH="${PUSH:-0}"

echo "-> hadolint"
docker run --rm -i hadolint/hadolint hadolint --failure-threshold warning --ignore DL3018 - < "$APPS/apps/shopapi/Dockerfile"
docker run --rm -i hadolint/hadolint hadolint --failure-threshold warning --ignore DL3008 --ignore DL3013 - < "$APPS/apps/shop-worker/Dockerfile"

echo "-> compose config"
(cd "$APPS" && docker compose -f compose.yml config -q)
(cd "$APPS" && REGISTRY="$REGISTRY" VERSION="$VERSION" docker compose -f compose.yml -f compose.prod.yml config -q)

echo "-> build etape test"
docker build --target test "$APPS/apps/shopapi"
docker build --target test --secret id=pipconf,src="$APPS/apps/shop-worker/pip.conf" "$APPS/apps/shop-worker"

echo "-> build images"
docker build --provenance=true --sbom=true --build-arg APP_VERSION="$VERSION" --build-arg GIT_SHA="$SHA" -t "$REGISTRY/shop-api:$VERSION" "$APPS/apps/shopapi"
docker build --secret id=pipconf,src="$APPS/apps/shop-worker/pip.conf" --build-arg VERSION="$VERSION" --build-arg GIT_SHA="$SHA" -t "$REGISTRY/shop-worker:$VERSION" "$APPS/apps/shop-worker"

echo "-> trivy"
for img in shop-api shop-worker; do
  MSYS_NO_PATHCONV=1 docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.55.2 image --severity CRITICAL --exit-code 1 --ignore-unfixed "$REGISTRY/$img:$VERSION"
done

if [ "$PUSH" = "1" ]; then
  echo "-> push"
  docker push "$REGISTRY/shop-api:$VERSION"
  docker push "$REGISTRY/shop-worker:$VERSION"
fi

echo OK
