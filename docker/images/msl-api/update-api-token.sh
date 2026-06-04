#!/bin/bash
export CKAN_API_KEY="$1"
perl -pi.bak -e '$ckan_api_key=$ENV{"CKAN_API_KEY"}; s/^CKAN_API_TOKEN=[\S\s]+$/CKAN_API_TOKEN= "$ckan_api_key"\n/' /var/www/msl_api/.env
