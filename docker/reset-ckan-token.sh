#!/bin/bash
#
# This script deletes the old CKAN MSL-API API key (if present), creates a new one
# and loads it into MSL-API. This requires that the CKAN and MSL-API
# containers are running.

set -u

## Drop old API token
docker exec -it ckan /bin/bash -c '/usr/lib/ckan/default/bin/ckan -c /etc/ckan/default/ckan.ini user token revoke mslapi' || \
	echo "Revoking old token failed. Assuming this is because token was not set yet."

set -e

## Create and load new API token
docker exec -it ckan /bin/bash -c '/usr/lib/ckan/default/bin/ckan -c /etc/ckan/default/ckan.ini user token add mslapi mslapi | tail -1 | sed 's/^\t//' > /ckan_api_key/api.key ; chmod 0770 /ckan_api_key/api.key'

## Set it in MSL-API config file
docker exec -it mslapi_web /bin/bash -c '/update-api-token.sh $(cat /ckan_api_key/api.key)'

## Reload MSL-API configuration
docker exec -it mslapi_web /bin/bash -c 'cd /var/www/msl_api ; sudo -u www-data /usr/bin/php8.3 artisan config:clear'
