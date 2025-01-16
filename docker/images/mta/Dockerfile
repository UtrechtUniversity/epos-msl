# This is an image for running the MSL-API application, that is part of the EPOS-MSL catalog

# See CKAN docs on installation from Docker Compose on usage
FROM ubuntu:noble
MAINTAINER Yoda team

ENV MAILPIT_VERSION=v1.21.8

# Need bash to get nvm/npm to work with default init files
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

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

# Install common dependencies
RUN apt -y install curl golang git && \
    curl https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash && \
    source /root/.nvm/nvm.sh && \
    nvm install v18

### Install Mailpit
RUN cd / && \
    source /root/.nvm/nvm.sh && \
    git clone -c advice.detachedHead=false https://github.com/axllent/mailpit.git && \
    cd mailpit && \
    git checkout ${MAILPIT_VERSION} && \
    npm install && \
    npm run package && \
    CGO_ENABLED=0 go build -ldflags "-s -w -X github.com/axllent/mailpit/config.Version=${VERSION}" -o /mailpit.bin

### Install Postfix
RUN apt -y install postfix sasl2-bin mailutils
ADD main.cf /etc/postfix/main.cf
ADD master.cf /etc/postfix/master.cf

# Run
ADD mta-entrypoint.sh /mta-entrypoint.sh
RUN chmod +x /mta-entrypoint.sh
CMD ["/mta-entrypoint.sh"]
