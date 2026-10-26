#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/certs"

openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 \
  -subj "/O=Shop SAS/CN=Shop SAS Internal CA" -out ca.crt

openssl genrsa -out server.key 2048
openssl req -new -key server.key -subj "/O=Shop SAS/CN=registry.local" -out server.csr

cat > server.ext <<EXT
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = DNS:registry.local, DNS:registry, DNS:localhost, IP:127.0.0.1
EXT

openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out server.crt -days 825 -sha256 -extfile server.ext
rm -f server.csr server.ext ca.srl
