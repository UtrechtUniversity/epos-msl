#!/bin/bash

## Adapt URL in config
export EPOS_MSL_HOST="$EPOS_MSL_HOST"
perl -pi.bak -e '$epos_msl_host=$ENV{EPOS_MSL_HOST}; s/EPOS_MSL_HOST/$epos_msl_host/ge' /etc/certificates/epos-msl.cnf

## Generate certificates if needed
cd /etc/certificates
if [ -f "epos-msl.pem" ]
then echo "Skipping certificate generation, because certificate files are already present."
else echo "Generating certificates for reverse proxy  at https://$EPOS_MSL_HOST ..."
     openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes -keyout epos-msl.key -out epos-msl.pem -config epos-msl.cnf
     echo "Certificate generation complete."
fi

if [ -f "dhparam.pem" ]
then echo "Skipping DHParam generation, because DHParam file is already present."
else echo "Generating DHParam configuration..."
     openssl dhparam -dsaparam -out dhparams.pem 4096
     echo "DHParam generation complete."
fi

## Run Nginx
nginx -g "daemon off;"
