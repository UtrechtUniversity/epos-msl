# Image for Solr configured for CKAN

FROM solr:8.11
LABEL org.opencontainers.image.authors="Yoda team"

ENV SOLR_CONFIG_DIR="/opt/solr/server/solr/configsets"
ENV MSL_CKAN_CORE_VERSION=1.7.0

# Create a CKAN configset based on the default one
USER root
RUN cp -R $SOLR_CONFIG_DIR/_default $SOLR_CONFIG_DIR/ckan

# Install basic components
RUN apt update && \
    apt install -y git vim && \
    apt-get -q clean && \
    rm -rf /var/lib/apt/lists/*

# Download the EPOS-MSL core plugin (for the schema)
RUN cd /usr/lib && \
    git clone https://github.com/UtrechtUniversity/msl_ckan_core.git && \
    cd msl_ckan_core && \
    git checkout "$MSL_CKAN_CORE_VERSION"


# Change the CKAN configset to use the EPOS-MSL schema, and enable Query Elevation
USER root
ADD solrconfig.xml /opt/solr-8.11.4/server/solr/configsets/ckan/conf/solrconfig.xml
RUN ln -s /usr/lib/msl_ckan_core/ckanext/msl_ckan/config/solr/schema.xml $SOLR_CONFIG_DIR/ckan/conf/schema.xml && \
    perl -n -i.bak -e 'print unless /defaultSearchField/ or /solrQueryParser/' $SOLR_CONFIG_DIR/ckan/conf/schema.xml && \
    cp $SOLR_CONFIG_DIR/ckan/conf/schema.xml $SOLR_CONFIG_DIR/ckan/conf/managed-schema && \
    cp /opt/solr/server/solr/configsets/sample_techproducts_configs/conf/elevate.xml $SOLR_CONFIG_DIR/ckan/conf/elevate.xml

USER solr
CMD ["sh", "-c", "solr-precreate ckan $SOLR_CONFIG_DIR/ckan"]
