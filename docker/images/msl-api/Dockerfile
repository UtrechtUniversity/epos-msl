# This is an image for running the MSL-API application, that is part of the EPOS-MSL catalog

# See CKAN docs on installation from Docker Compose on usage
FROM ubuntu:focal-20210119
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
       bash \
       sudo \
       software-properties-common \
    && apt-add-repository ppa:ondrej/php \
    && apt-get -q -y install \
       php8.0 \
       php8.0-bcmath \
       php8.0-common \
       php8.0-curl \
       php8.0-fpm \
       php8.0-gd \
       php8.0-mbstring \
       php8.0-mysql \
       php8.0-xml \
       php8.0-zip \
       mysql-client \
    && apt-get -q clean \
    && rm -rf /var/lib/apt/lists/* \
    && wget "https://getcomposer.org/download/$COMPOSER_VERSION/composer.phar" \
       -O  /usr/local/bin/composer2

ADD msl-api.site /etc/nginx/conf.d/msl-api.conf

ADD msl-api-entrypoint.sh /msl-api-entrypoint.sh
RUN chmod +x /msl-api-entrypoint.sh

RUN cd /var/www && \
    git clone https://github.com/utrechtUniversity/msl_api && \
    chown -R www-data:www-data msl_api
USER www-data
ADD msl-api.env /var/www/msl_api/.env
RUN cd /var/www/msl_api && \
    /usr/bin/php8.0 /usr/local/bin/composer2 install

USER root
CMD ["/msl-api-entrypoint.sh"]
