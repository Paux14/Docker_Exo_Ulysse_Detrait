REGISTRY_HOST="${REGISTRY_HOST:-registry.local:5000}"
REGISTRY_USER="${REGISTRY_USER:-ci}"
REGISTRY_PASS="${REGISTRY_PASS:-ci-push-2024}"
CA_CERT="${CA_CERT:-$(dirname "${BASH_SOURCE[0]}")/certs/ca.crt}"

reg_curl() {
  curl -s --ssl-no-revoke --cacert "$CA_CERT" --resolve "registry.local:5000:127.0.0.1" \
    -u "$REGISTRY_USER:$REGISTRY_PASS" "$@"
}

if ! command -v jq >/dev/null 2>&1; then
  jq() { MSYS_NO_PATHCONV=1 docker run --rm -i ghcr.io/jqlang/jq:latest "$@"; }
fi
