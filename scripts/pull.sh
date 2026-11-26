#!/usr/bin/env bash
# Downloads the images of this release. Images that versions.local.env points
# at (built by `make build-local`) exist only on this machine and are skipped.
set -Eeuo pipefail
: "${COMPOSE:?run this through make}"
cd "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.."

declare -A services=(
  [BACKEND_IMAGE]="django migrate storage-init"
  [FRONTEND_IMAGE]="web"
  [GEOSERVER_IMAGE]="geoserver"
)
pull=(db garage geoserver-init)
for var in "${!services[@]}"; do
  if [[ -f versions.local.env ]] && grep -q "^$var=" versions.local.env; then
    echo "Skipping ${services[$var]}: local image $(sed -n "s/^$var=//p" versions.local.env)"
  else
    read -ra s <<<"${services[$var]}"
    pull+=("${s[@]}")
  fi
done
$COMPOSE pull "${pull[@]}"
