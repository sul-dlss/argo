# frozen_string_literal: true

class RegistrationController < ApplicationController
  def form
    redirect_to register_items_url
  end

  def tracksheet
    druids   = Array(params[:druid])
    name     = params[:name] || 'tracksheet'
    sequence = params[:sequence] || 1
    response['content-disposition'] = "attachment; filename=#{name}-#{sequence}.pdf"
    pdf = TrackSheet.new(druids).generate_tracking_pdf
    render plain: pdf.render, content_type: :pdf
  end

  def workflows_for_apo(apo_id)
    docs = Dor::SearchService.query(%(id:"#{apo_id}"))['response']['docs']
    result = docs.collect { |doc| doc['registration_workflow_id_ssim'] }.compact
    apo_object = Dor.find(apo_id)
    adm_xml = apo_object.administrativeMetadata.ng_xml
    adm_xml.search('//registration/workflow').each do |wf|
      result << wf['id']
    end
    # always put default workflow option first, then alpha sort the rest
    result.flatten.sort.unshift(Settings.apo.default_workflow_option).uniq
  end

  def workflow_list
    respond_to do |format|
      format.any(:json, :xml) { render request.format.to_sym => workflows_for_apo(params[:apo_id]) }
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
    registration_collection_ids_for_apo(params[:apo_id]).each do |col_id|
      col_druid = col_id.gsub(/^druid:/, '')
      col_title_field = SolrDocument::FIELD_TITLE

      # grab the collection title from Solr, or fall back to DOR
      solr_doc = Dor::SearchService.query("id:\"#{col_id}\"",
                                          rows: 1,
                                          fl: col_title_field)['response']['docs'].first

      if solr_doc.present? && solr_doc[col_title_field].present?
        collections[col_id] = "#{short_label(solr_doc[col_title_field], truncate_limit)} (#{col_druid})"
      else
        Honeybadger.notify("Unable to find title of the collection #{col_id} in Solr. Checking Fedora, but this is slow.")
        begin # Title not found in Solr, so check DOR
          collection = Dor.find(col_id)
          collections[col_id] = "#{short_label(collection.label, truncate_limit)} (#{col_druid})"
        rescue ActiveFedora::ObjectNotFoundError
          Honeybadger.notify("Unable to find the collection #{col_id} in Fedora, but it's listed in the administrativeMetadata datastream for #{params[:apo_id]}")
          col_not_found_warning = "#{params[:apo_id]} lists collection #{col_id} for registration, but it wasn't found in Fedora."
          Rails.logger.warning col_not_found_warning
        end
      end
    end

    # before returning the list, sort by collection name, and add a "None" option at the top
    collections = { '' => 'None' }.merge((collections.sort_by { |_k, col_title| col_title }).to_h)
    respond_to do |format|
      format.any(:json, :xml) { render request.format.to_sym => collections }
    end
  end

  def rights_list
    apo_object = Dor.find(params[:apo_id])

    default_opt = apo_object.default_rights

    # iterate through the default version of the rights list.  if we found a default option
    # selection, label it in the UI text and key it as 'default' (instead of its own name).  if
    # we didn't find a default option, we'll just return the default list of rights options with no
    # specified selection.
    result = {}
    Constants::DEFAULT_RIGHTS_OPTIONS.each do |val|
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
    response = Dor::SearchService.query(
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

  # @param [String] s string to truncate at word boundary
  # @param [Integer] truncate_limit character limit for truncation target
  def short_label(s, truncate_limit = 60)
    s.truncate(truncate_limit, separator: /\s/)
  end

  def registration_collection_ids_for_apo(apo_id)
    Dor.find(apo_id).default_collections
  end
end
