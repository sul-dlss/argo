#!/bin/bash

# Startup Jetty
if rake jetty:status | grep -q 'Not running'; then
    jetty_startup=$(find ./ -name 'dev_jetty_start.sh')
    $jetty_startup
fi

# Startup ARGO
bundle exec ./bin/delayed_job start   # Necessary only for spreadsheet bulk upload
bundle exec rails server -d

