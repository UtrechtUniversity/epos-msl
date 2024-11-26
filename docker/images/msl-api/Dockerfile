# This is an image for running the MSL-API application, that is part of the EPOS-MSL catalog

# See CKAN docs on installation from Docker Compose on usage
FROM ubuntu:jammy
MAINTAINER Yoda team

# Set timezone
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Setting the locale
ENV LC_ALL=en_US.UTF-8
RUN apt-get update
RUN apt-get install --no-install-recommends -y locales
RUN sed -i "/$LC_ALL/s/^# //g" /etc/locale.gen
RUN dpkg-reconfigure --frontend=noninteractive locales
RUN update-locale LANG=${LC_ALL}

# Install required system packages
ENV COMPOSER_VERSION=2.5.4
RUN apt-get -q -y update \
    && DEBIAN_FRONTEND=noninteractive apt-get -q -y upgrade \
    && apt-get -q -y install \
       nginx \
       acl \
       git \
       nginx \
       wget \
       nmap \
       sudo \
       software-properties-common \
    && apt-add-repository ppa:ondrej/php \
    && apt-get -q -y install \
       php8.3 \
       php8.3-bcmath \
       php8.3-common \
       php8.3-curl \
       php8.3-fpm \
       php8.3-gd \
       php8.3-mbstring \
       php8.3-mysql \
       php8.3-xml \
       php8.3-zip \
       mysql-client \
       supervisor \
    && apt-get -q clean \
    && rm -rf /var/lib/apt/lists/* \
    && wget "https://getcomposer.org/download/$COMPOSER_VERSION/composer.phar" \
       -O  /usr/local/bin/composer2

ADD msl-api.site /etc/nginx/sites-enabled/msl-api
RUN rm /etc/nginx/sites-enabled/default

ADD msl-api-entrypoint.sh /msl-api-entrypoint.sh
RUN chmod +x /msl-api-entrypoint.sh

RUN cd /var/www && \
    git clone https://github.com/utrechtUniversity/msl_api --branch development && \
    chown -R www-data:www-data msl_api
USER www-data
ADD msl-api.env /var/www/msl_api/.env
ADD supervisord.conf /var/www/msl-api-supervisord.conf
ADD supervisord-webserver-only.conf /var/www/msl-api-supervisord-webserver-only.conf
RUN cd /var/www/msl_api && \
    /usr/bin/php8.3 /usr/local/bin/composer2 install
USER root
RUN chown www-data /var/www/msl_api/.env && \
    chmod 0664 /var/www/msl_api/.env && \
    mkdir /run/php

CMD ["/msl-api-entrypoint.sh"]
