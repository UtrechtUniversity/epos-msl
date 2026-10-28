#!/bin/bash
#
# Configures MSL-API to use Redis for its queue and cache, and sets the queue
# retry timeout from MSLAPI_QUEUE_RETRY_AFTER. This also updates .env files
# that predate the Redis setup, e.g. after restoring a backup.

set -euo pipefail

ENVFILE="/var/www/msl_api/.env"
QUEUE_RETRY_AFTER="${MSLAPI_QUEUE_RETRY_AFTER:-660}"

set_setting() {
    local key="$1"
    local value="$2"
    if grep -q "^${key}=" "$ENVFILE"
    then sed -i "s@^${key}=.*@${key}=${value}@" "$ENVFILE"
    else echo "${key}=${value}" >> "$ENVFILE"
    fi
}

set_setting QUEUE_CONNECTION redis
set_setting CACHE_DRIVER redis
set_setting REDIS_HOST mslapi_redis
set_setting REDIS_PORT 6379
set_setting QUEUE_RETRY_AFTER "$QUEUE_RETRY_AFTER"
