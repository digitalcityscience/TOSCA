#!/usr/bin/env bash
# Builds the TOSCA images from the component checkouts and writes
# versions.local.env so the stack uses them instead of the released images.
#
#   scripts/build-local.sh            all three
#   scripts/build-local.sh web        one service: django | web | geoserver
#
# The sources are ./components/<repo> after `make dev-setup`, or wherever
# BACKEND_SRC / FRONTEND_SRC / GEOSERVER_SRC point. The Dockerfiles and build
# arguments are the ones the components' release workflows use.
#
# The images are tagged :local (LOCAL_TAG=name for another tag, e.g. to build
# for a second installation on the same machine without replacing the images
# the first one uses). Each carries its checkout's commit as revision ("-dirty"
# when the checkout has uncommitted changes).
set -Eeuo pipefail
cd "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.."

: "${BACKEND_SRC:=./components/TOSCA-Backend}" "${FRONTEND_SRC:=./components/TOSCA-Frontend}" "${GEOSERVER_SRC:=./components/geoserver_docker}"

revision() {
  local sha; sha=$(git -C "$1" rev-parse HEAD)
  [[ -z $(git -C "$1" status --porcelain) ]] || sha+="-dirty"
  echo "$sha"
}
version() { echo "local-$(git -C "$1" rev-parse --short HEAD)"; }

declare -A src=([django]=$BACKEND_SRC [web]=$FRONTEND_SRC [geoserver]=$GEOSERVER_SRC)
declare -A dockerfile=([django]=docker/django/Dockerfile.prod [web]=Dockerfile [geoserver]=docker/Dockerfile)
declare -A var=([django]=BACKEND [web]=FRONTEND [geoserver]=GEOSERVER)
declare -A img=([django]=tosca-backend [web]=tosca-frontend [geoserver]=tosca-geoserver)

tag=${LOCAL_TAG:-local}
[[ $tag =~ ^[A-Za-z0-9_][A-Za-z0-9_.-]*$ ]] || { echo "Invalid LOCAL_TAG '$tag'." >&2; exit 1; }

services=("$@")
[[ $# -eq 0 ]] && services=(django web geoserver)
for s in "${services[@]}"; do
  [[ -n ${src[$s]:-} ]] || { echo "Unknown service '$s' (django, web, geoserver)." >&2; exit 1; }
  [[ -d ${src[$s]} ]] || { echo "No checkout at ${src[$s]}. Run: make dev-setup" >&2; exit 1; }
done

touch versions.local.env
for s in "${services[@]}"; do
  image=ghcr.io/digitalcityscience/${img[$s]}:$tag
  echo "== Building $image from ${src[$s]}"
  DOCKER_BUILDKIT=1 docker build \
    -f "${src[$s]}/${dockerfile[$s]}" \
    --build-arg "VERSION=$(version "${src[$s]}")" \
    --build-arg "REVISION=$(revision "${src[$s]}")" \
    -t "$image" "${src[$s]}"
  # Keep the other services' entries when building one.
  sed -i "/^${var[$s]}_IMAGE=/d" versions.local.env
  echo "${var[$s]}_IMAGE=$image" >> versions.local.env
done

echo; echo "Built:"
for s in "${services[@]}"; do
  i=ghcr.io/digitalcityscience/${img[$s]}:$tag
  printf '  %-48s %s  %s\n' "$i" "$(docker image inspect "$i" --format '{{.Id}}' | cut -c8-19)" \
    "$(docker image inspect "$i" --format '{{index .Config.Labels "org.opencontainers.image.revision"}}')"
done
echo "versions.local.env now points the stack at these images. Run: make up"
