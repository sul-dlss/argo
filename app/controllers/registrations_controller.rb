# frozen_string_literal: true

class RegistrationsController < ApplicationController
  def show
    @perm_keys = current_user.groups
  end

  def tracksheet
    druids   = Array(params[:druid])
    name     = params[:name] || 'tracksheet'
    sequence = params[:sequence] || 1
    response['content-disposition'] = "attachment; filename=#{name}-#{sequence}.pdf"
    pdf = TrackSheet.new(druids).generate_tracking_pdf
    render plain: pdf.render, content_type: :pdf
  end

  def workflow_list
    cocina_admin_policy = object_client.find
    workflows = ([Settings.apo.default_workflow_option] + Array(cocina_admin_policy.administrative.registrationWorkflow)).uniq

    respond_to do |format|
      format.any(:json, :xml) { render request.format.to_sym => workflows }
    end
  end

  ##
  # Data route to return all the registration collections listed for the given APO
  # @option params [String] `:apo_id` the druid for the APO
  # @option params [String] `:truncate` word boundary truncation limit
  # @return [Hash<String, String>] key represents collection druid, value represents collection title. entries sorted by title, except leading "None" option.
  def collection_list
    truncate_limit = (params[:truncate] || 60).to_i
    collections = {}
    registration_collection_ids_for_apo.each do |col_id|
      col_druid = col_id.gsub(/^druid:/, '')
      col_title_field = SolrDocument::FIELD_TITLE

      # grab the collection title from Solr, or fall back to DOR
      solr_doc = SearchService.query("id:\"#{col_id}\"",
                                     rows: 1,
                                     fl: col_title_field)['response']['docs'].first
      collections[col_id] = "#{short_label(solr_doc[col_title_field].first, truncate_limit)} (#{col_druid})"
    end

    # before returning the list, sort by collection name, and add a "None" option at the top
    collections = { '' => 'None' }.merge((collections.sort_by { |_k, col_title| col_title }).to_h)
    respond_to do |format|
      format.any(:json, :xml) { render request.format.to_sym => collections }
    end
  end

  def rights_list
    cocina_admin_policy = object_client.find
    default_opt = RightsLabeler.label(cocina_admin_policy.administrative.defaultObjectRights)

    # iterate through the default version of the rights list.  if we found a default option
    # selection, label it in the UI text and key it as 'default' (instead of its own name).  if
    # we didn't find a default option, we'll just return the default list of rights options with no
    # specified selection.
    result = {}
    Constants::REGISTRATION_RIGHTS_OPTIONS.each do |val|
      if default_opt == val[1]
        result['default'] = "#{val[0]} (APO default)"
      else
        result[val[1]] = val[0]
      end
    end

    respond_to do |format|
      format.any(:json, :xml) { render request.format.to_sym => result }
    end
  end

  def autocomplete
    facet_field = params[:field]
    response = SearchService.query(
      '*:*',
      rows: 0,
      'facet.field': facet_field,
      'facet.prefix': params[:term].titlecase,
      'facet.mincount': 1,
      'facet.limit': 15,
      'json.nl': 'map'
    )
    result = response['facet_counts']['facet_fields'][facet_field].keys.sort
    respond_to do |format|
      format.any(:json, :xml) { render request.format.to_sym => result }
    end
  end

  private

  # @param [String] label string to truncate at word boundary
  # @param [Integer] truncate_limit character limit for truncation target
  def short_label(label, truncate_limit = 60)
    label.truncate(truncate_limit, separator: /\s/)
  end

  def apo_id
    druid = params[:apo_id]
    raise ArgumentError if druid.nil?

    return druid if druid.starts_with?('druid:')

    "druid:#{druid}"
  end

  def object_client
    Dor::Services::Client.object(apo_id)
  end

  def registration_collection_ids_for_apo
    Array(object_client.find.administrative.collectionsForRegistration)
  end
end
