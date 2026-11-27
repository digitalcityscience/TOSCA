# TOSCA

[![Integration](https://github.com/digitalcityscience/TOSCA/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/digitalcityscience/TOSCA/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/digitalcityscience/TOSCA?sort=date)](https://github.com/digitalcityscience/TOSCA/releases)
[![License: MIT](https://img.shields.io/github/license/digitalcityscience/TOSCA)](LICENSE)

TOSCA is an open-source web platform for exploring and publishing urban
geodata. This repository is the place to start: it runs the whole platform
with Docker Compose and defines which component versions belong together.

| Component | Repository | Image | CI |
|---|---|---|---|
| Backend (Django API) | [TOSCA-Backend](https://github.com/digitalcityscience/TOSCA-Backend) | [`ghcr.io/digitalcityscience/tosca-backend`](https://github.com/digitalcityscience/TOSCA-Backend/pkgs/container/tosca-backend) | [![CI](https://github.com/digitalcityscience/TOSCA-Backend/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/digitalcityscience/TOSCA-Backend/actions/workflows/ci.yml) |
| Web app (Vue) | [TOSCA-Frontend](https://github.com/digitalcityscience/TOSCA-Frontend) | [`ghcr.io/digitalcityscience/tosca-frontend`](https://github.com/digitalcityscience/TOSCA-Frontend/pkgs/container/tosca-frontend) | [![CI](https://github.com/digitalcityscience/TOSCA-Frontend/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/digitalcityscience/TOSCA-Frontend/actions/workflows/ci.yml) |
| GeoServer | [geoserver_docker](https://github.com/digitalcityscience/geoserver_docker) | [`ghcr.io/digitalcityscience/tosca-geoserver`](https://github.com/digitalcityscience/geoserver_docker/pkgs/container/tosca-geoserver) | [![CI](https://github.com/digitalcityscience/geoserver_docker/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/digitalcityscience/geoserver_docker/actions/workflows/ci.yml) |
| PostgreSQL/PostGIS | upstream | `postgis/postgis` | |
| Object storage (Garage) | upstream | `dxflrs/garage` | |

The current release and its component versions are on the
[Releases](https://github.com/digitalcityscience/TOSCA/releases) page;
`versions.env` at a release tag lists the exact images.

## Run TOSCA

You need:

- Docker with the Compose plugin, `make`, `openssl`;
- a free [MapTiler](https://www.maptiler.com/) key for the base map;
- **a Keycloak realm for sign-in.** TOSCA does not start without one today;
  see [Sign-in](#sign-in).

```bash
git clone --branch v2026.11.1 https://github.com/digitalcityscience/TOSCA.git
cd TOSCA

make init          # creates .env.production with random secrets
# edit .env.production: MAPTILER_API_KEY and the KEYCLOAK_* block
make up
```

`make up` checks `.env.production` first, then prints the addresses when everything is
healthy. `make smoke` checks the running stack end to end.

On one machine the defaults are enough: the platform is at
<http://tosca.localhost:8080>. For other people to reach it, set `PUBLIC_HOST`
to the machine's LAN address or DNS name. `PUBLIC_HOST=localhost` does not
work (inside a container it means the container); any `*.localhost` name does.
Safari does not resolve `*.localhost` by itself; add
`127.0.0.1 tosca.localhost` to `/etc/hosts` for it.

### Sign-in

The backend verifies sign-ins against a Keycloak realm and refuses to start
without `KEYCLOAK_ISSUER`, `KEYCLOAK_JWKS_URL` and `KEYCLOAK_CLIENT_ID`. Fill in
the `KEYCLOAK_*` block of `.env.production` for the backend, and the `WEB_KEYCLOAK_*`
block for the web app's sign-in button. There is no built-in user database
yet; [docs/roadmap/authentication.md](docs/roadmap/authentication.md) describes
the current dependencies and the option of Django accounts being considered.

### What else to know

- **No TLS.** The stack serves plain http on the ports in `.env.production`. For a public
  server put a reverse proxy with TLS in front and set the four `TOSCA_*_URL`
  values to the https addresses.
- **PostgreSQL is published on `127.0.0.1` only.** The web app, API, GeoServer
  and storage ports listen on all interfaces (`BIND_ADDRESS`).
- On a new installation the one-shot services replace GeoServer's default
  admin password, set the address GeoServer advertises, create the media
  buckets and apply their CORS rules.

### Everyday commands

| | |
|---|---|
| `make ps`, `make logs` | what is running, and its logs |
| `make versions` | image, version and commit of every running service |
| `make backup` | dump the database to `backups/` |
| `make update` | pull the images in `versions.env`, back up, restart |
| `make down` | stop; **data volumes are kept** |

Your data lives in the Docker volumes `<project>_pg_data`,
`<project>_geoserver_data`, `<project>_garage_meta` and `<project>_garage_data`.
No `make` command deletes them. `make backup` covers the database only; back
up the Garage and GeoServer volumes separately.

To update, check out the release tag you want and run `make update`.
Database migrations are not reversible in general: going back to an older
release after an update means restoring the backup.

## Develop TOSCA

```bash
git clone https://github.com/digitalcityscience/TOSCA.git
cd TOSCA

make dev-setup     # clones the three component repositories into components/
                   # and creates .env.development
# edit .env.development: MAPTILER_API_KEY and the KEYCLOAK_* block
make build-local   # builds the three images from components/
make dev-up        # backend and web app from source, with reload on save
```

- `make dev-up ONLY=frontend` runs only the web app from source and the
  backend from its image; `ONLY=backend` is the reverse.
- Edit the code in `components/`. The web app reloads in the browser; the
  backend restarts when a Python file is saved.
- After changing dependencies or a Dockerfile: `make build-local SERVICE=django`
  (or `web`, `geoserver`). `LOCAL_TAG=name` builds under another tag than
  `:local`, e.g. for a second installation on the same machine.
- `make test` runs the components' own tests and `make lint` their linters,
  with the same scripts as their CI, in containers: backend tests against a
  throwaway PostGIS and Garage, web app unit tests, GeoServer image smoke test.
- To work on checkouts elsewhere, set `BACKEND_SRC`, `FRONTEND_SRC` and
  `GEOSERVER_SRC` in `.env.development`.

## How it fits together

```
db ──────────► migrate ───────┐
garage ──────► storage-init ──┼──► django (API)
geoserver ───► geoserver-init ┘
web (static app, configured at start)
```

| File | Purpose | In git |
|---|---|---|
| `compose.yaml` | the services and what each one is given | yes |
| `versions.env` | the platform release: exact image versions | yes |
| `.env.production` | this installation: addresses, ports, secrets | **no** |
| `.env.development` | the same for a development checkout | **no** |
| `.env.production.example`, `.env.development.example` | the templates the two files are created from | yes |
| `versions.local.env` | written by `make build-local`; use local images | no |
| `compose.override.yaml` | installation-specific additions, e.g. extra mounts | no |
| `compose.dev.*.yaml` | run a component from source | yes |

### Environment files

One naming rule in all four TOSCA repositories: the committed template is
`.env.<mode>.example`, your copy is `.env.<mode>`, and the mode is written out
in full (`production`, `development`). There is no plain `.env`, `.env.dev`,
`.env.prod` or `.env.example`.

- `make init` creates `.env.production` from `.env.production.example`;
  `make dev-setup` creates `.env.development` from `.env.development.example`.
  Both fill in random secrets.
- The `dev-*` commands read `.env.development`. Every other command reads
  `.env.production` when it exists, otherwise `.env.development`;
  `ENV=production` or `ENV=development` chooses explicitly.
- The two templates define the same variables (CI checks it): add a new
  variable to both.
- An installation made before this rule has a `.env`; rename it once:
  `mv .env .env.production`. `make` refuses to run until then.

The one-shot services are safe to run on every start: `migrate` applies
pending migrations, `storage-init` creates missing media buckets and their
CORS rules, `geoserver-init` replaces GeoServer's default admin password and
sets its public address.

## Versions and releases

| Repository | Versioning | Example tag |
|---|---|---|
| TOSCA-Backend | [SemVer](https://semver.org/) | `v1.0.0` |
| TOSCA-Frontend | SemVer | `v1.0.0` |
| geoserver_docker | GeoServer version + TOSCA revision | `v2.28.5-tosca.1` |
| TOSCA (this repository) | CalVer `YYYY.MM.N` | `v2026.12.1` |

Each component publishes its image from its own release tag, after its tests
pass on the exact image that is pushed, and creates a GitHub Release. Published
image tags are never overwritten.

A **platform release** is a tag of this repository. `versions.env` at that tag
pins the three TOSCA images that were tested together, each as
`name:version@sha256:digest`, plus the upstream images. The release workflow
([`release.yml`](.github/workflows/release.yml)) refuses to publish unless every
image exists in its registry with exactly that digest and the integration test
passes against them; it then creates a GitHub Release listing the component
versions. It deploys nothing: installations update with `make update` when
their operators decide to. The steps are in
[docs/releasing.md](docs/releasing.md); the changes are in
[CHANGELOG.md](CHANGELOG.md).

`/api/version` on the API and `/version.json` on the web app report what a
running installation actually serves; `make versions` shows all services.

## License

[MIT](LICENSE)
