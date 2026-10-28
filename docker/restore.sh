#!/bin/bash
#
# This script restores data from the containerized EPOS-MSL catalog
#
# Usage: restore.sh [--no-config-restore] [BACKUPDIRECTORY]
#
# If no backup directory provided, the current directory is used.

if [ "$1" = "--no-config-restore" ]
then shift
     CONFIGRESTORE="0"
else
     CONFIGRESTORE="1"
fi

STAGINGDIR="$1"

source ./.env

if [ -z "$STAGINGDIR" ]
then echo "No staging dir provided. Setting it to current working directory."
     STAGINGDIR="."
fi

read -r -d '' RESET_CKAN_DB <<'EOF'
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;
EOF

# The MSL-API database is reset using the local superuser connection inside the
# database container. The password of the database user is passed as a psql variable.
read -r -d '' RESET_MSLAPI_DB <<'EOF'
DROP DATABASE IF EXISTS mslapi WITH (FORCE);
SELECT 'CREATE ROLE msl LOGIN' WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'msl')\gexec
ALTER ROLE msl WITH LOGIN PASSWORD :'pw';
CREATE DATABASE mslapi OWNER msl;
EOF

# MSL-API used MySQL before switching to PostgreSQL. Database backups from that
# period cannot be restored with this script.
if gunzip -c "${STAGINGDIR}/msl-api-db.sql.gz" | head -n 5 | grep -q "MySQL dump"
then echo "Error: ${STAGINGDIR}/msl-api-db.sql.gz is a MySQL backup. MSL-API now uses PostgreSQL," >&2
     echo "so this backup has to be migrated before it can be restored." >&2
     exit 1
fi

# Exported so that it can be passed to the database container without showing it in the trace output
export MSLAPI_DB_PASSWORD

set -e
set -x

if [ "$CONFIGRESTORE" = 1 ]
then    echo "Restoring MSL-API local storage and configuration data ..."
        gunzip -c "${STAGINGDIR}/msl-api-data.tar.gz" | docker exec -i mslapi_web /bin/bash -c "tar xv --anchored --exclude storage/app -C /var/www/msl_api"
else    echo "Restoring MSL-API local storage (without configuration data) ..."
	gunzip -c "${STAGINGDIR}/msl-api-data.tar.gz" | docker exec -i mslapi_web /bin/bash -c "tar xv --anchored --exclude storage/app --exclude .env -C /var/www/msl_api"
fi

echo "Ensuring MSL-API uses PostgreSQL for its database ..."
docker exec -u www-data mslapi_web /configure-database.sh

echo "Ensuring MSL-API uses Redis for its queue and cache ..."
docker exec -u www-data mslapi_web /configure-redis.sh

echo "Clearing MSL-API caches ..."
docker exec mslapi_web /bin/bash -c "cd /var/www/msl_api && php artisan optimize:clear"
docker exec mslapi_web /bin/bash -c "cd /var/www/msl_api && php artisan config:cache"

echo "Restarting MSL-API queue worker ..."
docker exec mslapi_web /bin/bash -c "cd /var/www/msl_api && php artisan queue:restart"

echo "Setting up MSL-API database ..."
echo "$RESET_MSLAPI_DB" | docker exec -i -e MSLAPI_DB_PASSWORD mslapi_db \
    /bin/bash -c 'psql -U postgres -d postgres -v ON_ERROR_STOP=1 -v pw="$MSLAPI_DB_PASSWORD"'

echo "Restoring contents of MSL-API database ..."
gunzip -c "${STAGINGDIR}/msl-api-db.sql.gz" | docker exec -i mslapi_db psql -U msl -d mslapi -v ON_ERROR_STOP=1

echo "Restoring CKAN local settings ..."
gunzip -c "${STAGINGDIR}/ckan-settings.tar.gz" | docker exec -i ckan /bin/bash -c "tar xv -C /etc/ckan"

echo "Setting up CKAN database ..."
echo "$RESET_CKAN_DB" |  docker exec -i ckan /bin/bash -c "PGPASSWORD=\"\$POSTGRES_PASSWORD\" psql -d ckan_default -h db -U ckan"

echo "Restoring contents of CKAN database ..."
gunzip -c "${STAGINGDIR}/ckan-db.sql.gz" | docker exec -i ckan /bin/bash -c "PGPASSWORD=\"\$POSTGRES_PASSWORD\" psql -d ckan_default -h db -U ckan"

echo "Reloading CKAN web server after database change ..."
docker restart ckan

echo "Rebuilding CKAN search index ..."
docker exec -it ckan /bin/bash -c "/usr/lib/ckan/default/bin/ckan -c /etc/ckan/default/ckan.ini search-index rebuild"

echo "Restarting the application ..."
docker compose restart

echo "Clearing MSL-API caches ..."
docker exec mslapi_web /bin/bash -c "cd /var/www/msl_api && php artisan optimize:clear"
docker exec mslapi_web /bin/bash -c "cd /var/www/msl_api && php artisan config:cache"

echo "Done."
