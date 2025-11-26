#!/bin/bash
#
# This script restores data from the containerized EPOS-MSL catalog

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

read -r -d '' RESET_MSLAPI_DB <<'EOF'
DROP DATABASE mslapi;
CREATE DATABASE mslapi;
DROP USER IF EXISTS msl;
CREATE USER 'msl'@'%' IDENTIFIED BY '$MSLAPI_DB_PASSWORD';
GRANT ALL PRIVILEGES ON mslapi.* TO 'msl'@'%';
FLUSH PRIVILEGES;
SHOW GRANTS FOR 'msl';
EOF

set -e
set -x

echo "Restoring MSL-API local storage and configuration data ..."
gunzip -c "${STAGINGDIR}/msl-api-data.tar.gz" | docker exec -i mslapi_web /bin/bash -c "tar xv -C /var/www/msl_api"

echo "Reloading MSL-API configuration into cache ..."
docker exec mslapi_web /bin/bash -c "cd /var/www/msl_api && php artisan config:cache"

echo "Restarting MSL-API queue worker ..."
docker exec mslapi_web /bin/bash -c "cd /var/www/msl_api && php artisan queue:restart"

echo "Setting up MSL-API database ..."
echo "$RESET_MSLAPI_DB" | docker exec -i mslapi_web /bin/bash -c "mysql -h mslapi_db -u root \"-p\${MYSQL_ROOT_PASSWORD}\""

echo "Restoring contents of MSL-API database ..."
gunzip -c "${STAGINGDIR}/msl-api-db.sql.gz" | docker exec -i mslapi_web /bin/bash -c "mysql -h mslapi_db -u root \"-p\${MYSQL_ROOT_PASSWORD}\" mslapi"

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

echo "Done."
