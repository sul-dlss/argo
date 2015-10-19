[![Build Status](https://travis-ci.org/sul-dlss/argo.png?branch=master)](https://travis-ci.org/sul-dlss/argo)

# Argo

Argo is the administrative interface to the Stanford Digital Repository. It uses Blacklight and ActiveFedora to expose the repository contents, and DorServices to enable editing and updating. 

## Getting Started

Install Java 1.8 (or newer) JRE (and JDK also on Mac OSX).  It is required for the version of Solr in use.
http://java.com/en/download/

Install ruby 1.9.3 or later (e.g., via rvm).

### Check Out the Code and Install Ruby Dependencies
    
```bash
git clone https://github.com/sul-dlss/argo.git
cd argo
bundle install
```
    
### Configure the argo and database yml files.  Stanford users should review internal documentation.

```bash
cp config/database.yml.example config/database.yml
```

You will also need to acquire the following config files (per environment):

 - `config/development.rb`
 - `config/dor_development.rb`

### Install components and DB:

```bash
rake argo:jetty:clean
rake argo:jetty:config
rake db:setup
rake db:migrate
rake tmp:create
```

### Optional - Increase Jetty heap size and Solr logging

In the created `./jetty` directory add the following the `start.ini` to increase the heap size

At LN19
```
--exec

Djava.awt.headless=true
-Dcom.sun.management.jmxremote
-Dorg.eclipse.jetty.util.log.IGNORED=true
-Dorg.eclipse.jetty.LEVEL=INFO
-Dorg.eclipse.jetty.util.log.stderr.SOURCE=true
-Xmx2000m
-XX:+PrintCommandLineFlags
-XX:+UseConcMarkSweepGC
-XX:+CMSClassUnloadingEnabled
-XX:PermSize=64M
-XX:MaxPermSize=256M

# Solr logging
-Djava.util.logging.config.file=etc/logging.properties
```

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
