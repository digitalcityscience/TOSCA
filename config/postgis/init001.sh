#!/bin/bash
set -e

############################################
# ENV
############################################
API_USER="${PG_API_USER:-tosca_api}"
API_PASS="${PG_API_PASSWORD:-postgres_api}"

GS_USER="${PG_GS_USER:-tosca_gs}"
GS_PASS="${PG_GS_PASSWORD:-postgres_gs}"

SCHEMA_API="${PG_SCHEMA_API:-api_schema}"
SCHEMA_GS="${PG_SCHEMA_GEOSERVER:-gs_auth_role_schema}"
SCHEMA_GIS="${PG_SCHEMA_GIS:-gis_schema}"
SCHEMA_JDBCCONF="${PG_SCHEMA_JDBCCONF:-gs_jdbcconfig_schema}"

echo "Initializing database schemas:"
echo "  API        -> $SCHEMA_API"
echo "  GeoServer  -> $SCHEMA_GS"
echo "  JDBCConfig -> $SCHEMA_JDBCCONF"
echo "  GIS        -> $SCHEMA_GIS"

echo "Creating users:"
echo "  API User -> $API_USER"
echo "  GS User  -> $GS_USER"

############################################
# INIT
############################################
psql -v ON_ERROR_STOP=1 \
  --username "$POSTGRES_USER" \
  --dbname "$POSTGRES_DB" <<-EOSQL

-- 0) PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;

-- 1) Schemas
CREATE SCHEMA IF NOT EXISTS $SCHEMA_API;
CREATE SCHEMA IF NOT EXISTS $SCHEMA_GS;
CREATE SCHEMA IF NOT EXISTS $SCHEMA_JDBCCONF;
CREATE SCHEMA IF NOT EXISTS $SCHEMA_GIS;

-- 2) Roles
-- Passwords are deliberately set only when a role is first created. The
-- database volume outlives containers, so rotations must be an explicit
-- operation: make reconcile-postgis-service-passwords CONFIRM=1.
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '$API_USER') THEN
    CREATE ROLE $API_USER LOGIN PASSWORD '$API_PASS';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '$GS_USER') THEN
    CREATE ROLE $GS_USER LOGIN PASSWORD '$GS_PASS';
  END IF;
END
\$\$;

-- 3) Permissions
GRANT ALL ON SCHEMA $SCHEMA_GS       TO $GS_USER;
GRANT ALL ON SCHEMA $SCHEMA_JDBCCONF TO $GS_USER;
GRANT ALL ON SCHEMA $SCHEMA_GIS      TO $GS_USER;

GRANT ALL ON SCHEMA $SCHEMA_API TO $API_USER;

-- 4) search_path
ALTER ROLE $API_USER SET search_path = $SCHEMA_API, public;
ALTER ROLE $GS_USER  SET search_path = $SCHEMA_GS, $SCHEMA_JDBCCONF, $SCHEMA_GIS, public;

-- 5) public / PostGIS base permissions (spatial_ref_sys etc.)
GRANT SELECT ON ALL TABLES IN SCHEMA public TO $GS_USER;
GRANT SELECT ON spatial_ref_sys TO $GS_USER;

GRANT CREATE ON SCHEMA public TO $GS_USER;
GRANT ALL ON ALL TABLES    IN SCHEMA public TO $GS_USER;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO $GS_USER;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT ALL ON TABLES TO $GS_USER;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT ALL ON SEQUENCES TO $GS_USER;

-- 6) gis_schema — existing + future objects
GRANT ALL ON ALL TABLES    IN SCHEMA $SCHEMA_GIS TO $GS_USER;
GRANT ALL ON ALL SEQUENCES IN SCHEMA $SCHEMA_GIS TO $GS_USER;

ALTER DEFAULT PRIVILEGES IN SCHEMA $SCHEMA_GIS
  GRANT ALL ON TABLES TO $GS_USER;

ALTER DEFAULT PRIVILEGES IN SCHEMA $SCHEMA_GIS
  GRANT ALL ON SEQUENCES TO $GS_USER;

EOSQL

echo "Database initialization completed successfully."
