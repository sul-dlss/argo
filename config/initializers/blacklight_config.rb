# -*- encoding : utf-8 -*-
# You can configure Blacklight from here. 
#   
#   Blacklight.configure(:environment) do |config| end
#   
# :shared (or leave it blank) is used by all environments. 
# You can override a shared key by using that key in a particular
# environment's configuration.
# 
# If you have no configuration beyond :shared for an environment, you
# do not need to call configure() for that envirnoment.
# 
# For specific environments:
# 
#   Blacklight.configure(:test) {}
#   Blacklight.configure(:development) {}
#   Blacklight.configure(:production) {}
# 

Blacklight.configure(:shared) do |config|

  config[:default_solr_params] = {
    :per_page => 10,
    :facet => true,
    :'facet.mincount' => 1,
    :q => "*:*"
  }
 
  # solr field values given special treatment in the show (single result) view
  config[:show] = {
    :html_title => "fgs_label_field",
    :heading => "Title",
    :display_type => "object_type_field",
    :sections => {
      :default => ['identification','datastreams','history'],
      :item    => ['identification','datastreams','history','contents','child_objects']
    },
    :section_links => {
      'identification' => :render_full_dc_link,
      'contents' => :render_dor_workspace_link
    }
  }

  # solr fld values given special treatment in the index (search results) view
  config[:index] = {
    :show_link => "link_text_display",
    :record_display_type => "content_type_facet"
  }

  # solr fields that will be treated as facets by the blacklight application
  #   The ordering of the field names is the order of the display
  # TODO: Reorganize facet data structures supplied in config to make simpler
  # for human reading/writing, kind of like search_fields. Eg,
  # config[:facet] << {:field_name => "format", :label => "Format", :limit => 10}
  config[:facet] = {
    :field_names => (facet_fields = [
#      "project_tag_facet",
      "tag_facet",
      "object_type_field",
      "content_type_facet",
      "isGovernedBy_id_facet",
      "isMemberOfCollection_id_facet",
      "wf_wps_facet",
      "wf_wsp_facet",
      "wf_swp_facet"
    ]),
    :labels => {
      "project_tag_facet"             => "Project Name",
      "tag_facet"                     => "Tag",
      "object_type_field"             => "Object Type",
      "content_type_facet"            => "Content Type",
      "isGovernedBy_id_facet"         => "Admin. Policy",
      "isMemberOfCollection_id_facet" => "Owning Collection",
      "wf_wps_facet"                  => "Workflows (WPS)",
      "wf_wsp_facet"                  => "Workflows (WSP)",
      "wf_swp_facet"                  => "Workflows (SWP)"
    },
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.    
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or 
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.     
    :limits => {
      "project_tag_facet" => 20
    },
    :partials => {
      :wf_wps_facet        => "facet_hierarchy",
      :wf_wsp_facet        => "facet_hierarchy",
      :wf_swp_facet        => "facet_hierarchy",
      :tag_facet           => "facet_hierarchy"
    },
    :hierarchy => {
      'wf' => ['wps','wsp','swp'],
      'tag' => [nil]
    }
  }

  # Have BL send all facet field names to Solr, which has been the default
  # previously. Simply remove these lines if you'd rather use Solr request
  # handler defaults, or have no facets.
  config[:default_solr_params] ||= {}
  config[:default_solr_params][:"facet.field"] = facet_fields
  config[:default_solr_params][:"f.wf_wps_facet.facet.limit"] = -1
  config[:default_solr_params][:"f.wf_wsp_facet.facet.limit"] = -1
  config[:default_solr_params][:"f.wf_swp_facet.facet.limit"] = -1

  # solr fields to be displayed in the index (search results) view
  #   The ordering of the field names is the order of the display 
  
  config[:all_field_labels] = {
    "content_type_facet"            => "Content Type:",
    "dc_identifier_field"           => "IDs:",
    "fgs_createdDate_date"          => "Created:",
    "fgs_label_field"               => "Label:",
    "isGovernedBy_field"            => "Admin. Policy:",
    "isMemberOfCollection_field"    => "Collection:",
    "item_status_field"             => "Status:",
    "object_type_field"             => "Object Type:",
    "PID"                           => "DRUID:",
    "project_tag_field"             => "Project:",
    "project_tag_field"             => "Project:",
    "source_id_field"               => "Source:",
    "tag_field"                     => "Tags:"
  }
  
  config[:index_fields] = {
    :field_names => [
      "PID",
      "dc_creator_field",
      "project_tag_field"
    ],
    :labels => config[:all_field_labels]
  }

  # solr fields to be displayed in the show (single result) view
  #   The ordering of the field names is the order of the display 
  config[:show_fields] = {
    :field_names => [
      "fgs_createdDate_date",
      "fgs_label_field",
      "dc_identifier_field",
      "tag_field"
    ],
    :labels => config[:all_field_labels]
  }


  # "fielded" search configuration. Used by pulldown among other places.
  # For supported keys in hash, see rdoc for Blacklight::SearchFields
  #
  # Search fields will inherit the :qt solr request handler from
  # config[:default_solr_parameters], OR can specify a different one
  # with a :qt key/value. Below examples inherit, except for subject
  # that specifies the same :qt as default for our own internal
  # testing purposes.
  #
  # The :key is what will be used to identify this BL search field internally,
  # as well as in URLs -- so changing it after deployment may break bookmarked
  # urls.  A display label will be automatically calculated from the :key,
  # or can be specified manually to be different. 
  config[:search_fields] ||= []

  # This one uses all the defaults set by the solr request handler. Which
  # solr request handler? The one set in config[:default_solr_parameters][:qt],
  # since we aren't specifying it otherwise. 
  config[:search_fields] << {
    :key => "text",  
    :display_label => 'All Fields'   
  }

  # Now we see how to over-ride Solr request handler defaults, in this
  # case for a BL "search field", which is really a dismax aggregate
  # of Solr search fields. 
