# Changelog

Platform releases of TOSCA. Each one pins the component images that were
tested together (see `versions.env` at the release tag). Versions are
`YYYY.MM.N`; see [docs/releasing.md](docs/releasing.md).

## [Unreleased]

### Changed
- Environment files are named `.env.<mode>` with the mode written out, as in
  every TOSCA repository. An installation's settings are in `.env.production`
  (was `.env`), created by `make init` from `.env.production.example` (was
  `.env.example`). A development checkout uses `.env.development`, created by
  `make dev-setup` from `.env.development.example`.

### Upgrading
- Rename the settings file once before the first `make` command:
  `mv .env .env.production`. `make` refuses to run until then, so an
  installation cannot start without its settings.

## [2026.11.1] - 2026-11-26

First platform release. It pins the first versioned component images, built
from the code that runs the NGCN installation:

| Component | Version |
|---|---|
| TOSCA-Backend | 1.0.0 |
| TOSCA-Frontend | 1.0.0 |
| tosca-geoserver | 2.28.5-tosca.1 |
| PostGIS | 16-3.4 (upstream) |
| Garage | v2.3.0 (upstream) |

### Added
- Docker Compose stack for the whole platform with `make` commands to run,
  update, back up and develop it; `versions.env` pins the component images.
- Upstream Garage with a static configuration; buckets and CORS are created by
  the backend's `init_storage`, without a Garage admin token.
- `make init` writes a `.env` with random secrets; `make up` checks it first.
- `PUBLIC_HOST=tosca.localhost` works on a single machine: browsers and the
  backend containers reach the same storage address.
- A new GeoServer data directory gets the public address and a non-default
  admin password on first start.
- `make dev-up` runs the backend and the web app from source with reload on
  save; `make test` and `make lint` run the components' checks in containers.
- Integration CI: a new installation with `make up` and `make smoke`.
- Platform release workflow: publishes only when every pinned image exists
  with its digest and the integration test passes; deploys nothing.

### Known limitations
- The backend does not start without a Keycloak realm; see
  [docs/roadmap/authentication.md](docs/roadmap/authentication.md).
