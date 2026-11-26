#!/bin/sh
# Runs once per deploy in a curl sidecar on the Compose network:
#  1. waits until GeoServer answers HTTP;
#  2. makes the configured admin credentials work. The published GeoServer
#     image starts with the built-in admin/geoserver account and does not apply
#     GEOSERVER_ADMIN_PASSWORD itself, so the password is set here via REST;
#  3. makes GeoServer advertise its public address (proxyBaseUrl). The image
#     sets it on start only when the data directory already has a global.xml,
#     which a new installation does not have yet.
set -eu

GS=http://geoserver:8080/geoserver
: "${GEOSERVER_ADMIN_USER:?}" "${GEOSERVER_ADMIN_PASSWORD:?}"

ready=0
for _ in $(seq 1 60); do
  if curl -fsS --max-time 5 -o /dev/null "$GS/web/"; then ready=1; break; fi
  sleep 5
done
[ "$ready" = 1 ] || { echo 'GeoServer did not become HTTP-ready within 300 seconds.' >&2; exit 1; }

status() { curl -s -o /dev/null -w '%{http_code}' --max-time 10 -u "$1" "$GS/rest/about/version.json"; }

set_public_address() {
  [ -n "${GEOSERVER_PUBLIC_URL:-}" ] || return 0
  auth="$GEOSERVER_ADMIN_USER:$GEOSERVER_ADMIN_PASSWORD"
  settings=$(curl -fsS --max-time 10 -u "$auth" "$GS/rest/settings.xml")
  case $settings in
    *"<proxyBaseUrl>$GEOSERVER_PUBLIC_URL</proxyBaseUrl>"*) echo 'GeoServer public address OK.'; return 0 ;;
  esac
  echo "Setting the GeoServer public address to $GEOSERVER_PUBLIC_URL."
  # PUT replaces all global settings, so send back everything that is there
  # with only proxyBaseUrl changed (or added, on a new data directory).
  case $settings in
    *"<proxyBaseUrl>"*)
      settings=$(printf '%s' "$settings" | sed "s|<proxyBaseUrl>[^<]*</proxyBaseUrl>|<proxyBaseUrl>$GEOSERVER_PUBLIC_URL</proxyBaseUrl>|") ;;
    *)
      settings=$(printf '%s' "$settings" | sed "s|<settings>|<settings><proxyBaseUrl>$GEOSERVER_PUBLIC_URL</proxyBaseUrl>|") ;;
  esac
  printf '%s' "$settings" |
    curl -fsS --max-time 10 -u "$auth" -X PUT -H 'Content-Type: application/xml' \
      --data-binary @- "$GS/rest/settings"
  case $(curl -fsS --max-time 10 -u "$auth" "$GS/rest/settings.xml") in
    *"<proxyBaseUrl>$GEOSERVER_PUBLIC_URL</proxyBaseUrl>"*"<charset>"*|*"<charset>"*"<proxyBaseUrl>$GEOSERVER_PUBLIC_URL</proxyBaseUrl>"*) ;;
    *) echo 'Setting the GeoServer public address did not take effect.' >&2; exit 1 ;;
  esac
}

if [ "$(status "$GEOSERVER_ADMIN_USER:$GEOSERVER_ADMIN_PASSWORD")" = 200 ]; then
  echo 'GeoServer admin credentials OK.'
  set_public_address
  exit 0
fi

if [ "$GEOSERVER_ADMIN_USER" != admin ]; then
  echo "GeoServer rejects $GEOSERVER_ADMIN_USER; automatic setup only supports GEOSERVER_ADMIN_USER=admin." >&2
  exit 1
fi
if [ "$(status admin:geoserver)" != 200 ]; then
  echo 'GeoServer rejects both the configured and the default admin password; fix it manually.' >&2
  exit 1
fi

echo 'Replacing the default GeoServer admin password.'
printf '{"newPassword":"%s"}' "$GEOSERVER_ADMIN_PASSWORD" |
  curl -fsS --max-time 10 -u admin:geoserver -X PUT -H 'Content-Type: application/json' \
    --data-binary @- "$GS/rest/security/self/password"
# GeoServer reloads users.xml asynchronously; give it a moment.
for _ in $(seq 1 15); do
  if [ "$(status "$GEOSERVER_ADMIN_USER:$GEOSERVER_ADMIN_PASSWORD")" = 200 ]; then
    # GeoServer keeps accepting recently used credentials from its
    # authentication cache; a reset drops them, so the default password stops
    # working now rather than minutes later.
    curl -fsS --max-time 30 -o /dev/null -u "$GEOSERVER_ADMIN_USER:$GEOSERVER_ADMIN_PASSWORD" -X POST "$GS/rest/reset"
    [ "$(status admin:geoserver)" = 401 ] || { echo 'GeoServer still accepts the default admin password.' >&2; exit 1; }
    echo 'GeoServer admin password set.'
    set_public_address
    exit 0
  fi
  sleep 2
done
echo 'Password change did not take effect within 30 seconds.' >&2
exit 1
