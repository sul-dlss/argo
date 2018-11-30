[![Build Status](https://travis-ci.org/sul-dlss/argo.png?branch=master)](https://travis-ci.org/sul-dlss/argo) | [![Coverage Status](https://coveralls.io/repos/sul-dlss/argo/badge.svg?branch=master&service=github)](https://coveralls.io/github/sul-dlss/argo?branch=master)
[![Code Climate](https://codeclimate.com/github/sul-dlss/argo/badges/gpa.svg)](https://codeclimate.com/github/sul-dlss/argo)
[![Code Climate Test Coverage](https://codeclimate.com/github/sul-dlss/argo/badges/coverage.svg)](https://codeclimate.com/github/sul-dlss/argo/coverage)
[![GitHub version](https://badge.fury.io/gh/sul-dlss%2Fargo.svg)](https://badge.fury.io/gh/sul-dlss%2Fargo)

# Argo

Argo is the administrative interface to the Stanford Digital Repository.

## Installation

### System Requirements

1. Install Docker

2. Install Ruby 2.5.3

### Check Out the Code

```bash
git clone https://github.com/sul-dlss/argo.git
cd argo
```

### Configure the local environment and settings

Settings configuration is managed using the [config](https://github.com/railsconfig/config) gem. Developers should create (or obtain in one of the argo branches in the `shared_configs` repo) the `config/settings/development.local.yml` file to set local development variables correctly.

You will also need to create or acquire the following certificate files (per environment):

 - `config/certs/argo-client.crt`  # should match the value specified by `Settings.SSL.CERT_FILE`
 - `config/certs/argo-client.key`  # should match the value specified by `Settings.SSL.KEY_FILE`

For vanilla Stanford laptop installations, the cert files and the local settings file should be available from a private DLSS repository.  You can clone this and create symlinks to the checked out config files (instead of having copies of those files in place).  That way, you can easily pull changes to the vanilla configs as defaults are changed, and you can submit such changes back upstream, in place on your instance.  An Argo developer or DevOps person should be able to point you to the private config repo and explain how to use it.

### Run bundler to install the Gem dependencies

```bash
bundle install
```

Note that `bundle install` may complain if MySQL isn't installed.  You can either comment out the `mysql2` inclusion in `Gemfile` and come back to it later (you can develop using `sqlite3`), or you can install MySQL.

### Install components

This will setup the database:

```bash
rake argo:install
```

## Run the servers

```
docker-compose up
```

If you want to use the rails console use:

```
docker-compose run --rm web rails console
```

If you want to run background jobs, which are necessary for spreadsheet bulk uploads and indexing run:

```
docker-compose run web bin/delayed_job start
```

## Load and index records

```
docker-compose run --rm web rake argo:repo:load
```

## Common tasks

### Run the tests

To run the test suite (which runs against the `test` Fedora repo/Solr collection), invoke `rspec` from the Argo app root
```bash
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
