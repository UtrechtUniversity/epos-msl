#!/bin/bash

## Only include mailpit rev proxy configuration is mailpit is enabled.
if [ "$MTA_ROLE" == "mailpit" ]
then cat /etc/nginx/nginx.site.part1 /etc/nginx/nginx.site.part-mailpit /etc/nginx/nginx.site.part2 > /etc/nginx/conf.d/nginx.conf
else cat /etc/nginx/nginx.site.part1 /etc/nginx/nginx.site.part2 > /etc/nginx/conf.d/nginx.conf
fi

# Import certificates if available in import bind mount. Otherwise generate
# a self-signed certificate

CERTIFICATE_IMPORTDIR=/etc/import-certificates
CERTIFICATE_DIR=/etc/certificates
cd "$CERTIFICATE_DIR"

if [ -f "${CERTIFICATE_IMPORTDIR}/epos-msl.pem" ] && [ -f "${CERTIFICATE_IMPORTDIR}/epos-msl.key" ]
then echo "Importing TLS certificate ..."
     cp "${CERTIFICATE_IMPORTDIR}/epos-msl.pem" "${CERTIFICATE_DIR}/epos-msl.pem"
     cp "${CERTIFICATE_IMPORTDIR}/epos-msl.key" "${CERTIFICATE_DIR}/epos-msl.key"
else if [ -f "epos-msl.pem" ]
     then echo "Skipping certificate generation, because certificate files are already present."
     else echo "Generating certificates for reverse proxy  at https://$EPOS_MSL_HOST ..."
	  export EPOS_MSL_HOST="$EPOS_MSL_HOST"
          perl -pi.bak -e '$epos_msl_host=$ENV{EPOS_MSL_HOST}; s/EPOS_MSL_HOST/$epos_msl_host/ge' /etc/certificates/epos-msl.cnf
          openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes -keyout epos-msl.key -out epos-msl.pem -config epos-msl.cnf
     echo "Certificate generation complete."
     fi
fi

if [ -f "dhparams.pem" ]
then echo "Skipping DHParam generation, because DHParam file is already present."
else echo "Generating DHParam configuration..."
     openssl dhparam -dsaparam -out "${CERTIFICATE_DIR}/dhparams.pem" 4096
     echo "DHParam generation complete."
fi

# Configure host header for reverse proxy
if [ "$EPOS_MSL_HOST_PORT" -eq "443" ]
then export HOST_HEADER="${EPOS_MSL_HOST}"
else export HOST_HEADER="${EPOS_MSL_HOST}:${EPOS_MSL_HOST_PORT}"
fi
perl -pi.bak -e '$host_header=$ENV{HOST_HEADER}; s/PUT_HOST_HEADER_HERE/"$host_header"/ge' "/etc/nginx/conf.d/nginx.conf"

## Run Nginx
nginx -g "daemon off;"
