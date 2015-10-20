[![Build Status](https://travis-ci.org/sul-dlss/argo.png?branch=master)](https://travis-ci.org/sul-dlss/argo)

# Argo

Argo is the administrative interface to the Stanford Digital Repository. It uses Blacklight and ActiveFedora to expose the repository contents, and DorServices to enable editing and updating. 

## Getting Started

Install Java 1.8 (or newer) JRE (and JDK also on Mac OSX).  It is required for the version of Solr in use.
http://java.com/en/download/

Install ruby 1.9.3 or later (e.g., via rvm).

### Check Out the Code
    
```bash
git clone https://github.com/sul-dlss/argo.git
cd argo
```
    
### Configure the database.yml file.  Stanford users should review internal documentation.

```bash
cp config/database.yml.example config/database.yml
```

### Configure the rest of the local environment.  Stanford users should review internal documentation.

You will also need to acquire the following config files (per environment):

 - `config/environments/development.rb`
 - `config/environments/dor_development.rb`
 - `config/environments/test.rb`
 - `config/environments/dor_test.rb`
 - `config/certs/dlss-dev-$USER-dor-dev.crt`  # should match the value specified by cert_file in dor_development.rb
 - `config/certs/dlss-dev-$USER-dor-dev.key`  # should match the value specified by key_file in dor_development.rb

### Run bundler to install the Gem dependencies

`bundle install`

`bundle install` may complain if MySQL isn't installed.  You can either comment out the mysql2 inclusion in Gemfile and come back to it later (you can develop using sqlite), or you can install MySQL.

### Install components, setup DB and Solr:

```bash
rails generate argo:solr
rake argo:jetty:clean
rake argo:jetty:config
rake db:setup
rake db:migrate
rake tmp:create
```

### Optional - Increase Jetty heap size and Solr logging verbosity
#### Delving into this is only recemmended if you run into more trouble than usual starting jetty or getting it to run stably (or if you know you have some other reason to make these sorts of changes).

In the created `./jetty` directory add the following to the `start.ini` to increase the heap size, allow the debugger to attach, and to explicitly specify logging properties.

In the section that starts with the heading `If the arguments in this file include JVM arguments` (at LN19 as of this README update):
```
--exec

Djava.awt.headless=true
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
rails server
```

## Load and index records

```bash
rake argo:repo:load
```

## Delete records

You cannot just load records twice and overwrite.  The repo namespace has been provisioned and you need to remove the old record first.

For example, using `rails console` to target one ID, or five:

```ruby
Dor::Item.find("druid:pv820dk6668").destroy
%w[pv820dk6668 rn653dy9317 xb482bw3979 hj185vb7593 hv992ry2431].each{ |pid| Dor::Item.find("druid:#{pid}").destroy }

```
