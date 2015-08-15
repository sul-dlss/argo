# -*- encoding : utf-8 -*-
require 'blacklight/catalog'
class CatalogController < ApplicationController
  include Blacklight::Marc::Catalog

  include BlacklightSolrExtensions
  include Blacklight::Catalog
  include Argo::AccessControlsEnforcement
  helper ArgoHelper

  before_filter :reformat_dates, :set_user_obj_instance_var

  CatalogController.solr_search_params_logic << :add_access_controls_to_solr_params

  configure_blacklight do |config|
    config.default_solr_params = {
      :'q.alt' => "*:*",
      :defType => 'dismax',
      :qf => %{text^3 citationCreator_t citationTitle_t content_file_t creator_tesim dc_creator_tesim dc_identifier_tesim dc_title_tesim dor_id_tesim event_t events_event_t events_t extent_teim identifier_tesim identityMetadata_citationCreator_t identityMetadata_citationTitle_t objectCreator_teim identityMetadata_otherId_t identityMetadata_sourceId_t lifecycle_teim originInfo_place_placeTerm_tesim originInfo_publisher_tesim obj_label_tesim obj_state_tesim originInfo_place_placeTerm_tesim originInfo_publisher_tesim otherId_t public_dc_contributor_tesim public_dc_coverage_tesim public_dc_creator_tesim public_dc_date_tesim public_dc_description_tesim public_dc_format_tesim public_dc_identifier_tesim public_dc_language_tesim public_dc_publisher_tesim public_dc_relation_tesim public_dc_rights_tesim public_dc_subject_tesim public_dc_title_tesim public_dc_type_tesim scale_teim sourceId_t tag_ssim title_tesim topic_tesim},
      :rows => 10,
      :facet => true,
      :'facet.mincount' => 1,
      :'f.wf_wps_ssim.facet.limit' => -1,
      :'f.wf_wsp_ssim.facet.limit' => -1,
      :'f.wf_swp_ssim.facet.limit' => -1,
      :'f.tag_ssim.facet.limit' => -1,
      :'f.tag_ssim.facet.sort' => 'index'
    }

    config.index.title_field = 'dc_title_ssi'
    config.index.display_type_field = 'content_type_ssim'

    config.show.title_field = 'dc_title_ssi'
    config.show.display_type_field = 'objectType_ssim'
    config.show.sections = {
      :default => %w(identification datastreams history contents),
      :item    => %w(identification datastreams history contents child_objects)
    }
    config.show.section_links = {
      'identification' => :render_full_view_links,
      'contents'       => :render_dor_workspace_link,
      'datastreams'    => :render_datastream_link
    }

    config.index.thumbnail_method = :render_index_thumbnail

    config.add_index_field 'id',               :label => 'DRUID'
    config.add_index_field 'dc_creator_ssi',   :label => 'Creator'
    config.add_index_field 'project_tag_ssim', :label => 'Project'

    config.add_show_field 'content_type_ssim',           :label => 'Content Type'
    config.add_show_field 'identifier_tesim',            :label => 'IDs'
    config.add_show_field 'originInfo_date_created_tesim', :label => 'Created'
    config.add_show_field 'obj_label_ssim',              :label => 'Label'
    config.add_show_field 'is_governed_by_ssim',         :label => 'Admin Policy'
    config.add_show_field 'is_member_of_collection_ssim',:label => 'Collection'
    config.add_show_field 'status_ssi',                  :label => 'Status'
    config.add_show_field 'objectType_ssim',             :label => 'Object Type'
    config.add_show_field 'id',                          :label => 'DRUID'
    config.add_show_field 'project_tag_ssim',            :label => 'Project'
    config.add_show_field 'source_id_ssim',              :label => 'Source'
    config.add_show_field 'tag_ssim',                    :label => 'Tags'
    config.add_show_field 'wf_error_ssim',               :label => 'Error'
    config.add_show_field 'collection_title_ssim',       :label => 'Collection Title'
    config.add_show_field 'metadata_source_ssi',         :label => 'MD Source'
    config.add_show_field 'preserved_size_dbtsi',        :label => 'Preservation Size'

    # exploded_tag_ssim indexes all tag prefixes (see IdentityMetadataDS#to_solr for a more exact
    # description), whereas tag_ssim only indexes whole tags.  we want to facet on exploded_tag_ssim
    # to get the hierarchy.
    config.add_facet_field 'exploded_tag_ssim',     :label => 'Tag', :partial => 'blacklight/hierarchy/facet_hierarchy'
    config.add_facet_field 'objectType_ssim',       :label => 'Object Type'
    config.add_facet_field 'content_type_ssim',     :label => 'Content Type'
    config.add_facet_field 'rights_primary_ssi',    :label => 'Access Rights'
    config.add_facet_field 'collection_title_ssim', :label => 'Collection',  :sort => 'index', :limit => 500
    config.add_facet_field 'apo_title_ssim',        :label => 'Admin Policy',:sort => 'index', :limit => 500
    config.add_facet_field 'current_version_isi',   :label => 'Version'
    config.add_facet_field 'processing_status_text_ssi', :label => 'Processing Status'
    config.add_facet_field 'released_to_ssim',      :label => 'Released To'
    config.add_facet_field 'wf_wps_ssim', :label => 'Workflows (WPS)', :partial => 'blacklight/hierarchy/facet_hierarchy'
    config.add_facet_field 'wf_wsp_ssim', :label => 'Workflows (WSP)', :partial => 'blacklight/hierarchy/facet_hierarchy'
    config.add_facet_field 'wf_swp_ssim', :label => 'Workflows (SWP)', :partial => 'blacklight/hierarchy/facet_hierarchy'
    config.add_facet_field 'has_model_ssim',  :label => 'Object Model'

    ## This is the costlier way to do this.  Instead convert this logic to delivering new values to a new field.  Then use normal add_facet_field.
    ## For now, if you add an additional case, make sure the DOR case gets the negation.
    config.add_facet_field 'source', :label => 'Object Source', :query => {
      :other  => { :label => 'DOR',        :fq => '-has_model_ssim:"info:fedora/afmodel:Hydrus_Item" AND -has_model_ssim:"info:fedora/afmodel:Hydrus_Collection" AND -has_model_ssim:"info:fedora/afmodel:Hydrus_AdminPolicyObject" AND -has_model_ssim:"info:fedora/dor:googleScannedBook"' },
      :google => { :label => 'Google',     :fq => 'has_model_ssim:"info:fedora/dor:googleScannedBook"' },
      :hyrdus => { :label => 'Hydrus/SDR', :fq => 'has_model_ssim:"info:fedora/afmodel:Hydrus_Item" OR has_model_ssim:"info:fedora/afmodel:Hydrus_Collection" OR has_model_ssim:"info:fedora/afmodel:Hydrus_AdminPolicyObject"' }
    }

    config.add_facet_field 'metadata_source_ssi', :label => 'Metadata Source'

    # common helper method since search results and reports all do the same configuration
    BlacklightConfigHelper.add_common_date_facet_fields_to_config config

    config.add_facet_field 'empties', :label => 'Empty Fields', :query => {
      :no_has_model => { :label => 'has_model_ssim',  :fq => "-has_model_ssim:*"}
    }

    config.add_facet_field 'sw_format_ssim', :label => 'SW Resource Type'
    config.add_facet_field 'sw_pub_date_facet_ssi', :label => 'SW Date'
    config.add_facet_field 'topic_ssim', :label => 'SW Topic'
    config.add_facet_field 'sw_subject_geographic_ssim', :label => 'SW Region'
    config.add_facet_field 'sw_subject_temporal_ssim', :label => 'SW Era'
    config.add_facet_field 'sw_genre_ssim', :label => 'SW Genre'
    config.add_facet_field 'sw_language_ssim', :label => 'SW Language'
    config.add_facet_field 'mods_typeOfResource_ssim', :label => 'MODS Resource Type'

    config.add_facet_fields_to_solr_request!        # deprecated in newer Blacklights

    config.add_search_field 'text', :label => 'All Fields'
    config.add_sort_field 'id asc', :label => 'Druid'
    config.add_sort_field 'score desc', :label => 'Relevance'
    config.add_sort_field 'creator_title_ssi asc', :label => 'Creator and Title'

    config.spell_max = 5

    config.facet_display = {
      :hierarchy => {
        'wf_wps' => [['ssim'], ':'],
        'wf_wsp' => [['ssim'], ':'],
        'wf_swp' => [['ssim'], ':'],
        'exploded_tag' => [['ssim'], ':']
      }
    }

    config.field_groups = {
      :identification => [
        %w(id objectType_ssim content_type_ssim status_ssi wf_error_ssim),
        %w(is_governed_by_ssim is_member_of_collection_ssim project_tag_ssim source_id_ssim preserved_size_dbtsi)
      ],
      :full_identification => [
        %w(id objectType_ssim content_type_ssim metadata_source_ssim),
        %w(is_governed_by_ssim is_member_of_collection_ssim project_tag_ssim source_id_ssim)
      ]
    }

  end

  def default_solr_doc_params(id = nil)
    id ||= params[:id]
    {
      :q => %{id:"#{id}"}
    }
  end

  def show
    params[:id] = 'druid:' + params[:id] unless params[:id].include? 'druid'
    @obj = Dor.find params[:id]

    return unless valid_user?(@obj)
    super()  # with or without an APO, if we get here, user is authorized to view
  end

  def datastream_view
    pid = params[:id].include?('druid') ? params[:id] : "druid:#{params[:id]}"
    @response, @document = get_solr_response_for_doc_id pid
    @obj = Dor.find pid, :lightweight => true
    data = @obj.datastreams[params[:dsid]].content
    raise ActionController::RoutingError.new('Not Found') if data.nil?
    send_data data, :type => 'xml', :disposition => 'inline'
  end

  def show_aspect
    pid = params[:id].include?('druid') ? params[:id] : "druid:#{params[:id]}"
    @obj ||= Dor.find(pid)
    @response, @document = get_solr_response_for_doc_id pid
    render :layout => request.xhr? ? false : true
  end

  def bulk_upload_form
    @object = Dor.find params[:id]
  end

  # Lets the user start a bulk metadata job (i.e. upload a metadata spreadsheet/XML file).
  def upload
    @object = Dor.find params[:id]

    directory_name = Time.now.strftime("%Y_%m_%d_%H_%M_%S_%L")
    output_directory = File.join(Argo::Config.bulk_metadata_directory, params[:druid], directory_name)
    temp_spreadsheet_filename = params[:spreadsheet_file].original_filename + '.' + directory_name

    # Temporary files are sometimes garbage collected before the Delayed Job is run, so make a copy and let the job delete it when it's done.
    temp_filename = Rails.root.join('tmp', temp_spreadsheet_filename)
    FileUtils.copy(params[:spreadsheet_file].path, temp_filename)
    ModsulatorJob.perform_later(temp_filename.to_s, output_directory, current_user.login, params[:filetypes], params[:xml_only], params[:note])

    redirect_to bulk_jobs_index_path(@object.id)
  end

  # Generates the index page for a given DRUID's past bulk metadata upload jobs.
  def bulk_jobs_index
    params[:id] = 'druid:' + params[:id] unless params[:id].include? 'druid'
    @obj = Dor.find params[:id]

    return unless valid_user?(@obj)
    @response, @document = get_solr_response_for_doc_id params[:id]
    @bulk_jobs = load_bulk_jobs(params[:id])
  end

  # Lets the user download the generated/cleaned XML metadata file that corresponds to a bulk metadata upload job.
  # This functionality is defined by the bulk_jobs_index method above.
  def bulk_jobs_xml
    desc_metadata_xml_file = find_desc_metadata_file(File.join(Argo::Config.bulk_metadata_directory, params[:id], params[:time]))
    if(File.exist?(desc_metadata_xml_file))
      send_file(desc_metadata_xml_file, :type => 'application/xml')
    else
      # Display error message and log the error
    end
  end

  def bulk_status_help
  end

  def bulk_jobs_help
    @obj = Dor.find params[:id]
  end

  private

  def set_user_obj_instance_var
    @user = current_user
  end

  def reformat_dates
    params.each do |key, val|
      begin
        if (key=~ /_datepicker/ && val=~ /[0-9]{2}\/[0-9]{2}\/[0-9]{4}/)
          val = DateTime.parse(val).beginning_of_day.utc.xmlschema
          field = key.split( '_after_datepicker').first.split('_before_datepicker').first
          params[:f][field] = '['+val.to_s+'Z TO *]'
        end
      rescue
      end
    end
  end

  # Given a directory with bulk metadata upload information (written by ModsulatorJob), loads the job data into a hash.
  def bulk_job_metadata(dir)
    job_info = Hash.new
    log_filename = File.join(dir, Argo::Config.bulk_metadata_log)
    if (File.directory?(dir) && File.readable?(dir))
      if (File.exist?(log_filename) && File.readable?(log_filename))
        File.open(log_filename, 'r') { |log_file|
          log_file.each_line do |line|

            # The log file is a very simple flat file (whitespace separated) format where the first token denotes the
            # field/type of information and the rest is the actual value.
            matched_strings = line.match(/^([^\s]+)\s+(.*)/)
            if (matched_strings && matched_strings.length == 3)
              job_info[matched_strings[1]] = matched_strings[2]
            end
          end
          job_info['dir'] = get_leafdir(dir)
        }
      end
    end
    return job_info
  end

  # Given a DRUID, loads any metadata bulk upload information associated with that DRUID into a hash.
  def load_bulk_jobs(druid)
    directory_list = Array.new
    bulk_info = Array.new()
    bulk_load_dir = File.join(Argo::Config.bulk_metadata_directory, druid)

    # The metadata bulk upload processing stores its logs and other information in a very simple directory structure
    if (File.directory?(bulk_load_dir))
      directory_list = Dir.glob("#{bulk_load_dir}/*")
    end

    directory_list.each do |d|
      bulk_info.push(bulk_job_metadata(d))
    end
    return bulk_info
  end

  # Determines whether or not the current user has permissions to view the current DOR object.
  def valid_user?(dor_object)
    begin
      @apo = dor_object.admin_policy_object
    rescue
      return false
    end

    if @apo
      unless @user.is_admin || @user.is_viewer || dor_object.can_view_metadata?(@user.roles(@apo.pid))
        render :status=> :forbidden, :text =>'forbidden'
        return false
      end
    else
      unless @user.is_admin || @user.is_viewer
        render :status=> :forbidden, :text =>'No APO, no access'
        return false
      end
    end
    return true
  end


  def get_leafdir(directory)
    return directory[Argo::Config.bulk_metadata_directory.length, directory.length].sub(/^\/+(.*)/, '\1')
  end


  def find_desc_metadata_file(job_output_directory)
    return File.join(job_output_directory, bulk_job_metadata(job_output_directory)['xml_filename'])
  end
end
