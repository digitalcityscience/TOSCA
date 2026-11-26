#!/usr/bin/env bash
# Creates .env from .env.example and fills every "[secret]" line with a random
# value. Refuses to touch an existing .env: its secrets are already in the
# database and storage volumes, and replacing them would lock the stack out.
set -Eeuo pipefail
cd "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.."

[[ -e .env ]] && { echo ".env already exists; not changing it." >&2; exit 1; }

hex() { openssl rand -hex "$1"; }
secret_for() {
  case $1 in
    S3_ACCESS_KEY_ID)      echo "GK$(hex 12)" ;;          # Garage key id format
    S3_SECRET_ACCESS_KEY|GARAGE_RPC_SECRET) hex 32 ;;      # Garage wants 32 bytes hex
    FIELD_ENCRYPTION_KEY)  openssl rand -base64 32 | tr '+/' '-_' ;;  # Fernet key
    DJANGO_SECRET_KEY)     hex 48 ;;
    *)                     hex 24 ;;
  esac
}

umask 077
tmp=$(mktemp .env.XXXXXX)
while IFS= read -r line; do
  if [[ $line =~ ^([A-Z0-9_]+)=[[:space:]]*#\ \[secret\] ]]; then
    printf '%s=%s\n' "${BASH_REMATCH[1]}" "$(secret_for "${BASH_REMATCH[1]}")"
  else
    printf '%s\n' "$line"
  fi
done < .env.example > "$tmp"
mv "$tmp" .env
echo "Created .env with new random secrets."
echo "Now set PUBLIC_HOST and MAPTILER_API_KEY in .env, then run: make up"
