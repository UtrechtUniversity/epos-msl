#!/bin/bash
#
# This script backs up data from the containerized EPOS-MSL catalog

source ./.env

STAGINGDIR="$1"

if [ -z "$STAGINGDIR" ]
then echo "No staging dir provided. Setting it to current working directory."
     STAGINGDIR="."
fi

docker exec mslapi_web /bin/bash -c "cd /var/www/msl_api && tar cv .env storage" | gzip -9 > "${STAGINGDIR}/msl-api-data.tar.gz"
docker exec mslapi_web /bin/bash -c "mysqldump -h mslapi_db -u root "-p$MYSQL_ROOT_PASSWORD" mslapi" | gzip -9 > "${STAGINGDIR}/msl-api-db.sql.gz"
docker exec ckan /bin/bash -c "cd /etc/ckan; tar cv default" | gzip -9 > "${STAGINGDIR}/ckan-settings.tar.gz"
docker exec ckan /bin/bash -c "PGPASSWORD=\"\$POSTGRES_PASSWORD\" pg_dump -d ckan_default -h db -U ckan" | gzip -9 > "${STAGINGDIR}/ckan-db.sql.gz"
