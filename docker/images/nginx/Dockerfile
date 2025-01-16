# Image for Nginx reverse proxy configured for CKAN

FROM nginx:1.27
MAINTAINER Yoda team

ADD nginx.site.part1 /etc/nginx/nginx.site.part1
ADD nginx.site.part2 /etc/nginx/nginx.site.part2
ADD nginx.site.part-mailpit /etc/nginx/nginx.site.part-mailpit
RUN rm /etc/nginx/conf.d/default.conf
ADD epos-msl.cnf /etc/certificates/epos-msl.cnf
ADD nginx-entrypoint.sh /nginx-entrypoint.sh
RUN chmod +x /nginx-entrypoint.sh
CMD ["/nginx-entrypoint.sh"]
