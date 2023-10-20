#!/bin/bash

bin/solr -cloud -noprompt -p 8983
echo 'zookeeper command about to run'
server/scripts/cloud-scripts/zkcli.sh -zkhost localhost:9983 -cmd putfile /security.json /opt/solr/security.json

echo 'zookeeper command ran'

#sleep infinity