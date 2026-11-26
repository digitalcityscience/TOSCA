# Releasing TOSCA

Three component releases, then a platform release that pins them. Nothing in
this process deploys to a server; installations update when their operators
run `make update`.

```
component PR ──► main ──► tag vX.Y.Z ──► release.yml: build once, test that build,
                                          push image X.Y.Z to GHCR, GitHub Release
                                                         │
TOSCA PR: versions.env = name:X.Y.Z@sha256:… ◄───────────┘
   │  Integration CI: new installation of exactly these images, make up + make smoke
   ▼
main ──► tag vYYYY.MM.N ──► release.yml: check digests in GHCR, integration test,
                             GitHub Release with the component versions
```

## 1. Release a component

In TOSCA-Backend, TOSCA-Frontend or geoserver_docker:

1. Open a pull request to `main` that sets the version (backend:
   `pyproject.toml`; web app: `package.json` and `package-lock.json`, e.g.
   `npm version X.Y.Z --no-git-tag-version`; GeoServer: nothing, the tag
   carries it) and adds a `## [X.Y.Z]` section to `CHANGELOG.md`. CI must pass.
2. After merging, tag the merge commit and push the tag:

   ```bash
   git tag -a v1.0.0 -m "tosca-backend 1.0.0"
   git push origin v1.0.0
   ```

3. The release workflow checks the tag against the version, `main` and the
   changelog, refuses a version whose image already exists, builds amd64 and
   arm64 once, tests the amd64 image from that build, pushes exactly that build
   and creates the GitHub Release. Its summary shows the image digest.

Version numbers: backend and web app use SemVer (`v1.2.3`, pre-releases
`v1.3.0-rc.1`); GeoServer uses `v<GeoServer version>-tosca.<n>`.

## 2. Release the platform

1. Open a pull request in this repository that updates `versions.env`:
   - each TOSCA image as `ghcr.io/digitalcityscience/<image>:<version>@sha256:<digest>`
     (the digest is in the component release's notes and workflow summary,
     or `skopeo inspect --raw docker://<image>:<version> | sha256sum`);
   - `TOSCA_VERSION=YYYY.MM.N` (year, month, release number in that month);
   - a `## [YYYY.MM.N]` section in `CHANGELOG.md`.

   `make release-check` checks the pins locally. The Integration workflow then
   runs a new installation of exactly these images.
2. After merging, tag and push:

   ```bash
   git tag -a v2026.12.1 -m "TOSCA 2026.12.1"
   git push origin v2026.12.1
   ```

3. The platform release workflow checks again that every digest exists and
   each tag still points at it, runs the integration test, and creates the
   GitHub Release with the component table.

## Never overwritten

- Component release workflows refuse to push an image tag that exists.
- Release tags should be protected in each repository's settings (rulesets:
  restrict updates and deletions of `v*` tags), so a tag cannot be moved to
  another commit after its release.
- GHCR keeps every pushed digest; `versions.env` pins digests, so even a
  replaced tag would not change what an installation pulls.

## Integration test details

`scripts/ci/integration.sh` creates a new `.env` with `make init`, starts the
stack with `make up`, runs `make smoke`, deploys a second time over the same
volumes and runs `make smoke` again. The backend gets placeholder settings for
an unreachable Keycloak realm, because it does not start without one (see
[roadmap/authentication.md](roadmap/authentication.md)); no check is switched
off, and nobody can sign in during the test.
