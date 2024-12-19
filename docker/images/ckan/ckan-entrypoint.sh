#!/bin/bash

set -u

check_port() {
    local host="$1"
    local port="$2"

    echo "Checking service availability at ${host}:${port}..."

    while true; do
        # Use nmap to scan the specified port on the given host
        nmap -p "${port}" "${host}" | grep -q "open"

        # If the port is open, exit the loop
        if [ $? -eq 0 ]; then
            echo "Server is available at ${host}:${port}"
            break
        else
            echo "Server at ${host}:${port} is not available. Retrying in 1 seconds..."
            sleep 1
        fi
    done
}

## Check DB up
check_port db 5432

## Check Solr up
check_port solr 8983

## Check Redis up
check_port redis 6379

## Initialize CKAN config, database and admin account
CKAN_CONFIG_FILE=/etc/ckan/default/ckan.ini
CKAN_INIT_STATUS_FILE=/etc/ckan/default/.ckan_initialized

if test -f "$CKAN_INIT_STATUS_FILE"
then echo "Configuration and database already initialized."
else echo "Initializing configuration ..."
     export BEAKER_SESSION_SECRET=$(openssl rand -base64 32)
     export SECRET_TOKEN_VALUE=$(openssl rand -base64 32)
     export APP_INSTANCE_UUID=$(uuidgen --name "$EPOS_MSL_FQDN" --namespace "@url" --sha1)
     export CKAN_DATABASE_PASSWORD=$(pwgen -n 16 -N 1)
     export CKAN_MSL_VOCABULARIES_ENDPOINT="https://${EPOS_MSL_FQDN}/webservice/api/vocabularies"
     perl -pi.bak -e '$beaker_session_secret=$ENV{BEAKER_SESSION_SECRET}; s/BEAKER_SESSION_SECRET/$beaker_session_secret/ge' "$CKAN_CONFIG_FILE"
     perl -pi.bak -e '$secret_token=$ENV{SECRET_TOKEN_VALUE}; s/SECRET_TOKEN_VALUE/$secret_token/ge' "$CKAN_CONFIG_FILE"
     perl -pi.bak -e '$app_instance_uuid=$ENV{APP_INSTANCE_UUID}; s/APP_INSTANCE_UUID/$app_instance_uuid/ge' "$CKAN_CONFIG_FILE"
     perl -pi.bak -e '$ckan_database_password=$ENV{CKAN_DATABASE_PASSWORD}; s/CKAN_DATABASE_PASSWORD/$ckan_database_password/ge' "$CKAN_CONFIG_FILE"
     perl -pi.bak -e '$epos_msl_fqdn=$ENV{EPOS_MSL_FQDN}; s/EPOS_MSL_FQDN/$epos_msl_fqdn/ge' "$CKAN_CONFIG_FILE"
     perl -pi.bak -e '$ckan_msl_vocabularies_endpoint=$ENV{CKAN_MSL_VOCABULARIES_ENDPOINT}; s/CKAN_MSL_VOCABULARIES_ENDPOINT/$ckan_msl_vocabularies_endpoint/ge' "$CKAN_CONFIG_FILE"
     echo "Initializing database ..."
     /usr/lib/ckan/default/bin/ckan -c "$CKAN_CONFIG_FILE" db init
     /usr/lib/ckan/default/bin/ckan -c "$CKAN_CONFIG_FILE" user add ckanadmin password="$CKAN_ADMIN_PASSWORD" email=ckanadmin@localhost name=ckanadmin
     /usr/lib/ckan/default/bin/ckan -c "$CKAN_CONFIG_FILE" user add mslapi password="$CKAN_MSLAPI_PASSWORD" email=mslapi@localhost name=mslapi
     /usr/lib/ckan/default/bin/ckan -c "$CKAN_CONFIG_FILE" sysadmin add ckanadmin
     /usr/lib/ckan/default/bin/ckan -c "$CKAN_CONFIG_FILE" sysadmin add mslapi
     sudo chown ckan /ckan_api_key
     /usr/lib/ckan/default/bin/ckan -c "$CKAN_CONFIG_FILE" user token add mslapi mslapi | tail -1 | sed 's/^\t//' > /ckan_api_key/api.key
     touch "$CKAN_INIT_STATUS_FILE"
     echo "Configuration and database initialization finished."
fi

## Start CKAN
echo "Starting CKAN ..."
while true
do /usr/lib/ckan/default/bin/uwsgi -i /etc/ckan/default/ckan-uwsgi.ini
   sleep 1
   echo "CKAN process terminated; trying to restart ..."
done
