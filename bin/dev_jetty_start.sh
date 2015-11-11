#!/bin/bash

function jetty_check_url {
    URL=$1
    echo "Waiting for a successful response from $URL"
    count=0
    until $(curl --output /dev/null --silent --head --fail $URL); do
        printf '.'
        let count=count+1
        if [ $count -eq 120 ]; then
            echo
            echo "Failing! Will continue to wait a little longer."
        fi
        if [ $count -gt 240 ]; then
            echo
            echo "Failure to start jetty!"
            exit 1
        fi
        sleep 1
    done
}

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

echo
echo "Resetting Jetty"
rake jetty:restart
jetty_check_url 'http://localhost:8983/solr/'
echo "Success! Solr responds"
jetty_check_url 'http://localhost:8983/fedora/'
echo "Success! Fedora responds."

# Load and index records in the 'development' Solr core
rake argo:repo:load
