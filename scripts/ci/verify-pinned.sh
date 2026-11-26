#!/usr/bin/env bash
# Checks that the running TOSCA services use exactly the images pinned in
# versions.env: each container's image has the pinned digest, and its version
# label is the pinned tag. Used by the integration test when versions.env is
# pinned (release candidates and releases).
#
#   verify-pinned.sh COMPOSE_PROJECT_NAME
set -Eeuo pipefail
cd "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/../.."

project=${1:?usage: verify-pinned.sh COMPOSE_PROJECT_NAME}
get() { sed -n "s/^$1=//p" versions.env | tail -n 1; }

failed=0
for pair in django:BACKEND_IMAGE web:FRONTEND_IMAGE geoserver:GEOSERVER_IMAGE; do
  service=${pair%%:*}; ref=$(get "${pair#*:}")
  name=${ref%%:*}; rest=${ref#*:}; tag=${rest%@*}; digest=${ref#*@}
  container=$(docker ps -q --filter "label=com.docker.compose.project=$project" \
    --filter "label=com.docker.compose.service=$service" | head -n 1)
  if [[ -z $container ]]; then
    echo "FAIL $service: no running container"; failed=1; continue
  fi
  image=$(docker inspect --format '{{.Image}}' "$container")
  digests=$(docker image inspect --format '{{join .RepoDigests " "}}' "$image")
  version=$(docker image inspect --format '{{index .Config.Labels "org.opencontainers.image.version"}}' "$image")
  if [[ " $digests " != *" $name@$digest "* ]]; then
    echo "FAIL $service: image $image is not $name@$digest (has: ${digests:-none})"; failed=1
  elif [[ $version != "$tag" ]]; then
    echo "FAIL $service: image version label is '$version', versions.env says '$tag'"; failed=1
  else
    echo "ok   $service: $name:$tag@$digest"
  fi
done
exit $failed
