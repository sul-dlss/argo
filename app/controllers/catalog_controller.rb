# -*- encoding : utf-8 -*-
require 'blacklight/catalog'
class CatalogController < ApplicationController
  include Blacklight::Marc::Catalog

  include BlacklightSolrExtensions
  include Blacklight::Catalog
  include Argo::AccessControlsEnforcement
  helper ArgoHelper
  include SpreadsheetHelper
  include DateFacetConfigurations

  before_filter :reformat_dates, :set_user_obj_instance_var
  before_action :show_aspect, only: [:dc, :ds]

  CatalogController.solr_search_params_logic << :add_access_controls_to_solr_params

  configure_blacklight do |config|
    # common helper method since search results and reports share most of this config
    BlacklightConfigHelper.add_common_default_solr_params_to_config! config
    config.default_solr_params[:rows] = 10

    config.document_solr_request_handler = '/document'

    config.document_presenter_class = ArgoPresenter

    config.index.display_type_field = 'content_type_ssim'

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

    config.add_index_field 'id',                              label: 'DRUID'
    config.add_index_field 'objectType_ssim',                 label: 'Object Type'
    config.add_index_field 'content_type_ssim',               label: 'Content Type'
    config.add_index_field 'status_ssi',                      label: 'Status'
    config.add_index_field SolrDocument::FIELD_APO_ID,        label: 'Admin Policy',      helper_method: :link_to_admin_policy
    config.add_index_field SolrDocument::FIELD_COLLECTION_ID, label: 'Collection',        helper_method: :links_to_collections
    config.add_index_field 'project_tag_ssim',                label: 'Project',           link_to_search: true
    config.add_index_field 'identifier_tesim',                label: 'IDs',               helper_method: :value_for_identifier_tesim
    config.add_index_field 'originInfo_date_created_tesim',   label: 'Created'
    config.add_index_field 'obj_label_ssim',                  label: 'Label'
    config.add_index_field 'source_id_ssim',                  label: 'Source'
    config.add_index_field 'wf_error_ssim',                   label: 'Error',             helper_method: :value_for_wf_error
    config.add_index_field 'preserved_size_dbtsi',            label: 'Preservation Size', helper_method: :preserved_size_human

    config.add_show_field 'content_type_ssim',           :label => 'Content Type'
    config.add_show_field 'identifier_tesim',            :label => 'IDs',               helper_method: :value_for_identifier_tesim
    config.add_show_field 'originInfo_date_created_tesim', :label => 'Created'
    config.add_show_field 'obj_label_ssim',              :label => 'Label'
    config.add_show_field SolrDocument::FIELD_APO_ID,    :label => 'Admin Policy',      helper_method: :link_to_admin_policy
    config.add_show_field SolrDocument::FIELD_COLLECTION_ID, :label => 'Collection',    helper_method: :links_to_collections
    config.add_show_field 'status_ssi',                  :label => 'Status'
    config.add_show_field 'objectType_ssim',             :label => 'Object Type'
    config.add_show_field 'id',                          :label => 'DRUID'
    config.add_show_field 'project_tag_ssim',            :label => 'Project',           link_to_search: true
    config.add_show_field 'source_id_ssim',              :label => 'Source'
    config.add_show_field 'tag_ssim',                    :label => 'Tags'
    config.add_show_field 'wf_error_ssim',               :label => 'Error',             helper_method: :value_for_wf_error
    config.add_show_field 'metadata_source_ssi',         :label => 'MD Source'
    config.add_show_field 'preserved_size_dbtsi',        :label => 'Preservation Size', helper_method: :preserved_size_human

    # exploded_tag_ssim indexes all tag prefixes (see IdentityMetadataDS#to_solr for a more exact
    # description), whereas tag_ssim only indexes whole tags.  we want to facet on exploded_tag_ssim
    # to get the hierarchy.
    config.add_facet_field 'exploded_tag_ssim',               label: 'Tag',                 limit: 9999, partial: 'blacklight/hierarchy/facet_hierarchy'
    config.add_facet_field 'objectType_ssim',                 label: 'Object Type',         limit: 10
    config.add_facet_field 'content_type_ssim',               label: 'Content Type',        limit: 10
    config.add_facet_field 'rights_primary_ssi',              label: 'Access Rights',       limit: 10
    config.add_facet_field 'use_license_machine_ssi',         label: 'License',             limit: 10
    config.add_facet_field 'nonhydrus_collection_title_ssim', label: 'Collection',          limit: 9999, sort: 'index'
    config.add_facet_field 'hydrus_collection_title_ssim',    label: 'Hydrus Collection',   limit: 9999, sort: 'index'
    config.add_facet_field 'nonhydrus_apo_title_ssim',        label: 'Admin Policy',        limit: 9999, sort: 'index'
    config.add_facet_field 'hydrus_apo_title_ssim',           label: 'Hydrus Admin Policy', limit: 9999, sort: 'index'
    config.add_facet_field 'current_version_isi',             label: 'Version',             limit: 10
    config.add_facet_field 'processing_status_text_ssi',      label: 'Processing Status',   limit: 10
    config.add_facet_field 'released_to_ssim',                label: 'Released To',         limit: 10
    config.add_facet_field 'wf_wps_ssim',                     label: 'Workflows (WPS)',     limit: 9999, partial: 'blacklight/hierarchy/facet_hierarchy'
    config.add_facet_field 'wf_wsp_ssim',                     label: 'Workflows (WSP)',     limit: 9999, partial: 'blacklight/hierarchy/facet_hierarchy'
    config.add_facet_field 'wf_swp_ssim',                     label: 'Workflows (SWP)',     limit: 9999, partial: 'blacklight/hierarchy/facet_hierarchy'
    config.add_facet_field 'has_model_ssim',                  label: 'Object Model',        limit: 10

    ## This is the costlier way to do this.  Instead convert this logic to delivering new values to a new field.  Then use normal add_facet_field.
    ## For now, if you add an additional case, make sure the DOR case gets the negation.
    config.add_facet_field 'source', :label => 'Object Source', :query => {
      :other  => { :label => 'DOR',        :fq => '-has_model_ssim:"info:fedora/afmodel:Hydrus_Item" AND -has_model_ssim:"info:fedora/afmodel:Hydrus_Collection" AND -has_model_ssim:"info:fedora/afmodel:Hydrus_AdminPolicyObject" AND -has_model_ssim:"info:fedora/dor:googleScannedBook"' },
      :google => { :label => 'Google',     :fq => 'has_model_ssim:"info:fedora/dor:googleScannedBook"' },
      :hyrdus => { :label => 'Hydrus/SDR', :fq => 'has_model_ssim:"info:fedora/afmodel:Hydrus_Item" OR has_model_ssim:"info:fedora/afmodel:Hydrus_Collection" OR has_model_ssim:"info:fedora/afmodel:Hydrus_AdminPolicyObject"' }
    }

    config.add_facet_field 'metadata_source_ssi', :label => 'Metadata Source'

    # common method since search results and reports all do the same configuration
    add_common_date_facet_fields_to_config! config

    config.add_facet_field 'empties', :label => 'Empty Fields', :query => {
      :no_rights_characteristics   => { :label => 'No Rights Characteristics',  :fq => '-rights_characteristics_ssim:*' },
      :no_content_type             => { :label => 'No Content Type',            :fq => '-content_type_ssim:*' },
      :no_has_model                => { :label => 'No Object Model',            :fq => '-has_model_ssim:*' },
      :no_objectType               => { :label => 'No Object Type',             :fq => '-objectType_ssim:*' },
      :no_object_title             => { :label => 'No Object Title',            :fq => '-dc_title_ssi:*' },
      :no_is_governed_by           => { :label => 'No APO',                     :fq => "-#{SolrDocument::FIELD_APO_ID}:*" },
      :no_collection_title         => { :label => 'No Collection Title',        :fq => "-#{SolrDocument::FIELD_COLLECTION_TITLE}:*" },
      :no_copyright                => { :label => 'No Copyright',               :fq => '-copyright_ssim:*' },
      :no_license                  => { :label => 'No License',                 :fq => '-use_license_machine_ssi:*' },
      :no_public_dc_creator        => { :label => 'No MODS Creator',            :fq => '-public_dc_creator_tesim:*' },
      # TODO: mods extent (?)
      # TODO: mods form (?)
      :no_sw_genre                 => { :label => 'No SW Genre',                :fq => '-sw_genre_ssim:*' },   # spec said "mods genre"
      :no_public_dc_language       => { :label => 'No MODS Language',           :fq => '-public_dc_language_tesim:*' },
      :no_public_dc_subject        => { :label => 'No MODS Subject',            :fq => '-public_dc_subject_tesim:*' },
      :no_mods_typeOfResource_ssim => { :label => 'No MODS typeOfResource',      :fq => '-mods_typeOfResource_ssim:*' },
      :no_sw_pub_date_sort         => { :label => 'No SW Date',                 :fq => '-sw_pub_date_sort_ssi:*' },
      :no_sw_subject_temporal      => { :label => 'No SW Era',                  :fq => '-sw_subject_temporal_ssim:*' },
      :no_sw_subject_geographic    => { :label => 'No SW Region',               :fq => '-sw_subject_geographic_ssim:*' },
      # TODO: sw resource type (?)  is this different from MODS resource type?
      :no_use_statement            => { :label => 'No Use & Reproduction Statement', :fq => '-use_statement_ssim:*' }
    }

    config.add_facet_field 'sw_format_ssim',             label: 'SW Resource Type',   limit: 10
    config.add_facet_field 'sw_pub_date_facet_ssi',      label: 'SW Date',            limit: 10
    config.add_facet_field 'topic_ssim',                 label: 'SW Topic',           limit: 10
    config.add_facet_field 'sw_subject_geographic_ssim', label: 'SW Region',          limit: 10
    config.add_facet_field 'sw_subject_temporal_ssim',   label: 'SW Era',             limit: 10
    config.add_facet_field 'sw_genre_ssim',              label: 'SW Genre',           limit: 10
    config.add_facet_field 'sw_language_ssim',           label: 'SW Language',        limit: 10
    config.add_facet_field 'mods_typeOfResource_ssim',   label: 'MODS Resource Type', limit: 10

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
        [SolrDocument::FIELD_APO_ID, SolrDocument::FIELD_COLLECTION_ID].map(&:to_s) + %w(project_tag_ssim source_id_ssim preserved_size_dbtsi)
      ],
      :full_identification => [
        %w(id objectType_ssim content_type_ssim metadata_source_ssi),
        [SolrDocument::FIELD_APO_ID, SolrDocument::FIELD_COLLECTION_ID].map(&:to_s) + %w(project_tag_ssim source_id_ssim)
      ]
    }

    config.add_results_collection_tool(:report_view_toggle)

    ##
    # Configure document actions framework
    config.index.document_actions.delete(:bookmark)

  end

  def default_solr_doc_params(id = nil)
    id ||= params[:id]
    {
      :q => %(id:"#{id}")
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

  def dc
  end

  def ds
  end

  def bulk_upload_form
    @object = Dor.find params[:id]
  end

  # Lets the user start a bulk metadata job (i.e. upload a metadata spreadsheet/XML file).
  def upload
    @apo = Dor.find params[:id]

    directory_name = Time.now.strftime('%Y_%m_%d_%H_%M_%S_%L')
    output_directory = File.join(Argo::Config.bulk_metadata_directory, params[:druid], directory_name)
    temp_spreadsheet_filename = params[:spreadsheet_file].original_filename + '.' + directory_name

    # Temporary files are sometimes garbage collected before the Delayed Job is run, so make a copy and let the job delete it when it's done.
    temp_filename = Rails.root.join('tmp', temp_spreadsheet_filename)
    FileUtils.copy(params[:spreadsheet_file].path, temp_filename)
    ModsulatorJob.perform_later(@apo.id, temp_filename.to_s, output_directory, current_user.login, params[:filetypes], params[:xml_only], params[:note])

    redirect_to bulk_jobs_index_path(@apo.id)
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
    if File.exist?(desc_metadata_xml_file)
      send_file(desc_metadata_xml_file, :type => 'application/xml')
    else
      # Display error message and log the error
    end
  end

  def bulk_jobs_csv
    csv_file = File.join(Argo::Config.bulk_metadata_directory, params[:id], params[:time], 'log.csv')
    if File.exist?(csv_file)
      send_file(csv_file, :type => 'text/csv')
    else
      # Display error message and log the error
    end
  end

  def bulk_jobs_log
    @apo  = params[:id]
    @time = params[:time]
    job_directory = File.join(Argo::Config.bulk_metadata_directory, @apo, @time)

    # Generate both the actual log messages that go in the HTML and the CSV, since both need to be ready when the table is displayed to the user
    @druid_log = load_user_log(@apo, job_directory)
    user_log_csv(@druid_log, job_directory)
  end

  def bulk_status_help
  end

  def bulk_jobs_help
  end

  def bulk_jobs_delete
    @apo = params[:id]
    directory_to_delete = File.join(Argo::Config.bulk_metadata_directory, params[:dir])
    FileUtils.remove_dir(directory_to_delete, true)
    redirect_to bulk_jobs_index_path(@apo)
  end

  private

  def show_aspect
    pid = params[:id].include?('druid') ? params[:id] : "druid:#{params[:id]}"
    @obj ||= Dor.find(pid)
    @response, @document = get_solr_response_for_doc_id pid
  end

  def set_user_obj_instance_var
    @user = current_user
  end

  def reformat_dates
    params.each do |key, val|
      begin
        next unless key =~ /_datepicker/ && val =~ /[0-9]{2}\/[0-9]{2}\/[0-9]{4}/
        val = DateTime.parse(val).beginning_of_day.utc.xmlschema
        field = key.split( '_after_datepicker').first.split('_before_datepicker').first
        params[:f][field] = '[' + val.to_s + 'Z TO *]'
      rescue
      end
    end
  end

  # Given a directory with bulk metadata upload information (written by ModsulatorJob), loads the job data into a hash.
  def bulk_job_metadata(dir)
    success = 0
    job_info = {}
    log_filename = File.join(dir, Argo::Config.bulk_metadata_log)
    if File.directory?(dir) && File.readable?(dir) && File.exist?(log_filename) && File.readable?(log_filename)
      File.open(log_filename, 'r') do |log_file|
        log_file.each_line do |line|

          # The log file is a very simple flat file (whitespace separated) format where the first token denotes the
          # field/type of information and the rest is the actual value.
          matched_strings = line.match(/^([^\s]+)\s+(.*)/)
          next unless matched_strings && matched_strings.length == 3
          job_info[matched_strings[1]] = matched_strings[2]
          success += 1 if matched_strings[1] == 'argo.bulk_metadata.bulk_log_job_save_success'
          job_info['error'] = 1 if @@error_messages.include?(matched_strings[1])
        end
        job_info['dir'] = get_leafdir(dir)
        job_info['argo.bulk_metadata.bulk_log_druids_loaded'] = success
      end
    end
    job_info
  end

  # Given a DRUID, loads any metadata bulk upload information associated with that DRUID into a hash.
  def load_bulk_jobs(druid)
    directory_list = []
    bulk_info = []
    bulk_load_dir = File.join(Argo::Config.bulk_metadata_directory, druid)

    # The metadata bulk upload processing stores its logs and other information in a very simple directory structure
    if File.directory?(bulk_load_dir)
      directory_list = Dir.glob("#{bulk_load_dir}/*")
    end

    directory_list.each do |d|
      bulk_info.push(bulk_job_metadata(d))
    end

    # Sort by start time (newest first)
    sorted_info = bulk_info.sort_by { |b| b['argo.bulk_metadata.bulk_log_job_start'] }
    sorted_info.reverse!
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
        render :status => :forbidden, :text => 'forbidden'
        return false
      end
    else
      unless @user.is_admin || @user.is_viewer
        render :status => :forbidden, :text => 'No APO, no access'
        return false
      end
    end
    true
  end

  def get_leafdir(directory)
    directory[Argo::Config.bulk_metadata_directory.length, directory.length].sub(/^\/+(.*)/, '\1')
  end

  def find_desc_metadata_file(job_output_directory)
    File.join(job_output_directory, bulk_job_metadata(job_output_directory)['argo.bulk_metadata.bulk_log_xml_filename'])
  end
end
