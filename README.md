[![Build Status](https://travis-ci.org/sul-dlss/argo.png?branch=master)](https://travis-ci.org/sul-dlss/argo)
[![Code Climate](https://codeclimate.com/github/sul-dlss/argo/badges/gpa.svg)](https://codeclimate.com/github/sul-dlss/argo)
[![Code Climate Test Coverage](https://codeclimate.com/github/sul-dlss/argo/badges/coverage.svg)](https://codeclimate.com/github/sul-dlss/argo/coverage)
[![GitHub version](https://badge.fury.io/gh/sul-dlss%2Fargo.svg)](https://badge.fury.io/gh/sul-dlss%2Fargo)

# Argo

Argo is the administrative interface to the Stanford Digital Repository.

## Installation

### System Requirements

1. Install Docker
2. Install Ruby 2.6.4

### Check Out the Code

```bash
git clone https://github.com/sul-dlss/argo.git
cd argo
```

### Run bundler to install the Gem dependencies

```bash
bundle install
```

Note that `bundle install` may complain if MySQL isn't installed.  You can either comment out the `mysql2` inclusion in `Gemfile` and come back to it later (you can develop using `sqlite3`), or you can install MySQL.

### Install components
## Run the servers

```
docker-compose up -d
```

Need to emulate an administrator role in your browser?  Edit `docker-compose.yml`, and under services:web:environment
change the value of `ROLES` to `sdr:administrator-role`

If you want to use the rails console use:

```
docker-compose run --rm web rails console
```

If you want to run background jobs, which are necessary for spreadsheet bulk uploads and indexing to run:

```
docker-compose run web bin/delayed_job start
```

Note, if you update the Gemfile or Gemfile.lock, you will need to rebuild the web docker container and reload the data:

```
docker-compose build web
docker-compose run --rm web rake argo:repo:load
```

## Debugging

It can be useful when debugging to see the local rails server output in realtime and pause with 'byebug'.  You can do
this while running in the app in the web container.  First stop any existing web container (if running already):

```
docker-compose stop web
```

Then start it in a mode that is interactive:

```
docker-compose run --service-ports web
```

This will allow you to view rails output in real-time.  You can also add 'byebug' inline in your code to pause for inspection on the console.

### Note

If you run into errors related to the version of bundler when building the `web` container, that likely means you need to pull a newer copy of the base Ruby image specified in `Dockerfile`, e.g., `docker pull ruby:{MAJOR}.{MINOR}-stretch`.

## Load and index records

```
docker-compose run --rm web rake argo:repo:load
```

## Common tasks

### Run the tests

To run the test suite, invoke `rspec` from the Argo app root.  Note that the docker containers need to be running already for this work.
```bash
# docker-compose up -d # (if not already running)
rspec
```

### Run the continuous integration build

_Important Note: Running `rake ci` will reload fixtures for the `test` environment only._

The continuous integration build can be run by:
```bash
RAILS_ENV=test bundle exec rake ci
```

### Delete records

You cannot just load records twice and overwrite.  The repo namespace has been provisioned and you need to remove the old record first.

For example, using `rails console` to target one ID, or five:

```ruby
Dor.find("druid:pv820dk6668").destroy
%w[pv820dk6668 rn653dy9317 xb482bw3979 hj185vb7593 hv992ry2431].each{ |pid| Dor.find("druid:#{pid}").destroy }
```

### virtual-merge script

NOTE: temporary until bulk async action implemented in UI

Merges multiple image objects into a parent object via virtual object structure (e.g. an atlas in which each map has been individually cataloged).  Creates a virtual composite object with contentMD pointing to binaries held in other objects; the child objects have an isConstituentOf element in RELS-EXT allowing traversal to a parent object in discovery interfaces.

virtual merge can be run from the Argo application root directory:

```bash
RAILS_ENV=production bundle exec ./bin/virtual-merge --purge druid:pp000pp0000 druid:cc111cc1111 druid:cc222cc2222
```

where `pp000pp0000` is the druid for the virtual composite object and the child objects are `cc111cc1111` and `cc222cc2222`.  More info, including object requirements: <https://consul.stanford.edu/display/chimera/Virtual+Object+Combinator+I>

For help:

```bash
bundle exec ./bin/virtual-merge -h
```

## Internals

Argo uses Blacklight and ActiveFedora to expose the repository contents, and `dor-services` to enable editing and updating. Its key components include:

- Rails 5.1
- Blacklight 6
- dor-services
  - ActiveFedora
  - dor-workflow-service
- RSolr
- DelayedJob
- Bootstrap
- JQuery

and in development or testing mode:

- RSpec
- Capybara
- Chrome

## Further reading

### Indexing (including bulk reindexing)

For further reading on how indexing from Fedora to Solr works in Argo, see [INDEXING.md](INDEXING.md).  This explains how single object reindexing works, how the bulk reindexing mechanism works, and how to build custom reindexing runs.

### Profiling

For information on how to profile the app in the event of performance issues, see [PROFILING.md](PROFILING.md).  This explains how to collect profiling info, how to analyze it, how to approach the issue generally, and alternatives/complements to Argo's main built-in profiling tool.
