#!/usr/bin/env bash
# Checks that versions.env describes a releasable platform:
#
#   release-check.sh                 format only (no network)
#   release-check.sh --registry      also: every pinned digest exists, and each
#                                    TOSCA image's tag still points at it
#   release-check.sh --registry vYYYY.MM.N
#                                    also: TOSCA_VERSION and CHANGELOG.md match
#                                    the tag
#   release-check.sh --notes         print the component table for release notes
#
# Registry lookups use skopeo, or the skopeo container image if skopeo is not
# installed.
set -Eeuo pipefail
cd "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.."

registry=0 notes=0 tag=
for arg in "$@"; do
  case $arg in
    --registry) registry=1 ;;
    --notes) notes=1 ;;
    v*) tag=$arg ;;
    *) echo "usage: release-check.sh [--registry] [--notes] [vYYYY.MM.N]" >&2; exit 2 ;;
  esac
done

get() { sed -n "s/^$1=//p" versions.env | tail -n 1; }
problems=()
problem() { problems+=("$1"); }

skopeo_() {
  if command -v skopeo >/dev/null; then skopeo "$@"
  else docker run --rm quay.io/skopeo/stable:v1.16.1 "$@"; fi
}
# Digest of what a reference points at in its registry (the manifest list for
# multi-platform images), or nothing.
remote_digest() {
  skopeo_ inspect --raw "docker://$1" 2>/dev/null | sha256sum | cut -d' ' -f1 | sed 's/^/sha256:/' \
    | grep -v '^sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855$' || true
}

version=$(get TOSCA_VERSION)
[[ $version =~ ^20[0-9]{2}\.(0[1-9]|1[0-2])\.[1-9][0-9]*$ ]] \
  || problem "TOSCA_VERSION=$version is not a release version (YYYY.MM.N)"

declare -A component=([BACKEND_IMAGE]=TOSCA-Backend [FRONTEND_IMAGE]=TOSCA-Frontend [GEOSERVER_IMAGE]=geoserver_docker)
rows=()
for var in BACKEND_IMAGE FRONTEND_IMAGE GEOSERVER_IMAGE POSTGIS_IMAGE GARAGE_IMAGE CURL_IMAGE; do
  ref=$(get "$var")
  if [[ ! $ref =~ ^([^@:]+(:[0-9]+)?/)?[^@:]+:([^@]+)@(sha256:[0-9a-f]{64})$ ]]; then
    problem "$var=$ref is not pinned as name:tag@sha256:digest"
    continue
  fi
  name=${ref%%:*}; rest=${ref#*:}; itag=${rest%@*}; digest=${ref#*@}
  if [[ -n ${component[$var]:-} ]]; then
    case $itag in
      unreleased|latest|main|local|dev*|ci*) problem "$var uses the tag '$itag', not a release" ;;
    esac
    rows+=("| ${component[$var]} | \`$itag\` | \`$name@$digest\` | [release](https://github.com/digitalcityscience/${component[$var]}/releases/tag/v$itag) |")
  else
    rows+=("| ${name##*/} (upstream) | \`$itag\` | \`$name@$digest\` | |")
  fi
  if (( registry )); then
    [[ -n $(remote_digest "$name@$digest") ]] || { problem "$name@$digest does not exist in its registry"; continue; }
    if [[ -n ${component[$var]:-} ]]; then
      now=$(remote_digest "$name:$itag")
      [[ $now == "$digest" ]] || problem "$name:$itag now points at ${now:-nothing}, not $digest"
    fi
  fi
done

if [[ -n $tag ]]; then
  [[ ${tag#v} == "$version" ]] || problem "tag $tag does not match TOSCA_VERSION=$version"
  grep -q "^## \[$version\]" CHANGELOG.md || problem "CHANGELOG.md has no '## [$version]' section"
fi

if (( notes )); then
  echo "| Component | Version | Image | |"
  echo "|---|---|---|---|"
  printf '%s\n' "${rows[@]}"
fi

if (( ${#problems[@]} )); then
  echo "versions.env is not releasable:" >&2
  printf '  - %s\n' "${problems[@]}" >&2
  exit 1
fi
(( notes )) || echo "versions.env is releasable as $version."
