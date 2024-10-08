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
    if [ "$MSLAPI_ROLE" == "WEBSERVER" ]
    then # Initialize the MSL-API database
	 mysql -u root "-p$MYSQL_ROOT_PASSWORD" -h mslapi_db -e "
CREATE DATABASE mslapi;
CREATE USER 'msl'@'%' IDENTIFIED BY 'msl';
GRANT ALL PRIVILEGES ON mslapi.* TO 'msl'@'%';
FLUSH PRIVILEGES;
"
         cd /var/www/msl_api
	 # Initialize the MSL-API application
	 set -x
	 sudo -u www-data /usr/bin/php8.0 artisan key:generate
	 sudo -u www-data /usr/bin/php8.0 artisan config:cache
         sudo -u www-data /usr/bin/php8.0 artisan migrate --force
         sudo -u www-data /usr/bin/php8.0 artisan db:seed --force
         sudo -u www-data /usr/bin/php8.0 artisan storage:link
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
     do sudo -u www-data /usr/bin/php8.0 /var/www/msl_api/artisan queue:work  --rest=1 --tries=3 --timeout=300
	sleep 3
	echo "Restarting queue worker after exit..."
     done
elif [ "$MSLAPI_ROLE" == "WEBSERVER" ]
then /usr/sbin/nginx -g 'daemon off;'
else echo "Error: unknown MSL API role: $MSLAPI_ROLE"
fi
