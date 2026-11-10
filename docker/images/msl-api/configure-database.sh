#!/bin/bash
#
# Configures MSL-API to use the PostgreSQL database in the mslapi_db container.

set -euo pipefail

ENVFILE="/var/www/msl_api/.env"

set_setting() {
    local key="$1"
    local value="$2"
    if grep -q "^${key}=" "$ENVFILE"
    then sed -i "s@^${key}=.*@${key}=${value}@" "$ENVFILE"
    else echo "${key}=${value}" >> "$ENVFILE"
    fi
}

set_setting DB_CONNECTION pgsql
set_setting DB_HOST mslapi_db
set_setting DB_PORT 5432
set_setting DB_DATABASE mslapi
set_setting DB_USERNAME msl
