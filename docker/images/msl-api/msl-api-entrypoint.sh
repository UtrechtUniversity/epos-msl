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

## Check DB and Redis up
check_port mslapi_db 5432
check_port mslapi_redis 6379

# Ensure the MSL-API database and database user exist. This is idempotent, so that
# it also works for existing installations and after the database volume has been
# recreated. The password of the database user is (re)set to MSLAPI_DB_PASSWORD.
setup_database() {
    local dbname="$1"
    echo "Ensuring MSL-API database $dbname exists ..."
    PGPASSWORD="$MSLAPI_DB_ADMIN_PASSWORD" psql -h mslapi_db -U postgres -d postgres \
        -v ON_ERROR_STOP=1 -v pw="$MSLAPI_DB_PASSWORD" -v dbname="$dbname" <<'EOF'
SELECT 'CREATE ROLE msl LOGIN' WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'msl')\gexec
ALTER ROLE msl WITH LOGIN PASSWORD :'pw';
SELECT format('CREATE DATABASE %I OWNER msl', :'dbname') WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = :'dbname')\gexec
EOF
}

if [ "$MSLAPI_ROLE" == "WEBSERVER" ] || [ "$MSLAPI_ROLE" == "BOTH" ]
then setup_database mslapi
     if [ "$DEVELOPMENT_MODE" == "True" ]
     then # Testing database for the MSL-API test suite
          setup_database testing
     else # Remove the MSL-API production env, because otherwise it would
	  # take priority and overwrite the database configuration we're
	  # setting here, which would result in MSL-API failing to communicate
	  # with its database.
	  rm /var/www/msl_api/.env.production
     fi
fi

# The web server container initializes the database and application
# The queue worker container waits for the web server to finish initialization
SIGNALFILE="/signal/mslapi_initialized.sig"
if [ -f "$SIGNALFILE" ]
then echo "MSL-API already initialized. Proceeding with starting $MSLAPI_ROLE ..."
else
    if [ "$MSLAPI_ROLE" == "WEBSERVER" ] || [ "$MSLAPI_ROLE" == "BOTH" ]
    then # Wait until CKAN API key has been generated, then
         # add it to the config.
         CKAN_API_KEY_FILE="/ckan_api_key/api.key"
         while ! [ -s "$CKAN_API_KEY_FILE" ]
         do echo "Waiting for CKAN API key to be available ..."
                 sleep 1
         done
         export CKAN_API_KEY=$(cat "$CKAN_API_KEY_FILE")
         perl -pi.bak -e '$ckan_api_key=$ENV{CKAN_API_KEY}; s/PUT_API_TOKEN_HERE/"$ckan_api_key"/ge' "/var/www/msl_api/.env"

	 # Also configure the FAST-API key, which is passed via an environment variable
	 perl -pi.bak -e '$fast_api_token=$ENV{MSLAPI_FAST_API_TOKEN}; s/PUT_FASTAPI_TOKEN_HERE/"$fast_api_token"/ge' "/var/www/msl_api/.env"

	 # Configure MSL-API DB password here
	 perl -pi.bak -e '$mslapi_db_password=$ENV{MSLAPI_DB_PASSWORD}; s/PUT_DB_PASSWORD_HERE/"$mslapi_db_password"/ge' \
		 "/var/www/msl_api/.env"

	 # Configure email sender address
	 perl -pi.bak -e '$mail_from_address=$ENV{MSLAPI_MAIL_FROM_ADDRESS}; s/PUT_MAIL_FROM_ADDRESS_HERE/"$mail_from_address"/ge' \
		 /var/www/msl_api/.env

         # Configure Matomo parameters
         for PARAM in TRACKING_ENABLED MATOMO_HOST MATOMO_SITE_ID MATOMO_TOKEN ALLOW_INDEXING
         do echo "Replacing $PARAM in config: value ${!PARAM} ..."
            sed -i "s@${PARAM}_HERE@${!PARAM}@" /var/www/msl_api/.env
         done

	 if [ "$DEVELOPMENT_MODE" == "True" ]
	 then echo "Development mode active"
	      cd /var/www/msl_api
	      # Set uid of www-data to prevent permission issues in WSL mount
	      sudo usermod -u "$WWW_USERID" www-data
	      # Reinstall php and node packages due to fresh codebase
	      sudo -u www-data bash -c '/usr/bin/php8.3 /usr/local/bin/composer2 install'
	      sudo -u www-data bash -c 'cd /var/www/msl_api && source /var/www/.nvm/nvm.sh && npm install'
	 else echo "Development mode not active"
	 fi


	 # Configure App URL
	 if [ "$EPOS_MSL_HOST_PORT" -eq "443" ]
         then export MSLAPI_APP_URL="https://${EPOS_MSL_HOST}"
	 else export MSLAPI_APP_URL="https://${EPOS_MSL_HOST}:${EPOS_MSL_HOST_PORT}"
	 fi
         perl -pi.bak -e '$app_url=$ENV{MSLAPI_APP_URL}; s/PUT_APP_URL_HERE/"$app_url"/ge' "/var/www/msl_api/.env"

         cd /var/www/msl_api
	 # Initialize the MSL-API application
	 set -x
	 sudo -u www-data /usr/bin/php8.3 artisan key:generate
	 sudo -u www-data /usr/bin/php8.3 artisan config:cache
	 sudo -u www-data /usr/bin/php8.3 artisan optimize:clear

         # Import admin account credentials for MSL-API seeder, as configured via Ansible.
         if [ -f "/var/msl-api-seed-data/admin-passwd.csv" ]
         then cp /var/msl-api-seed-data/admin-passwd.csv /var/www/msl_api/admin-passwd.csv
              cd /var/www/msl_api
              sudo -u www-data /usr/bin/php8.3 artisan db:seed --force --class=UserSeeder
         fi

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

# Ensure PostgreSQL is used for the database and Redis for the queue and cache, also
# for existing installations whose .env file predates the PostgreSQL or Redis setup.
# The queue worker uses the same application directory, so it picks up this
# configuration as well.
if [ "$MSLAPI_ROLE" == "WEBSERVER" ] || [ "$MSLAPI_ROLE" == "BOTH" ]
then echo "Configuring database settings ..."
     sudo -u www-data /configure-database.sh
     echo "Configuring Redis settings ..."
     sudo -u www-data MSLAPI_QUEUE_RETRY_AFTER="$MSLAPI_QUEUE_RETRY_AFTER" /configure-redis.sh
     sudo -u www-data bash -c 'cd /var/www/msl_api && /usr/bin/php8.3 artisan config:cache'
fi

# We are rebuilding front-end code here because it currently needs to be rebuilt after
# MSL-API configuration changes, and build artifacts are not persisted by default.
# This step is meant as a workaround until the configuration parameters can be extracted from
# the front-end code.
if [ "$MSLAPI_ROLE" == "WEBSERVER" ] || [ "$MSLAPI_ROLE" == "BOTH" ]
then echo "Rebuilding front-end code ..."
     sudo -u www-data bash -c 'cd /var/www/msl_api && source /var/www/.nvm/nvm.sh && npm run build'
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
