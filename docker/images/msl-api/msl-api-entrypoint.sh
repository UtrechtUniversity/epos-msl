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
check_port mslapi_db 3306

# The web server container initializes the database and application
# The queue worker container waits for the web server to finish initialization
SIGNALFILE="/signal/mslapi_initialized.sig"
if [ -f "$SIGNALFILE" ]
then echo "MSL-API already initialized. Proceeding with starting $MSLAPI_ROLE ..."
else
    if [ "$MSLAPI_ROLE" == "WEBSERVER" ] || [ "$MSLAPI_ROLE" == "BOTH" ]
    then # Initialize the MSL-API database
	 mysql -u root "-p$MYSQL_ROOT_PASSWORD" -h mslapi_db -e "
CREATE DATABASE mslapi;
CREATE USER 'msl'@'%' IDENTIFIED BY '$MSLAPI_DB_PASSWORD';
GRANT ALL PRIVILEGES ON mslapi.* TO 'msl'@'%';
FLUSH PRIVILEGES;
"

         # Wait until CKAN API key has been generated, then
         # add it to the config.
         CKAN_API_KEY_FILE="/ckan_api_key/api.key"
         while ! [ -f "$CKAN_API_KEY_FILE" ]
         do echo "Waiting for CKAN API key to be available ..."
                 sleep 1
         done
         export CKAN_API_KEY=$(cat "$CKAN_API_KEY_FILE")
         perl -pi.bak -e '$ckan_api_key=$ENV{CKAN_API_KEY}; s/PUT_API_TOKEN_HERE/"$ckan_api_key"/ge' "/var/www/msl_api/.env"

	 # Also configure the FAST-API key, which is passed via an environment variable
	 perl -pi.bak -e '$fast_api_token=$ENV{MSLAPI_FAST_API_TOKEN}; s/PUT_FASTAPI_TOKEN_HERE/"$fast_api_token"/ge' "/var/www/msl_api/.env"

	 # Configure MSL-API DB password here
	 perl -pi.bak -e '$mslapi_db_password=$ENV{MSLAPI_DB_PASSWORD}; s/PUT_MYSQL_PASSWORD_HERE/"$mslapi_db_password"/ge' \
		 "/var/www/msl_api/.env"

	 # Configure email sender address
	 perl -pi.bak -e '$mail_from_address=$ENV{MSLAPI_MAIL_FROM_ADDRESS}; s/PUT_MAIL_FROM_ADDRESS_HERE/"$mail_from_address"/ge' \
		 /var/www/msl_api/.env

	 # Configure App URL
	 if [ "$EPOS_MSL_HOST_PORT" -eq "443" ]
         then export MSLAPI_APP_URL="https://${EPOS_MSL_HOST}"
	 else export MSLAPI_APP_URL="https://${EPOS_MSL_HOST}:${EPOS_MSL_HOST_PORT}"
	 fi
         perl -pi.bak -e '$app_url=$ENV{MSLAPI_APP_URL}; s/PUT_APP_URL_HERE/"$app_url"/ge' "/var/www/msl_api/.env"

	 # Import admin account credentials for MSL-API seeder, as configured via Ansible.
	 if [ -f "/var/msl-api-seed-data/admin-passwd.csv" ]
	 then cp /var/msl-api-seed-data/admin-passwd.csv /var/www/msl_api/admin-passwd.csv
         fi

         cd /var/www/msl_api
	 # Initialize the MSL-API application
	 set -x
	 sudo -u www-data /usr/bin/php8.3 artisan key:generate
	 sudo -u www-data /usr/bin/php8.3 artisan config:cache
         sudo -u www-data /usr/bin/php8.3 artisan migrate --force
         sudo -u www-data /usr/bin/php8.3 artisan db:seed --force
         sudo -u www-data /usr/bin/php8.3 artisan storage:link
	 set +x
	 touch "$SIGNALFILE"
    elif [ "$MSLAPI_ROLE" == "QUEUE_WORKER" ]
    then while ! [ -f "$SIGNALFILE" ]
	 do echo "Waiting for web server to initialize MSL-API application ..."
            sleep 2
	 done
	 echo "MSL-API application initialized. Proceeding ..."
    else echo "Error: unknown MSL API role: $MSLAPI_ROLE"
         exit 1
    fi
fi

## Run main process
if [ "$MSLAPI_ROLE" == "QUEUE_WORKER" ]
then while true
     do echo "Starting MSL-API queue worker ..."
	sudo -u www-data /usr/bin/php8.3 /var/www/msl_api/artisan queue:work  --rest=1 --tries=3 --timeout=300
	sleep 3
	echo "Restarting queue worker after exit..."
     done
elif [ "$MSLAPI_ROLE" == "WEBSERVER" ]
then echo "Starting web server using supervisord ..."
     cp /var/www/msl-api-supervisord-webserver-only.conf /etc/supervisor/conf.d/mslapi.conf
     /usr/bin/supervisord
elif [ "$MSLAPI_ROLE" == "BOTH" ]
then echo "Starting both web server and queue worker using supervisord..."
     cp /var/www/msl-api-supervisord.conf /etc/supervisor/conf.d/mslapi.conf
     /usr/bin/supervisord
else echo "Error: unknown MSL API role: $MSLAPI_ROLE"
fi
