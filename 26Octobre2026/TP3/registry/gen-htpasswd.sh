#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/auth"
: > htpasswd
docker run --rm httpd:2 htpasswd -Bbn ci ci-push-2024 >> htpasswd
docker run --rm httpd:2 htpasswd -Bbn dev dev-pull-2024 >> htpasswd
