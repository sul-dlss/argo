#!/bin/bash

# Install components, setup DB and Solr:
bundle install
bundle exec rake argo:install

# Run the server
bundle exec rake jetty:stop  # Ensure it's not running
bundle exec rake jetty:start # This may take a few minutes

# Load and index records in the 'development' Solr core
bundle exec rake argo:repo:load

