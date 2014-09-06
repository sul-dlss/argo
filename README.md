# Argo

Argo is the administrative interface to the Stanford Digital Repository. It uses Blacklight and ActiveFedora to expose the repository contents, and DorServices to enable editing and updating. 

## Getting Started
Argo currently requires some unpublished gems from Stanford's internal gem server.  If you are interested in running Argo as a Hydra head, for further information on Argo's dependencies please contact DLSS at Standord Libraries (https://library.stanford.edu/department/digital-library-systems-and-services-dlss#) or open an issue on github.

### Check Out the Code
    
```bash
cd [ROOT LOCATION WHERE YOU WANT ARGO FOLDER TO GO]
git clone https://github.com/sul-dlss/argo.git
cd argo
```

### Install dependencies

```bash
# install ruby (e.g., via rvm)
# 
bundle install
```
    
### Configure the solr and database yml files.  Stanford users should review internal documentation.

### Install components and DB:

```bash
rake jetty:clean
rake db:setup
rake db:migrate RAILS_ENV=test
rake tmp:create
```

## Run the server

```bash
rake jetty:start
rails server    # alternatively: rake server
```

