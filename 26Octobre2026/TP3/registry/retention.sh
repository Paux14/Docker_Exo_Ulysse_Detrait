#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

REPO="${1:?usage: retention.sh REPO [N]}"
KEEP="${2:-5}"
BASE="https://${REGISTRY_HOST}/v2"
ACCEPT='Accept: application/vnd.oci.image.index.v1+json, application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json'
SEMVER='^v?[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$'

digest_of() {
  reg_curl -I -H "$ACCEPT" "$BASE/$REPO/manifests/$1" | tr -d '\r' \
    | awk -F': ' 'tolower($1)=="docker-content-digest"{print $2}'
}

created_of() {
  local manifest cfg
  manifest=$(reg_curl -H "$ACCEPT" "$BASE/$REPO/manifests/$1")
  if echo "$manifest" | jq -e '.manifests' >/dev/null 2>&1; then
    local sub
    sub=$(echo "$manifest" | jq -r '.manifests[0].digest')
    manifest=$(reg_curl -H "$ACCEPT" "$BASE/$REPO/manifests/$sub")
  fi
  cfg=$(echo "$manifest" | jq -r '.config.digest')
  reg_curl -L "$BASE/$REPO/blobs/$cfg" | jq -r '.created // "1970-01-01T00:00:00Z"'
}

tags=$(reg_curl "$BASE/$REPO/tags/list" | jq -r '.tags // [] | .[]')
[ -z "$tags" ] && { echo "aucun tag dans $REPO"; exit 0; }

protected=""
candidates=""
for t in $tags; do
  if [[ "$t" =~ $SEMVER ]]; then
    protected+="$(digest_of "$t") "
    echo "semver, conserve : $t"
  else
    candidates+="$(created_of "$t") $t"$'\n'
  fi
done

sorted=$(printf '%s' "$candidates" | sort -r)
i=0
while read -r created tag; do
  [ -z "${tag:-}" ] && continue
  i=$((i + 1))
  d=$(digest_of "$tag")
  if [ "$i" -le "$KEEP" ]; then
    protected+="$d "
    echo "recent #$i, conserve : $tag ($created)"
  fi
done <<< "$sorted"

i=0
while read -r created tag; do
  [ -z "${tag:-}" ] && continue
  i=$((i + 1))
  [ "$i" -le "$KEEP" ] && continue
  d=$(digest_of "$tag")
  if [[ " $protected " == *" $d "* ]]; then
    echo "partage un digest conserve, ignore : $tag"
    continue
  fi
  code=$(reg_curl -X DELETE -o /dev/null -w '%{http_code}' "$BASE/$REPO/manifests/$d")
  echo "supprime : $tag ($d) -> HTTP $code"
done <<< "$sorted"

echo "pense a lancer le garbage-collect pour liberer l'espace disque"
