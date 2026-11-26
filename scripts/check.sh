#!/usr/bin/env bash
# Runs the components' own checks from the checkouts, with the same scripts
# their CI uses. Everything runs in containers; the host needs only Docker.
#
#   check.sh test   backend pytest (throwaway PostGIS + Garage), web app unit
#                   tests, GeoServer image smoke test
#   check.sh lint   ruff, eslint
#
# The backend and GeoServer checks use the images this installation is set to
# (versions.local.env after `make build-local`, else versions.env).
set -Eeuo pipefail
cd "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.."
: "${BACKEND_SRC:?}" "${FRONTEND_SRC:?}" "${GEOSERVER_SRC:?}"

image() {
  local v
  v=$( { sed -n "s/^$1=//p" versions.env; [[ -f versions.local.env ]] && sed -n "s/^$1=//p" versions.local.env; } | tail -n 1)
  [[ -n $v ]] || { echo "No $1 in versions.env" >&2; exit 1; }
  echo "$v"
}
for src in "$BACKEND_SRC" "$FRONTEND_SRC" "$GEOSERVER_SRC"; do
  [[ -d $src ]] || { echo "No checkout at $src. Run: make dev-setup" >&2; exit 1; }
done

# node_modules lives in a volume, as with `make dev-up`, so packages built for
# the container never mix with the checkout's (and the mount point that
# `make dev-up` leaves in the checkout does not get in the way).
node() {
  docker run --rm --user 0:0 -v tosca-check-node-modules:/m "${DEV_NODE_IMAGE:-node:22.19.0-alpine}" \
    chown -R "$(id -u):$(id -g)" /m
  mkdir -p "$FRONTEND_SRC/node_modules"
  docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp -e CI=true \
    -v "$(readlink -f "$FRONTEND_SRC"):/app" -v tosca-check-node-modules:/app/node_modules \
    -w /app "${DEV_NODE_IMAGE:-node:22.19.0-alpine}" \
    sh -c "npm ci --no-audit --no-fund --loglevel=error && $1"
}

case ${1:-} in
  test)
    echo "== Backend tests ($(image BACKEND_IMAGE))"
    "$BACKEND_SRC/scripts/ci/run.sh" test "$(image BACKEND_IMAGE)"
    echo "== Web app tests"
    node "npm test -- --run"
    echo "== GeoServer image ($(image GEOSERVER_IMAGE))"
    "$GEOSERVER_SRC/scripts/ci/smoke-image.sh" "$(image GEOSERVER_IMAGE)"
    ;;
  lint)
    # Both run even if the first fails, so one run shows everything.
    status=0
    echo "== Backend: ruff"
    "$BACKEND_SRC/scripts/ci/run.sh" lint "$(image BACKEND_IMAGE)" || status=1
    echo "== Web app: eslint"
    node "npm run lint" || status=1
    exit $status
    ;;
  *) echo "usage: check.sh test|lint" >&2; exit 2 ;;
esac
