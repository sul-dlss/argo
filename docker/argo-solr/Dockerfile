FROM solr:8.11.2

COPY --chown=solr security.json /opt/solr/security.json
COPY --chown=solr ci-start.sh /opt/solr/server/scripts/ci-start.sh
# COPY --chown=$SOLR_USER:$SOLR_USER lando-start.sh /opt/solr/server/scripts/lando-start.sh

# ENV BASE_URL "https://raw.githubusercontent.com/pulibrary/princeton_ansible/main/roles/solrcloud/files"
# ENV JTS_URL "$BASE_URL/jts-core-1.15.1.jar"
# ENV CJK_URL "$BASE_URL/CJKFoldingFilter.jar"
# ENV UMICH_URL "$BASE_URL/lucene-umich-solr-filters-6.0.0-SNAPSHOT.jar"

# ENV EXTRAS_BASE_PATH "/opt/solr/contrib/analysis-extras/lib"
# ENV CJK_PATH "$EXTRAS_BASE_PATH/CJKFoldingFilter.jar"
# ENV UMICH_PATH "$EXTRAS_BASE_PATH/lucene-umich-solr-filters-6.0.0-SNAPSHOT.jar"
# ENV WEBAPP_BASE_PATH "/opt/solr/server/solr-webapp/webapp/WEB-INF/lib"
# ENV JTS_PATH "$WEBAPP_BASE_PATH/jts-core-1.15.1.jar"

# USER root
# RUN wget $CJK_URL -O $CJK_PATH
# RUN wget $UMICH_URL -O $UMICH_PATH
# RUN wget $JTS_URL -O $JTS_PATH
USER $SOLR_USER

# to build the image on docker hub:
# $ docker build -t suldlss/argo-solr:latest -f docker/argo-solr/Dockerfile .
# $ docker push suldlss/argo-solr:latest
