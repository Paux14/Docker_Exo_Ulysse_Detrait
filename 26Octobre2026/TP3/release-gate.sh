#!/usr/bin/env bash
set -euo pipefail

usage() { echo "usage: release-gate.sh IMAGE [--push REGISTRY_IMAGE]" >&2; exit 2; }

IMAGE="${1:-}"
[ -n "$IMAGE" ] || usage
PUSH_TARGET=""
if [ "${2:-}" = "--push" ]; then
  PUSH_TARGET="${3:-}"
  [ -n "$PUSH_TARGET" ] || usage
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEC="$ROOT/security"
CERTS="$ROOT/registry/certs"
NET="${REGISTRY_NETWORK:-registry_default}"
REG_USER="${REGISTRY_USER:-ci}"
REG_PASS="${REGISTRY_PASS:-ci-push-2024}"
export MSYS_NO_PATHCONV=1

jqc() { docker run --rm -i ghcr.io/jqlang/jq:latest "$@"; }
trivy() { docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v trivy-cache:/root/.cache aquasec/trivy:latest "$@"; }
syft() { docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v "$SEC:/out" anchore/syft:latest "$@"; }
cosign() {
  docker run --rm --network "$NET" -v "$CERTS:/certs:ro" -v "$SEC:/work" -w /work \
    -e SSL_CERT_FILE=/certs/ca.crt -e COSIGN_PASSWORD= \
    -e COSIGN_REGISTRY_USERNAME="$REG_USER" -e COSIGN_REGISTRY_PASSWORD="$REG_PASS" \
    ghcr.io/sigstore/cosign/cosign:latest "$@"
}

FAIL=0
fail() { echo "REFUS : $*"; FAIL=1; }
ok() { echo "ok    : $*"; }

docker image inspect "$IMAGE" >/dev/null 2>&1 || { echo "image introuvable : $IMAGE"; exit 2; }
META=$(docker image inspect "$IMAGE")

for label in org.opencontainers.image.version org.opencontainers.image.revision org.opencontainers.image.source; do
  value=$(echo "$META" | jqc -r --arg l "$label" '.[0].Config.Labels[$l] // empty')
  if [ -z "$value" ]; then fail "label $label absent"; else ok "$label=$value"; fi
done

user=$(echo "$META" | jqc -r '.[0].Config.User // empty')
case "$user" in
  ""|0|root|0:*|root:*) fail "utilisateur root (User='${user}')" ;;
  *) ok "utilisateur non-root ($user)" ;;
esac

if [ "$(echo "$META" | jqc -r '.[0].Config.Healthcheck.Test // empty | length')" = "" ]; then
  fail "pas de HEALTHCHECK"
else
  ok "HEALTHCHECK defini"
fi

REPORT=$(trivy image -q -f json --scanners vuln,secret --severity HIGH,CRITICAL --ignore-unfixed "$IMAGE" 2>/dev/null)
vulns=$(echo "$REPORT" | jqc '[.Results[]? | (.Vulnerabilities // [])[]] | length')
secrets=$(echo "$REPORT" | jqc '[.Results[]? | (.Secrets // [])[]] | length')
if [ "$vulns" -gt 0 ]; then fail "$vulns CVE HIGH/CRITICAL corrigeables"; else ok "aucune CVE HIGH/CRITICAL corrigeable"; fi
if [ "$secrets" -gt 0 ]; then
  fail "$secrets secret(s) detecte(s)"
  echo "$REPORT" | jqc -r '.Results[]? | .Target as $t | (.Secrets // [])[] | "        \(.Title) dans \($t)"'
else
  ok "aucun secret detecte"
fi

if [ "$FAIL" -ne 0 ]; then
  echo "porte de release : image refusee"
  exit 1
fi

if [ -z "$PUSH_TARGET" ]; then
  echo "porte de release : image conforme (pas de push demande)"
  exit 0
fi

HOST_REF="localhost:5000/${PUSH_TARGET#*/}"
docker tag "$IMAGE" "$HOST_REF"
docker push "$HOST_REF" | tee /tmp/gate-push.log
DIGEST=$(awk '/digest: sha256/ {for (i=1;i<=NF;i++) if ($i ~ /^sha256:/) print $i}' /tmp/gate-push.log | tail -1)
REPO_PATH="${PUSH_TARGET#*/}"
INTERNAL_REPO="registry:5000/${REPO_PATH%%:*}"

syft "$IMAGE" -o spdx-json=/out/sbom.json >/dev/null
cosign sign --yes --use-signing-config=false --tlog-upload=false --key cosign.key "${INTERNAL_REPO}@${DIGEST}"
cosign attest --yes --use-signing-config=false --tlog-upload=false --key cosign.key --type spdxjson --predicate sbom.json "${INTERNAL_REPO}@${DIGEST}"
echo "porte de release : image publiee et signee (${INTERNAL_REPO}@${DIGEST})"
