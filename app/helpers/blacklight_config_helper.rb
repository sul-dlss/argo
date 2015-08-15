module BlacklightConfigHelper
  def self.add_common_date_facet_fields_to_config! config
    # Be careful using NOW: http://lucidworks.com/blog/date-math-now-and-filter-queries/
    # tl;dr: specify coarsest granularity (/DAY or /HOUR) or lose caching
    #
    #TODO: update blacklight_range_limit to work w/ dates and use it.  Or something similarly powerful.
    #      Per-query user-paramatized facet endpoints w/ auto-scaling granularity is the point.
    #      See solr facet ranges (start/end/gap), NOT facet range queries (fq), as here.
    config.add_facet_field 'registered_date', :label => 'Registered', :query => {
      :days_7  => { :label => 'within 7 days',  :fq => "registered_dttsim:[NOW/DAY-7DAYS TO *]"},
      :days_30 => { :label => 'within 30 days', :fq => "registered_dttsim:[NOW/DAY-30DAYS TO *]"}
    }
    config.add_facet_field 'accessioned_latest_date', :label => 'Last Accessioned', :query => {
      :days_7  => { :label => 'within 7 days',  :fq => "accessioned_latest_dttsi:[NOW/DAY-7DAYS TO *]"},
      :days_30 => { :label => 'within 30 days', :fq => "accessioned_latest_dttsi:[NOW/DAY-30DAYS TO *]"}
    }
    config.add_facet_field 'published_latest_date', :label => 'Last Published', :query => {
      :days_7  => { :label => 'within 7 days',  :fq => "published_latest_dttsi:[NOW/DAY-7DAYS TO *]"},
      :days_30 => { :label => 'within 30 days', :fq => "published_latest_dttsi:[NOW/DAY-30DAYS TO *]"}
    }
    config.add_facet_field 'submitted_latest_date', :label => 'Last Submitted', :query => {
      :days_7  => { :label => 'within 7 days',  :fq => "submitted_latest_dttsi:[NOW/DAY-7DAYS TO *]"},
      :days_30 => { :label => 'within 30 days', :fq => "submitted_latest_dttsi:[NOW/DAY-30DAYS TO *]"}
    }
    config.add_facet_field 'deposited_date', :label => 'Last Ingested', :query => {
      :days_1  => { :label => 'today',          :fq => "deposited_latest_dttsi:[NOW/DAY TO *]"},
      :days_7  => { :label => 'within 7 days',  :fq => "deposited_latest_dttsi:[NOW/DAY-7DAYS TO *]"},
      :days_30 => { :label => 'within 30 days', :fq => "deposited_latest_dttsi:[NOW/DAY-30DAYS TO *]"}
    }
    config.add_facet_field 'object_modified_date', :label => 'Last Modified', :query => {
      :days_7  => { :label => 'within 7 days',  :fq => "modified_latest_dttsi:[NOW/DAY-7DAYS TO *]"},
      :days_30 => { :label => 'within 30 days', :fq => "modified_latest_dttsi:[NOW/DAY-30DAYS TO *]"}
    }
    config.add_facet_field 'version_opened_date', :label => 'Last Opened', :query => {
      :all     => { :label => 'All',               :fq => "opened_latest_dttsi:*"},
      :days_7  => { :label => 'more than 7 days',  :fq => "opened_latest_dttsi:[* TO NOW/DAY-7DAYS]"},
      :days_30 => { :label => 'more than 30 days', :fq => "opened_latest_dttsi:[* TO NOW/DAY-30DAYS]"}
    }
    config.add_facet_field 'embargo_release_date', :label => 'Embargo Release Date', :query => {
      :days_7  => { :label => 'up to 7 days',  :fq => "embargo_release_dtsim:[NOW TO NOW/DAY+7DAYS]"},
      :days_30 => { :label => 'up to 30 days', :fq => "embargo_release_dtsim:[NOW TO NOW/DAY+30DAYS]"},
      :all     => { :label => 'All',           :fq => "embargo_release_dtsim:*"}
    }
  end

  def self.add_common_default_solr_params_to_config! config
    config.default_solr_params = {
      :'q.alt' => "*:*",
      :defType => 'dismax',
      :qf => %{text^3 creator_tesim dc_creator_tesim dc_identifier_druid_tesim dc_title_tesim dor_id_tesim extent_ssim identifier_tesim lifecycle_ssim obj_label_tesim obj_state_tesim originInfo_place_placeTerm_tesim originInfo_publisher_tesim public_dc_contributor_tesim public_dc_coverage_tesim public_dc_creator_tesim public_dc_date_tesim public_dc_description_tesim public_dc_format_tesim public_dc_identifier_tesim public_dc_language_tesim public_dc_publisher_tesim public_dc_relation_tesim public_dc_rights_tesim public_dc_subject_tesim public_dc_title_tesim public_dc_type_tesim scale_ssim source_id_ssim tag_ssim title_tesim topic_tesim},
      :facet => true,
      :'facet.mincount' => 1,
      :'f.wf_wps_ssim.facet.limit' => -1,
      :'f.wf_wsp_ssim.facet.limit' => -1,
      :'f.wf_swp_ssim.facet.limit' => -1,
      :'f.tag_ssim.facet.limit' => -1,
      :'f.tag_ssim.facet.sort' => 'index'
    }
  end
end
