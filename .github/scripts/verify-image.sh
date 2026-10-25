#!/usr/bin/env bash
set -euo pipefail

image="${1:?Usage: verify-image.sh IMAGE}"
container="m-project-smoke-${GITHUB_RUN_ID:-local}"
response="$(mktemp)"

cleanup() {
  docker rm --force "$container" >/dev/null 2>&1 || true
  rm -f "$response"
}
trap cleanup EXIT

docker build --tag "$image" .
docker run --detach --rm --name "$container" --publish 127.0.0.1:8080:80 "$image" >/dev/null

curl --fail --silent --show-error --retry 10 --retry-connrefused --retry-delay 1 \
  http://127.0.0.1:8080/ --output /dev/null

status="$(curl --silent --show-error --output "$response" --write-out '%{http_code}' \
  http://127.0.0.1:8080/this-page-does-not-exist)"
test "$status" = "404"
cmp html/404.html "$response"
