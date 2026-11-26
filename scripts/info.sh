#!/usr/bin/env bash
# Reports on the running stack, read from the containers themselves so it
# shows what is actually running rather than what the files say.
#
#   info.sh urls       the addresses to open in a browser
#   info.sh versions   image id, version and commit of every service
#   info.sh env SERVICE NAME    one environment value of a running service
set -Eeuo pipefail
: "${COMPOSE:?run this through make}"

container() { $COMPOSE ps -q "$1" 2>/dev/null | head -n 1; }

# env_of <service> <NAME>
env_of() {
  local id; id=$(container "$1")
  [[ -n $id ]] || return 0
  docker inspect "$id" --format '{{range .Config.Env}}{{println .}}{{end}}' | sed -n "s/^$2=//p" | head -n 1
}

case ${1:-} in
  urls)
    printf '  %-10s %s\n' \
      "Web app"   "$(env_of django DJANGO_CORS_ALLOWED_ORIGINS | cut -d, -f1)" \
      "API"       "$(env_of web VITE_BACKEND_ROOT_URL)" \
      "GeoServer" "$(env_of web VITE_GEOSERVER_BASE_URL)" \
      "Storage"   "$(env_of django S3_ENDPOINT_URL)"
    ;;
  versions)
    for id in $($COMPOSE ps -q); do
      image=$(docker inspect "$id" --format '{{.Image}}')
      printf '%-10s %-58s %s  version=%s revision=%s\n' \
        "$(docker inspect "$id" --format '{{index .Config.Labels "com.docker.compose.service"}}')" \
        "$(docker inspect "$id" --format '{{.Config.Image}}' | sed 's/@sha256:\(.\{12\}\).*/@\1…/')" \
        "$(cut -c8-19 <<<"$image")" \
        "$(docker image inspect "$image" --format '{{with index .Config.Labels "org.opencontainers.image.version"}}{{.}}{{else}}-{{end}}')" \
        "$(docker image inspect "$image" --format '{{with index .Config.Labels "org.opencontainers.image.revision"}}{{.}}{{else}}-{{end}}' | cut -c1-18)"
    done | sort
    ;;
  env) env_of "$2" "$3" ;;
  *) echo "usage: info.sh urls|versions|env SERVICE NAME" >&2; exit 2 ;;
esac
