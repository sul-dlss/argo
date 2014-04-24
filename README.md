# Argo

Argo is the administrative interface to the Stanford Digital Repository. It uses Blacklight and ActiveFedora to expose the repository contents, and DorServices to enable editing and updating. 

## Getting Started
Argo current requires gems off Stanford's internal gem server.  If you are interested in running Argo as a Hydra head, it is suggested you contact DLSS at Standord Libraries for further information on Argo's dependencies.  

1. Check Out the Code
    
    cd [ROOT LOCATION OF WHERE YOU WANT THE ARGO FOLDER TO GO]
    git clone git clone https://github.com/sul-dlss/argo.git
    cd argo

1.  Install the dependencies:

    bundle install
    
1.  Configure the solr and database yml files.  Stanford users should review internal documentation.       

