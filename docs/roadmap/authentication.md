# Authentication: where TOSCA stands and where it could go

Status: **open — no decision taken.** Nothing described under "Option" below is
implemented. This page records the current state so that a later decision
starts from facts.

## Today: TOSCA needs a Keycloak

**A clean installation does not start without Keycloak settings.** The backend
runs Django system checks on start-up and stops with:

```
(tosca.settings.E004) KEYCLOAK_ISSUER is not set.
(tosca.settings.E005) KEYCLOAK_JWKS_URL is not set.
(tosca.settings.E006) KEYCLOAK_CLIENT_ID is unset or still the local-dev default ('django-dev').
```

`make up` checks this first (`scripts/preflight.sh`) and stops with a pointer
here instead of letting the backend fail. These checks stay as they are: they
keep a production deployment from running with no way to verify tokens. They
are not switched off for tests either; the platform's integration test gives
the backend placeholder Keycloak settings (an unreachable `keycloak.invalid`
realm), which lets everything start while no token can ever be accepted — so
nobody can sign in, and every endpoint that requires a user answers 401/403.

To run TOSCA you therefore point it at an existing Keycloak realm (the
`KEYCLOAK_*` block of `.env.production`).

## Where Keycloak is used

### Backend (TOSCA-Backend)

| What | Where | Role of Keycloak |
|---|---|---|
| API authentication | `REST_FRAMEWORK.DEFAULT_AUTHENTICATION_CLASSES`: `KeycloakTokenAuthentication` (bearer JWT), then DRF `TokenAuthentication`, then `SessionAuthentication` | access tokens are verified against the realm's JWKS (`KEYCLOAK_JWKS_URL`), issuer (`KEYCLOAK_ISSUER`), audiences (`ALLOWED_TOKEN_AUDIENCES`) and clients (`ALLOWED_TOKEN_CLIENTS`) |
| Default permission | `DEFAULT_PERMISSION_CLASSES = IsAuthenticated`; public endpoints opt out explicitly | — |
| Browser login to Django admin | django-allauth `openid_connect` provider `keycloak` (PKCE), `SOCIALACCOUNT_ADAPTER = KeycloakAdapter`, `LOGIN_URL=/accounts/login/` | users sign in at Keycloak; Django creates/links the local user (`apps/authentication/identity.py`) |
| Staff and superuser | `KEYCLOAK_DJANGO_STAFF_ROLES` (`DJANGO_STAFF`, `DJANGO_SUPERADMIN`), `KEYCLOAK_DJANGO_SUPERUSER_ROLES` | Django's `is_staff` / `is_superuser` follow realm roles at every login |
| Organisation permissions | `OrgRolePermissionBackend`; roles named `ROLE_<ORG>[_<PROJECT>]_<LEVEL>` are cataloged in `KeycloakRole` (`role_registry.py`, `role_sync.py`) | object-level permissions per organisation come from Keycloak role names |
| Role catalog sync | `manage.py sync_keycloak_roles` (Keycloak Admin API, `keycloak_admin.py`), `link_keycloak_identity` | optional admin tooling |
| Start-up checks | `apps/core/checks.py` E004–E006 | refuse to start without issuer, JWKS URL and client id |
| Defaults | `settings/base.py`: `KEYCLOAK_SERVER_URL` defaults to the HCU development realm (`https://auth2.dcs.hcu-hamburg.de/`, realm `tosca-dev`, client `django-dev`) | the platform passes its own values (empty if unset), so these defaults never apply in a platform installation; they matter only for the backend's own dev stack |

`ModelBackend` is in `AUTHENTICATION_BACKENDS`, so a Django user with a local
password can already log in to `/admin/` through Django's own login form if one
is exposed — but no TOSCA flow creates such users or uses that path.

### Web app (TOSCA-Frontend)

- `oidc-client-ts` with the authorization-code flow and PKCE (`src/auth/`).
- Configured at container start through `VITE_KEYCLOAK_URL`,
  `VITE_KEYCLOAK_REALM`, `VITE_KEYCLOAK_CLIENT_ID` (all three or none). With
  none, the app shows no sign-in and only public content works.
- API calls send `Authorization: Bearer <access token>` and
  `credentials: "omit"` (`src/auth/authFetch.ts`): no cookies, so no CSRF
  token is involved today.
- Tokens are kept in browser storage by `oidc-client-ts`
  (`WebStorageStateStore`); silent renew uses the refresh token.

### GeoServer (geoserver_docker)

- The image contains the `sec-oauth2-openid-connect` community plugin; the
  platform does not configure it (`GEOSERVER_SECURITY_MODE=default`).
- GeoServer is administered with its own admin account, which the platform's
  `geoserver-init` sets from `GEOSERVER_ADMIN_PASSWORD`.
- The backend talks to GeoServer with that admin account, not with user tokens.

## Option under consideration: Django local accounts with sessions

Goal: a TOSCA installation that works on its own — people sign in with an
account stored in TOSCA's database — while Keycloak stays supported for
installations that have one.

What it would take, as far as can be seen now:

**Backend**

- A sign-in, sign-out and password-reset flow for the web app (django-allauth
  `account` is already installed and could provide it), and a way to create
  the first administrator (`createsuperuser` through a `make` target).
- Make the Keycloak checks E004–E006 conditional on Keycloak being *selected*
  (an explicit `AUTH_MODE=local|keycloak`), never on settings merely being
  empty — an installation that meant to use Keycloak must still fail loudly
  when it is misconfigured.
- Session authentication for the API from the web app's origin:
  `SESSION_COOKIE_SAMESITE`, `CSRF_TRUSTED_ORIGINS` = the web app's address,
  `CORS_ALLOW_CREDENTIALS = True` for exactly that origin, and CSRF enforced on
  every unsafe method (DRF's `SessionAuthentication` already enforces it).
- Roles and organisation permissions without Keycloak: today they are derived
  from realm role names. Local accounts need the same information stored in
  Django (groups or an explicit membership model) and one code path that both
  sources feed, so permission checks do not fork.
- Admin login (`/admin/`) through the local flow.

**Web app**

- A second auth implementation next to `oidc-client-ts`: sign-in form or
  redirect to the backend's login page, `credentials: "include"` on API calls,
  reading the `csrftoken` cookie and sending `X-CSRFToken` on unsafe requests,
  and session-expiry handling instead of token renewal.
- The runtime config selects the mode (e.g. `VITE_AUTH_MODE`).

**Cookies across origins.** TOSCA serves the web app and the API on different
ports or host names. Session cookies are only practical if both are on the
same site (e.g. `tosca.example` and `api.tosca.example`), or if the reverse
proxy serves the API under the web app's origin (`/api`). This affects the
platform's address model (`TOSCA_*_URL`) and must be decided first.

**GeoServer.** Unchanged: it keeps its own admin account; layer access for
signed-in users goes through the backend.

## Questions to decide before implementing

1. Is local authentication a supported production mode, or only for evaluation
   installations?
2. One mode per installation (`local` or `keycloak`), or both at once?
3. Same-site requirement: do we serve the API under the web app's origin, or
   require sibling host names, for session cookies?
4. Where do roles and organisation membership live when there is no Keycloak,
   and how do existing Keycloak-based installations migrate, if ever?
5. Password policy, reset by e-mail (needs SMTP settings), brute-force
   protection and account lockout.
6. Should the platform offer an optional bundled Keycloak container instead
   (more moving parts, but no second auth implementation)?

Until these are answered, nothing in the authentication or permission code is
changed, and no check is relaxed.