#  config[:search_fields] << {
#    :key => 'title',     
#    # solr_parameters hash are sent to Solr as ordinary url query params. 
#    :solr_parameters => {
#      :"spellcheck.dictionary" => "title"
#    },
#    # :solr_local_parameters will be sent using Solr LocalParams
#    # syntax, as eg {! qf=$title_qf }. This is neccesary to use
#    # Solr parameter de-referencing like $title_qf.
#    # See: http://wiki.apache.org/solr/LocalParams
#    :solr_local_parameters => {
#      :qf => "$title_qf",
#      :pf => "$title_pf"
#    }
#  }
#  config[:search_fields] << {
#    :key =>'author',     
#    :solr_parameters => {
#      :"spellcheck.dictionary" => "author" 
#    },
#    :solr_local_parameters => {
#      :qf => "$author_qf",
#      :pf => "$author_pf"
#    }
#  }
#
#  # Specifying a :qt only to show it's possible, and so our internal automated
#  # tests can test it. In this case it's the same as 
#  # config[:default_solr_parameters][:qt], so isn't actually neccesary. 
#  config[:search_fields] << {
#    :key => 'subject', 
#    :qt=> 'select',
#    :solr_parameters => {
#      :"spellcheck.dictionary" => "subject"
#    },
#    :solr_local_parameters => {
#      :qf => "$subject_qf",
#      :pf => "$subject_pf"
#    }
#  }
  
  # "sort results by" select (pulldown)
  # label in pulldown is followed by the name of the SOLR field to sort by and
  # whether the sort is ascending or descending (it must be asc or desc
  # except in the relevancy case).
  # label is key, solr field is value
  config[:sort_fields] ||= []
  config[:sort_fields]  << ['relevance', 'score desc']
#  config[:sort_fields] << ['relevance', 'score desc, pub_date_sort desc, title_sort asc']
#  config[:sort_fields] << ['year', 'pub_date_sort desc, title_sort asc']
#  config[:sort_fields] << ['author', 'author_sort asc, title_sort asc']
#  config[:sort_fields] << ['title', 'title_sort asc, pub_date_sort desc']
  
  # If there are more than this many search results, no spelling ("did you 
  # mean") suggestion is offered.
  config[:spell_max] = 5

  # Add documents to the list of object formats that are supported for all objects.
  # This parameter is a hash, identical to the Blacklight::Solr::Document#export_formats 
  # output; keys are format short-names that can be exported. Hash includes:
  #    :content-type => mime-content-type
  config[:unapi] = {
    'oai_dc_xml' => { :content_type => 'text/xml' } 
  }
  
  config[:field_groups] = {
    :identification => [
      ['PID','object_type_field','content_type_facet','item_status_field'],
      ['isGovernedBy_field','isMemberOfCollection_field','project_tag_field','source_id_field']
    ]
  }
end

# Force Blacklight to use Dor:RSolrConnection, which supports client certificates
require 'dor/rsolr'
Blacklight.instance_variable_set(:@solr, RSolr::Ext.connect(Dor::RSolrConnection, Blacklight.solr_config))
