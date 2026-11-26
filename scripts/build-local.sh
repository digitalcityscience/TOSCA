#!/usr/bin/env bash
# Builds the TOSCA images from the component checkouts and writes
# versions.local.env so the stack uses them instead of the released images.
#
#   scripts/build-local.sh            all three
#   scripts/build-local.sh web        one service: django | web | geoserver
#
# The images are tagged :local. Each carries its checkout's commit as revision
# ("-dirty" when the checkout has uncommitted changes).
set -Eeuo pipefail
cd "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.."

: "${BACKEND_SRC:=./components/TOSCA-Backend}" "${FRONTEND_SRC:=./components/TOSCA-Frontend}" "${GEOSERVER_SRC:=./components/geoserver_docker}"
export BACKEND_SRC FRONTEND_SRC GEOSERVER_SRC

revision() {
  local sha; sha=$(git -C "$1" rev-parse HEAD)
  [[ -z $(git -C "$1" status --porcelain) ]] || sha+="-dirty"
  echo "$sha"
}
version() { echo "local-$(git -C "$1" rev-parse --short HEAD)"; }

declare -A src=([django]=$BACKEND_SRC [web]=$FRONTEND_SRC [geoserver]=$GEOSERVER_SRC)
declare -A var=([django]=BACKEND [web]=FRONTEND [geoserver]=GEOSERVER)
declare -A img=([django]=tosca-backend [web]=tosca-frontend [geoserver]=tosca-geoserver)

services=("${@:-django web geoserver}")
[[ $# -eq 0 ]] && services=(django web geoserver)

touch versions.local.env
for s in "${services[@]}"; do
  [[ -n ${src[$s]:-} ]] || { echo "Unknown service '$s' (django, web, geoserver)." >&2; exit 1; }
  [[ -d ${src[$s]} ]] || { echo "No checkout at ${src[$s]}. Run: make dev-setup" >&2; exit 1; }
  v=${var[$s]}
  export "${v}_IMAGE=ghcr.io/digitalcityscience/${img[$s]}:local"
  export "${v}_BUILD_VERSION=$(version "${src[$s]}")" "${v}_BUILD_REVISION=$(revision "${src[$s]}")"
  # Record it first so that a build of one service keeps the others' entries.
  sed -i "/^${v}_IMAGE=/d" versions.local.env
  echo "${v}_IMAGE=ghcr.io/digitalcityscience/${img[$s]}:local" >> versions.local.env
done

env_files=(--env-file versions.env --env-file versions.local.env)
[[ -f .env ]] && env_files+=(--env-file .env)
docker compose "${env_files[@]}" -f compose.yaml -f compose.build.yaml build "${services[@]}"

echo; echo "Built:"
for s in "${services[@]}"; do
  i=ghcr.io/digitalcityscience/${img[$s]}:local
  printf '  %-48s %s  %s\n' "$i" "$(docker image inspect "$i" --format '{{.Id}}' | cut -c8-19)" \
    "$(docker image inspect "$i" --format '{{index .Config.Labels "org.opencontainers.image.revision"}}')"
done
echo "versions.local.env now points the stack at these images. Run: make up"
