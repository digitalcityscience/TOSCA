#!/usr/bin/env bash
# The platform integration test: a new installation from empty volumes, started
# with `make up` and checked with `make smoke`. Used by CI and the platform
# release workflow; runs locally in a separate checkout too.
#
# The images are the ones this checkout is set to: versions.env, or
# versions.local.env after `make build-local`.
#
# Sign-in: the backend does not start without a Keycloak realm
# (docs/roadmap/authentication.md). The test gives it placeholder settings for
# an unreachable realm (keycloak.invalid). Every check stays on; no token can
# be accepted, so endpoints that need a user answer 401/403.
#
# It refuses to run where an environment file already exists, so it never
# touches a real installation.
set -Eeuo pipefail
cd "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/../.."

for f in .env .env.production .env.development; do
  [[ ! -e $f ]] || { echo "$f exists here; run the integration test in a separate checkout." >&2; exit 1; }
done

project=${CI_PROJECT_NAME:-tosca-ci}
scripts/init-env.sh >/dev/null
set_env() { sed -i "s|^$1=.*|$1=$2|" .env.production; }
set_env COMPOSE_PROJECT_NAME "$project"
set_env MAPTILER_API_KEY ci-placeholder
set_env KEYCLOAK_SERVER_URL https://keycloak.invalid/
set_env KEYCLOAK_REALM tosca
set_env KEYCLOAK_CLIENT_ID tosca-backend
set_env KEYCLOAK_ISSUER https://keycloak.invalid/realms/tosca
set_env KEYCLOAK_JWKS_URL https://keycloak.invalid/realms/tosca/protocol/openid-connect/certs
set_env ALLOWED_TOKEN_AUDIENCES tosca-backend
set_env ALLOWED_TOKEN_CLIENTS tosca-frontend
# Optional port overrides, e.g. WEB_PORT=6180 for a run next to a real install.
for p in WEB_PORT API_PORT GEOSERVER_PORT STORAGE_PORT DB_PORT; do
  [[ -z ${!p:-} ]] || set_env "$p" "${!p}"
done

status=0
make up || status=1
if [[ $status == 0 ]]; then make smoke || status=1; fi
if [[ $status == 0 ]]; then
  # A second deployment over the same volumes must be a no-op.
  make up >/dev/null || status=1
  make smoke >/dev/null || { echo "Smoke test failed after the second deployment." >&2; status=1; }
fi
make versions || true
# With released images (no versions.local.env), check that exactly the pinned
# digests and versions are running.
if [[ $status == 0 && ! -e versions.local.env ]] && ! grep -q ':unreleased$' versions.env; then
  scripts/ci/verify-pinned.sh "$project" || status=1
fi
if [[ $status != 0 ]]; then
  echo "::group::logs"
  make ps || true
  make --no-print-directory logs-once || true
  echo "::endgroup::"
fi
exit $status
