#!/usr/bin/env bash
# Checks .env for the settings without which the stack cannot start, before
# anything is started, and says what to do. Run by `make up` and `make dev-up`.
set -Eeuo pipefail
cd "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.."

value() { sed -n "s/^$1=//p" .env | sed 's/[[:space:]]*#.*$//; s/[[:space:]]*$//' | tail -n 1; }
problems=()

host=$(value PUBLIC_HOST)
case $host in
  "") problems+=("PUBLIC_HOST is empty. Use tosca.localhost on one machine, or this machine's LAN address or DNS name.") ;;
  localhost|127.*|::1) problems+=("PUBLIC_HOST=$host does not work: inside a container it means the container. Use tosca.localhost instead.") ;;
esac

[[ -n $(value MAPTILER_API_KEY) ]] \
  || problems+=("MAPTILER_API_KEY is empty. The base map needs a free key from https://www.maptiler.com/.")

missing=()
for name in KEYCLOAK_ISSUER KEYCLOAK_JWKS_URL KEYCLOAK_CLIENT_ID; do
  [[ -n $(value "$name") ]] || missing+=("$name")
done
if (( ${#missing[@]} )); then
  problems+=("Sign-in is not configured (${missing[*]}). The backend does not start without a Keycloak realm; see docs/roadmap/authentication.md.")
fi

if (( ${#problems[@]} )); then
  echo "Cannot start TOSCA with this .env:" >&2
  printf '  - %s\n' "${problems[@]}" >&2
  exit 1
fi
