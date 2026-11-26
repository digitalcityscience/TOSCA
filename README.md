# TOSCA

TOSCA is an open-source web platform for exploring and publishing urban
geodata. This repository is the place to start: it runs the whole platform
with Docker Compose and defines which component versions belong together.

| Component | Repository | Image |
|---|---|---|
| Backend (Django API) | [TOSCA-Backend](https://github.com/digitalcityscience/TOSCA-Backend) | `ghcr.io/digitalcityscience/tosca-backend` |
| Web app (Vue) | [TOSCA-Frontend](https://github.com/digitalcityscience/TOSCA-Frontend) | `ghcr.io/digitalcityscience/tosca-frontend` |
| GeoServer | [geoserver_docker](https://github.com/digitalcityscience/geoserver_docker) | `ghcr.io/digitalcityscience/tosca-geoserver` |
| PostgreSQL/PostGIS | upstream | `postgis/postgis` |
| Object storage (Garage) | upstream | `dxflrs/garage` |

> **Status: not released yet.** The three TOSCA images have not been published
> to GHCR, so `make up` cannot pull them. Until the first release, build them
> from source: follow [Develop TOSCA](#develop-tosca) up to `make build-local`,
> then `make up`.

## Run TOSCA

You need Docker with the Compose plugin, `make`, `openssl`, and a free
[MapTiler](https://www.maptiler.com/) key for the base map.

```bash
git clone https://github.com/digitalcityscience/TOSCA.git
cd TOSCA

make init          # creates .env with random secrets
# edit .env: set PUBLIC_HOST and MAPTILER_API_KEY
make up
```

`make up` prints the addresses when everything is healthy. `make smoke` checks
the running stack end to end.

`PUBLIC_HOST` is the name or IP address people type in the browser. It must
also be reachable from inside the containers, so use the machine's LAN address
or DNS name, not `localhost`.

### What you get, and what you do not

- **Sign-in is off until you connect a Keycloak.** Without one the map is
  public and nobody can log in, including to the admin pages. Fill in the
  Keycloak block in `.env` to connect an existing Keycloak.
- **No TLS.** The stack serves plain http on the ports in `.env`. For a public
  server put a reverse proxy with TLS in front and set the four `TOSCA_*_URL`
  values to the https addresses.
- **PostgreSQL is published on `127.0.0.1` only.** The web app, API, GeoServer
  and storage ports listen on all interfaces (`BIND_ADDRESS`).

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
# edit .env: set PUBLIC_HOST and MAPTILER_API_KEY
make build-local   # builds the three images from components/
make dev-up        # backend and web app from source, with reload on save
```

- `make dev-up ONLY=frontend` runs only the web app from source and the
  backend from its image; `ONLY=backend` is the reverse.
- Edit the code in `components/`. The web app reloads in the browser; the
  backend restarts when a Python file is saved.
- After changing dependencies or a Dockerfile: `make build-local SERVICE=django`
  (or `web`, `geoserver`).
- `make test` and `make lint` run the components' own tests and linters.
- To work on checkouts elsewhere, set `BACKEND_SRC`, `FRONTEND_SRC` and
  `GEOSERVER_SRC` in `.env`.

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
| `.env` | this installation: addresses, ports, secrets | **no** |
| `versions.local.env` | written by `make build-local`; use local images | no |
| `compose.override.yaml` | installation-specific additions, e.g. extra mounts | no |
| `compose.build.yaml` | adds `build:` for building from source | yes |
| `compose.dev.*.yaml` | run a component from source | yes |

The one-shot services are safe to run on every start: `migrate` applies
pending migrations, `storage-init` creates missing media buckets and their
CORS rules, `geoserver-init` replaces GeoServer's default admin password.

## Versions

Each component has its own version. A platform release is a tag of this
repository; `versions.env` at that tag pins the images that were tested
together, each as `name:tag@sha256:digest`.

`/api/version` on the API and `/version.json` on the web app report what a
running installation actually serves.
