# This is a locally modified version of the upstream CKAN Dockerfile

# See CKAN docs on installation from Docker Compose on usage
FROM ubuntu:focal-20210119
MAINTAINER Yoda team

# Set timezone
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Setting the locale
ENV LC_ALL=en_US.UTF-8
RUN adduser ckan
RUN apt-get update
RUN apt-get install --no-install-recommends -y locales
RUN sed -i "/$LC_ALL/s/^# //g" /etc/locale.gen
RUN dpkg-reconfigure --frontend=noninteractive locales
RUN update-locale LANG=${LC_ALL}

# Install required system packages
RUN apt-get -q -y update \
    && DEBIAN_FRONTEND=noninteractive apt-get -q -y upgrade \
    && apt-get -q -y install \
        python3.8 \
        python3-dev \
        python3-pip \
        python3-venv \
        python3-wheel \
        libpq-dev \
        python3-pastescript \
        python3-virtualenv \
        libxml2-dev \
        libxslt-dev \
        libgeos-dev \
        libssl-dev \
        libffi-dev \
        postgresql-client \
        build-essential \
        git-core \
        vim \
        bash \
        wget \
        curl \
        nmap \
        sqlite3 \
        pwgen \
        uuid-runtime \
    && apt-get -q clean \
    && rm -rf /var/lib/apt/lists/*

# Define environment variables
ENV CKAN_HOME /usr/lib/ckan
ENV CKAN_VENV $CKAN_HOME/default
ENV CKAN_CONFIG /etc/ckan
ENV CKAN_STORAGE_PATH=/ckanstorage
ENV CKAN_VERSION=2.9.11
ENV CKAN_SCHEMING_VERSION=release-2.1.0
ENV CKAN_MSL_CORE_VERSION=1.4.0
ENV CKAN_MSL_UTIL_VERSION=1.0.0

# Create storage path
RUN mkdir -p $CKAN_STORAGE_PATH/webassets $CKAN_STORAGE_PATH/storage

# Build-time variables specified by docker-compose.yml / .env
ARG CKAN_SITE_URL

# Setup virtual environment for CKAN
RUN mkdir -p $CKAN_VENV $CKAN_CONFIG/default && \
    python3 -m venv $CKAN_VENV && \
    ln -s $CKAN_VENV/bin/pip3 /usr/local/bin/ckan-pip3 &&\
    ln -s $CKAN_VENV/bin/ckan /usr/local/bin/ckan
ADD ckan.ini /etc/ckan/default/ckan.ini
ADD who.ini /etc/ckan/default/who.ini
ADD wsgi.py /etc/ckan/default/wsgi.py
ADD ckan-uwsgi.ini /etc/ckan/default/ckan-uwsgi.ini

# Virtual environment binaries/scripts to be used first
ENV PATH=${CKAN_VENV}/bin:${PATH}
ENV EPOS_MSL_FQDN=epos-msl.local
ENV CKAN_ADMIN_PASSWORD="testtest"

# Install CKAN and plugins
RUN ckan-pip3 install -U pip && \
    ckan-pip3 install setuptools==44.1.0 && \
    ckan-pip3 install --upgrade pip && \
    ckan-pip3 install wheel && \
    ckan-pip3 install -e "git+https://github.com/ckan/ckan@ckan-${CKAN_VERSION}#egg=ckan[requirements]" && \
    ckan-pip3 install uwsgi && \
    ckan-pip3 install -e "git+https://github.com/ckan/ckanext-scheming@${CKAN_SCHEMING_VERSION}#egg=ckanext-scheming" && \
    ckan-pip3 install -e "git+https://github.com/UtrechtUniversity/msl_ckan_core@${CKAN_MSL_CORE_VERSION}#egg=ckanext-msl_ckan" && \
    ckan-pip3 install -e "git+https://github.com/UtrechtUniversity/msl_ckan_util@${CKAN_MSL_UTIL_VERSION}#egg=ckanext-msl_ckan_util" && \
    ln -s $CKAN_VENV/src/ckan/ckan/config/who.ini $CKAN_CONFIG/who.ini && \
    cp -v $CKAN_VENV/src/ckan/contrib/docker/ckan-entrypoint.sh /ckan-entrypoint.sh && \
    chmod +x /ckan-entrypoint.sh && \
    chown -R ckan:ckan $CKAN_HOME $CKAN_VENV $CKAN_CONFIG $CKAN_STORAGE_PATH $COVERAGE_DIR && \
    rm /usr/lib/ckan/default/src/ckan/ckan/config/solr/schema.xml && \
    ln -sf /usr/lib/ckan/default/src/ckanext-msl-ckan/ckanext/msl_ckan/config/solr/schema.xml /usr/lib/ckan/default/src/ckan/ckan/config/solr/schema.xml && \
    perl -n -i.bak -e 'print unless /defaultSearchField/ or /solrQueryParser/' /usr/lib/ckan/default/src/ckan/ckan/config/solr/schema.xml

ADD ./ckan-entrypoint.sh /ckan-entrypoint.sh
ENTRYPOINT ["/ckan-entrypoint.sh"]
RUN chmod +x /ckan-entrypoint.sh

USER ckan
EXPOSE 8080

CMD ["/ckan-entrypoint.sh"]
