#!/bin/bash
#
# This script restores data from the containerized EPOS-MSL catalog

STAGINGDIR="$1"

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

set -x
gunzip -c "${STAGINGDIR}/msl-api-data.tar.gz" | docker exec -i mslapi_web /bin/bash -c "tar xv -C /var/www/msl_api"
gunzip -c "${STAGINGDIR}/msl-api-db.sql.gz" | docker exec -i mslapi_web /bin/bash -c "mysql -h mslapi_db -u msl \"-p\${MSLAPI_DB_PASSWORD}\" mslapi"
gunzip -c "${STAGINGDIR}/ckan-settings.tar.gz" | docker exec -i ckan /bin/bash -c "tar xv -C /etc/ckan"
echo "$RESET_CKAN_DB" |  docker exec -i ckan /bin/bash -c "PGPASSWORD=\"\$POSTGRES_PASSWORD\" psql -d ckan_default -h db -U ckan"
gunzip -c "${STAGINGDIR}/ckan-db.sql.gz" | docker exec -i ckan /bin/bash -c "PGPASSWORD=\"\$POSTGRES_PASSWORD\" psql -d ckan_default -h db -U ckan"
