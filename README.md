[![Build Status](https://travis-ci.org/sul-dlss/argo.png?branch=develop)](https://travis-ci.org/sul-dlss/argo) | [![Coverage Status](https://coveralls.io/repos/sul-dlss/argo/badge.svg?branch=develop&service=github)](https://coveralls.io/github/sul-dlss/argo?branch=master)

# Argo

Argo is the administrative interface to the Stanford Digital Repository. It uses Blacklight and ActiveFedora to expose the repository contents, and DorServices to enable editing and updating. 

## Getting Started

Install Java 1.8 (or newer) JRE (and JDK also on Mac OSX).  It is required for the version of Solr in use.
http://java.com/en/download/

Install ruby 2.2.2 or later (e.g., via rvm or rbenv).

[Install phantomjs](http://phantomjs.org/download.html) to run the tests.

### Check Out the Code
    
```bash
git clone https://github.com/sul-dlss/argo.git
cd argo
```

### Configure the rest of the local environment.

Settings configuration is managed using the [config](https://github.com/railsconfig/config) gem. Developers should create (or obtain in one of the argo branches in the `shared_config` repo) `config/settings/development.local.yml` and `config/settings/test.local.yml` files to set local development variables correctly.

You will also need to create or acquire the following certificate files (per environment):

 - `config/certs/argo-client.crt`  # should match the value specified by `Settings.SSL.CERT_FILE`
 - `config/certs/argo-client.key`  # should match the value specified by `Settings.SSL.CERT_FILE`

For vanilla Stanford laptop installations, the cert files and the local settings files should be available from a private DLSS repository.  You can clone this and create symlinks to the checked out config files (instead of having copies of those files in place).  That way, you can easily pull changes to the vanilla configs as defaults are changed, andyou can submit such changes back upstream, in place on your instance.  An Argo developer or DevOps person should be able to point you to the private config repo and explain how to use it.

### Run bundler to install the Gem dependencies

`bundle install`

`bundle install` may complain if MySQL isn't installed.  You can either comment out the mysql2 inclusion in Gemfile and come back to it later (you can develop using sqlite), or you can install MySQL.

### Install components, setup DB and Solr:

```bash
rake argo:install
```

### Optional - Increase Jetty heap size and Solr logging verbosity
#### Delving into this is only recemmended if you run into more trouble than usual starting jetty or getting it to run stably (or if you know you have some other reason to make these sorts of changes).

In the created `./jetty` directory add the following to the `start.ini` to increase the heap size, allow the debugger to attach, and to explicitly specify logging properties.

In the section that starts with the heading `If the arguments in this file include JVM arguments` (at LN19 as of this README update):
```
--exec

-Djava.awt.headless=true
-Dcom.sun.management.jmxremote
-Xmx2000m
-XX:+PrintCommandLineFlags
-XX:+UseConcMarkSweepGC
-XX:+CMSClassUnloadingEnabled
-XX:PermSize=64M
-XX:MaxPermSize=256M

# Solr logging
-Djava.util.logging.config.file=etc/logging.properties
```

You may then update values in `jetty/etc/logging.properties` to change logging settings (e.g., set `.level = FINEST`).

## Run the server

```bash
rake jetty:start # This may take a few minutes
bin/delayed_job start  # Necessary only for spreadsheet bulk upload
rails server
```

## Load and index records

_Note: Running this command will index the fixture data in the `development` core_
```bash
rake argo:repo:load
```

## Run the tests

```bash
rspec
```

_Important Note: Running `rake ci` will reinstall your jetty instance and delete any custom test data you may have setup_

The continuous integration build can also be run by:

```bash
bundle exec rake ci
```

_Note: Running the CI build will index fixture data into the `test` core. If you want data indexed into the `development` core for development, you probably need to clean the jetty and reload._

```bash
# Commands to clean and reload jetty for development
bundle exec rake argo:jetty:clean
bundle exec rake argo:jetty:config
bundle exec rake jetty:start
bundle exec rake argo:repo:load
```

## Delete records

You cannot just load records twice and overwrite.  The repo namespace has been provisioned and you need to remove the old record first.

For example, using `rails console` to target one ID, or five:

```ruby
Dor::Item.find("druid:pv820dk6668").destroy
%w[pv820dk6668 rn653dy9317 xb482bw3979 hj185vb7593 hv992ry2431].each{ |pid| Dor::Item.find("druid:#{pid}").destroy }

```
