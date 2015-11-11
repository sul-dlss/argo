#!/bin/bash

# Startup ARGO
bundle exec ./bin/delayed_job start   # Necessary only for spreadsheet bulk upload
bundle exec rails server -d

