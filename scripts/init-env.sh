#!/usr/bin/env bash
# Creates .env.<mode> from .env.<mode>.example and fills every "[secret]" line
# with a random value.
#
#   scripts/init-env.sh               .env.production   (an installation; `make init`)
#   scripts/init-env.sh development   .env.development  (`make dev-setup`)
#
# Refuses to touch an existing file: its secrets are already in the database
# and storage volumes, and replacing them would lock the stack out.
set -Eeuo pipefail
cd "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.."

mode=${1:-production}
[[ $mode == production || $mode == development ]] \
  || { echo "usage: init-env.sh [production|development]" >&2; exit 2; }
file=.env.$mode

[[ -e $file ]] && { echo "$file already exists; not changing it." >&2; exit 1; }

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
tmp=$(mktemp .env.tmp.XXXXXX)
while IFS= read -r line; do
  if [[ $line =~ ^([A-Z0-9_]+)=[[:space:]]*#\ \[secret\] ]]; then
    printf '%s=%s\n' "${BASH_REMATCH[1]}" "$(secret_for "${BASH_REMATCH[1]}")"
  else
    printf '%s\n' "$line"
  fi
done < "$file.example" > "$tmp"
mv "$tmp" "$file"
echo "Created $file with new random secrets."
if [[ $mode == production ]]; then
  echo "Now set PUBLIC_HOST and MAPTILER_API_KEY in $file, then run: make up"
fi
