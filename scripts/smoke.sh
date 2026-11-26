#!/usr/bin/env bash
# End-to-end check of the running stack, through the same public addresses a
# browser uses. Exits non-zero if any check fails. Run it with `make smoke`.
#
# It writes one small test object to the public media bucket and deletes it.
set -Euo pipefail
: "${COMPOSE:?run this through make}"
here=$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")
info() { COMPOSE="$COMPOSE" "$here/info.sh" "$@"; }

WEB=$(info env django DJANGO_CORS_ALLOWED_ORIGINS | cut -d, -f1)
API=$(info env web VITE_BACKEND_ROOT_URL)
GS=$(info env web VITE_GEOSERVER_BASE_URL)
S3=$(info env django S3_ENDPOINT_URL)
[[ -n $WEB && -n $API && -n $GS && -n $S3 ]] || { echo "The stack is not running. Run: make up" >&2; exit 1; }

failed=0
ok()   { printf '  ok    %s\n' "$1"; }
fail() { printf '  FAIL  %s\n        %s\n' "$1" "${2:-}"; failed=1; }
# check <name> <expected> <actual>
check() { if [[ $3 == *"$2"* ]]; then ok "$1"; else fail "$1" "expected '$2', got '${3:0:200}'"; fi; }
http() { curl -sS --max-time 20 "$@" 2>&1; }
code() { curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$@"; }
header() { curl -s -D - -o /dev/null --max-time 20 "${@:2}" | tr -d '\r' | grep -i "^$1:" | head -n 1; }

echo "Web app  $WEB"
check "serves the app"                      200 "$(code "$WEB/")"
check "config.js points at this API"        "$API" "$(http "$WEB/config.js")"
check "config.js is not cached"             no-cache "$(header cache-control "$WEB/config.js")"
check "version.json names the build"        tosca-frontend "$(http "$WEB/version.json")"

echo "API      $API"
check "ready (database reachable)"          200 "$(code "$API/readyz")"
check "reports its version"                 tosca-backend "$(http "$API/api/version")"
providers=$(http "$API/api/v1/catalog/providers")
check "lists the map data providers"        '"id"' "$providers"
check "allows the web app's origin (CORS)"  "$WEB" "$(header access-control-allow-origin -H "Origin: $WEB" "$API/api/v1/catalog/providers")"
if [[ -z $(header access-control-allow-origin -H "Origin: http://other.example" "$API/api/v1/catalog/providers") ]]; then
  ok "refuses another origin (CORS)"; else fail "refuses another origin (CORS)"; fi

echo "GeoServer $GS"
# The web UI answers 302 to a client without a session cookie.
check "web UI answers"                      302 "$(code "$GS/web/")"
caps=$(http "$GS/ows?service=WMS&version=1.3.0&request=GetCapabilities")
check "WMS capabilities"                    WMS_Capabilities "$caps"
check "advertises its public address"       "$GS" "$caps"
check "allows the web app's origin (CORS)"  "$WEB" "$(header access-control-allow-origin -H "Origin: $WEB" "$GS/ows?service=WMS&version=1.3.0&request=GetCapabilities")"
check "default admin password is rejected"  401 "$(code -u admin:geoserver "$GS/rest/about/version.json")"

echo "Storage  $S3"
# The backend writes an object, signs a URL for it, and the URL is fetched
# from outside the containers the way a browser would.
url=$($COMPOSE exec -T django gosu appuser /venv/bin/python manage.py shell -c '
from django.core.files.base import ContentFile
from django.core.files.storage import storages
s = storages["media_public"]
name = s.save("smoke/tosca-smoke.txt", ContentFile(b"tosca-smoke"))
print("URL=" + s.url(name)); print("NAME=" + name)
' 2>/dev/null)
name=$(sed -n 's/^NAME=//p' <<<"$url"); url=$(sed -n 's/^URL=//p' <<<"$url")
check "backend can write an object"         smoke/ "$name"
check "signed URL uses the public address"  "$S3" "$url"
check "signed URL downloads the object"     tosca-smoke "$(http "$url")"
check "allows the web app's origin (CORS)"  "$WEB" "$(header access-control-allow-origin -H "Origin: $WEB" "$url")"
check "refuses unsigned access"             403 "$(code "${url%%\?*}")"
if [[ -n $name ]]; then
  $COMPOSE exec -T django gosu appuser /venv/bin/python manage.py shell -c "
from django.core.files.storage import storages
storages['media_public'].delete('$name')" >/dev/null 2>&1 && ok "test object removed" || fail "test object removed"
fi

echo
if [[ $failed == 0 ]]; then echo "All checks passed."; else echo "Some checks FAILED."; fi
exit $failed
