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
    
### Configure the solr and database yml files.  Stanford users should review internal documentation.

### Install components and DB:

```bash
rake argo:jetty:clean
rake argo:jetty:config
rake db:setup
rake db:migrate RAILS_ENV=test
rake tmp:create
```

## Run the server

```bash
rake jetty:start
rails server
```

## Load and index records

```bash
for x in fedora_conf/data/*.xml; do echo Loading $x; rake repo:load foxml=$x ; done
```

## Delete records

You cannot just load records twice and overwrite.  The repo namespace has been provisioned and you need to remove the old record first.

For example, using `rails console` to target one ID, or five:

```ruby
Dor::Item.find("druid:pv820dk6668").destroy
%w[pv820dk6668 rn653dy9317 xb482bw3979 hj185vb7593 hv992ry2431].each{ |pid| Dor::Item.find("druid:#{pid}").destroy }

```
