# Image for Nginx reverse proxy configured for CKAN

FROM nginx:1.27
MAINTAINER Yoda team

ADD ckan.site /etc/nginx/conf.d/ckan.conf
RUN rm /etc/nginx/conf.d/default.conf
ADD epos-msl.cnf /etc/certificates/epos-msl.cnf
ADD nginx-entrypoint.sh /nginx-entrypoint.sh
RUN chmod +x /nginx-entrypoint.sh
CMD ["/nginx-entrypoint.sh"]
