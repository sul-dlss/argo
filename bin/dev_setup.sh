#!/bin/bash

echo "Checking java 1.8.x"
if java -version 2>&1 | grep -q 'build 1.8'; then
    echo "OK"
else
    echo "Use java 1.8.x; you have:"
    java -version
    exit 1
fi

# Ensure that everything is stopped prior to 'argo:install'
stop_script=$(find ./ -name 'dev_stop.sh')
$stop_script

# Install components, setup DB and Solr:
bundle install
bundle exec rake argo:install

jetty_startup=$(find ./ -name 'dev_jetty_start.sh')
$jetty_startup

# Load and index records in the 'development' Solr core
rake argo:repo:load
