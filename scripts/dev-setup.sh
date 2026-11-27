#!/usr/bin/env bash
# Prepares a development checkout: clones the three component repositories
# into components/ (skipping the ones already there) and creates
# .env.development.
set -Eeuo pipefail
cd "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.."

org=https://github.com/digitalcityscience
mkdir -p components
for repo in TOSCA-Backend TOSCA-Frontend geoserver_docker; do
  if [[ -d components/$repo/.git ]]; then
    echo "components/$repo: already cloned"
  else
    git clone --recurse-submodules "$org/$repo.git" "components/$repo"
  fi
done

[[ -e .env.development ]] || scripts/init-env.sh development
echo
echo "Next: set MAPTILER_API_KEY and the KEYCLOAK_* block in .env.development, then"
echo "  make build-local   # once, and again after changing a Dockerfile or dependencies"
echo "  make dev-up"
