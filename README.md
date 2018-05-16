[![Build Status](https://travis-ci.org/sul-dlss/argo.png?branch=master)](https://travis-ci.org/sul-dlss/argo) | [![Coverage Status](https://coveralls.io/repos/sul-dlss/argo/badge.svg?branch=master&service=github)](https://coveralls.io/github/sul-dlss/argo?branch=master)
[![Code Climate](https://codeclimate.com/github/sul-dlss/argo/badges/gpa.svg)](https://codeclimate.com/github/sul-dlss/argo)
[![Code Climate Test Coverage](https://codeclimate.com/github/sul-dlss/argo/badges/coverage.svg)](https://codeclimate.com/github/sul-dlss/argo/coverage)
[![Dependency Status](https://gemnasium.com/badges/github.com/sul-dlss/argo.svg)](https://gemnasium.com/github.com/sul-dlss/argo)
[![GitHub version](https://badge.fury.io/gh/sul-dlss%2Fargo.svg)](https://badge.fury.io/gh/sul-dlss%2Fargo)

# Argo

Argo is the administrative interface to the Stanford Digital Repository.

## Installation

### System Requirements

1. Install Java 1.8 JRE (and also the JDK on Mac OSX).  >= Java 1.8 is required for the version of Solr in use, <= 1.8 is requred for the version of Fedora in use.
http://java.com/en/download/

2. Install Ruby 2.2.2 (e.g., via rvm or rbenv).


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

This will setup the database, Fedora, and Solr:

```bash
rake argo:install
```

### Optional - Increase Jetty heap size and Solr logging verbosity

Fedora and Solr are hosted inside a local Jetty instance in the `./jetty/` folder.
Delving into this is only recommended if you run into more trouble than usual starting jetty or getting it to run stably (or if you know you have some other reason to make these sorts of changes).

In the created `./jetty` directory add the following to the `start.ini` to increase the heap size, allow the debugger to attach, and to explicitly specify logging properties. In the section that starts with the heading `If the arguments in this file include JVM arguments` (at LN19 as of this README update):

```
--exec
# increase VM memory usage to 2GB
-Xmx2000m
-Djava.awt.headless=true
-Dcom.sun.management.jmxremote
-XX:+PrintCommandLineFlags
-XX:+UseConcMarkSweepGC
-XX:+CMSClassUnloadingEnabled
-XX:PermSize=64M
-XX:MaxPermSize=256M

# Solr logging
-Djava.util.logging.config.file=etc/logging.properties
```

You may then update values in `jetty/etc/logging.properties` to change logging settings (e.g., set `.level = FINEST`).

## Run the servers

Note that Argo expects [Dor Indexing App](https://github.com/sul-dlss/dor_indexing_app) to be running on port 4000, which Argo uses to perform
indexing as part of loading and updating Dor objects. Check out the code and run it using

```bash
rails s -p 4000
```

Then start Argo:

```bash
rake jetty:start       # This may take a few minutes to boot Fedora and Solr
bin/delayed_job start  # Necessary for spreadsheet bulk uploads and indexing
rails server
```

### Important note about Workflow Services integration
Argo depends on the workflow service for both development and test environments. In order to run a stub implementation of this, install Docker and run:

```
docker-compose up
```

## Load and index records

1. Make sure Jetty has successfully started by going to [Fedora](http://localhost:8983/fedora) and [Solr](http://localhost:8983/solr).

2. Load fixture data to the `development` Fedora repository and index it to the `development` Solr collection:
```bash
rake argo:repo:load
```

3. Load fixture data to the `test` Fedora repository and index it to the `test` Solr collection. This is needed for testing (i.e., running specs):
```bash
RAILS_ENV=test rake argo:repo:load
```

## Common tasks

### Rebuilding Jetty instance without re-install

If you'd like to do a clean re-installation of jetty without running the `argo:install` task:
```bash
# Commands to install a fresh instance of Jetty, configure it, and start it
rake jetty:stop
rake argo:jetty:clean
rake argo:jetty:config
rake jetty:start

# Load and index development fixtures
rake argo:repo:load

# Load and index test fixtures
RAILS_ENV=test rake argo:repo:load
```

### Run the tests

To run the test suite (which runs against the `test` Fedora repo/Solr collection), invoke `rspec` from the Argo app root
```bash
rspec
```

### Run the continuous integration build

_Important Note: Running `rake ci` will reinstall your jetty instance and **delete any custom test data** you may have setup in both the `development` and `test` environments, and reload fixtures from scratch for the `test` environment only._

The continuous integration build can also be run by:
```bash
RAILS_ENV=test bundle exec rake ci
```

If, after running the CI build, you want to reload fixtures into the `development` environment, you can use `rake argo:repo:load`.  The default environment is `development`, so it should not be necessary to specify `RAILS_ENV` for that task.

### Delete records

You cannot just load records twice and overwrite.  The repo namespace has been provisioned and you need to remove the old record first.

For example, using `rails console` to target one ID, or five:

```ruby
Dor.find("druid:pv820dk6668").destroy
%w[pv820dk6668 rn653dy9317 xb482bw3979 hj185vb7593 hv992ry2431].each{ |pid| Dor.find("druid:#{pid}").destroy }
```

## Internals

Argo uses Blacklight and ActiveFedora to expose the repository contents, and `dor-services` to enable editing and updating. Its key components include:

- Rails 4
- Blacklight 5
- dor-services
  - ActiveFedora
  - dor-workflow-service
- RSolr
- DelayedJob
- Bootstrap
- JQuery

and in development or testing mode:

- Jetty
- RSpec
- Capybara
- Chrome

## Further reading

### Indexing (including bulk reindexing)

For further reading on how indexing from Fedora to Solr works in Argo, see [INDEXING.md](INDEXING.md).  This explains how single object reindexing works, how the bulk reindexing mechanism works, and how to build custom reindexing runs.

### Profiling

For information on how to profile the app in the event of performance issues, see [PROFILING.md](PROFILING.md).  This explains how to collect profiling info, how to analyze it, how to approach the issue generally, and alternatives/complements to Argo's main built-in profiling tool.
