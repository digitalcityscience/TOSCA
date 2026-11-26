#!/bin/sh
# Runs once per deploy in a curl sidecar on the Compose network:
#  1. waits until GeoServer answers HTTP;
#  2. makes the configured admin credentials work. The published GeoServer
#     image starts with the built-in admin/geoserver account and does not apply
#     GEOSERVER_ADMIN_PASSWORD itself, so the password is set here via REST.
set -eu

GS=http://geoserver:8080/geoserver
: "${GEOSERVER_ADMIN_USER:?}" "${GEOSERVER_ADMIN_PASSWORD:?}"

ready=0
for attempt in $(seq 1 60); do
  if curl -fsS --max-time 5 -o /dev/null "$GS/web/"; then ready=1; break; fi
  sleep 5
done
[ "$ready" = 1 ] || { echo 'GeoServer did not become HTTP-ready within 300 seconds.' >&2; exit 1; }

status() { curl -s -o /dev/null -w '%{http_code}' --max-time 10 -u "$1" "$GS/rest/about/version.json"; }

[ "$(status "$GEOSERVER_ADMIN_USER:$GEOSERVER_ADMIN_PASSWORD")" = 200 ] && { echo 'GeoServer admin credentials OK.'; exit 0; }

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
for attempt in $(seq 1 15); do
  [ "$(status "$GEOSERVER_ADMIN_USER:$GEOSERVER_ADMIN_PASSWORD")" = 200 ] && { echo 'GeoServer admin password set.'; exit 0; }
  sleep 2
done
echo 'Password change did not take effect within 30 seconds.' >&2
exit 1
