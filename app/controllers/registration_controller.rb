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
    render :text => pdf.render, :content_type => :pdf
  end

  def workflow_list
    docs = Dor::SearchService.query(%(id:"#{params[:apo_id]}")).docs
    result = docs.collect { |doc| doc['registration_workflow_id_ssim'] }.compact
    apo_object = Dor.find(params[:apo_id], :lightweight => true)
    adm_xml = apo_object.administrativeMetadata.ng_xml
    adm_xml.search('//registration/workflow').each do |wf|
      result << wf['id']
    end

    respond_to do |format|
      format.any(:json, :xml) { render request.format.to_sym => result.flatten.uniq.sort }
    end
  end

  ##
  # Data route to return all the registration collections listed for the given APO
  # @option params [String] `:apo_id` the druid for the APO
  # @option params [String] `:truncate` word boundary truncation limit
  def collection_list
    truncate_limit = (params[:truncate] || 60).to_i
    collections = { '' => 'None' }
    apo_object = Dor.find(params[:apo_id])
    apo_object.administrativeMetadata.ng_xml.search('//registration/collection/@id').each do |node|
      col_id = node.to_s
      col_druid = col_id.gsub(/^druid:/, '')
      col_title_field = SolrDocument::FIELD_TITLE
      # grab the collection title from Solr, or fall back to DOR
      solr_doc = Blacklight.default_index.connection.find({
        q: "id:\"#{col_id}\"",
        rows: 1,
        fl: col_title_field
      }).docs.first
      if solr_doc.present? && solr_doc[col_title_field].present?
        collections[col_id] = "#{short_label(solr_doc[col_title_field], truncate_limit)} (#{col_druid})"
      else
        begin # Title not found in Solr, so check DOR
          collection = Dor.find(col_id)
          collections[col_id] = "#{short_label(collection.label, truncate_limit)} (#{col_druid})"
        rescue ActiveFedora::ObjectNotFoundError
          collections[col_id] = "Unknown Collection (#{col_druid})"
        end
      end
    end
    respond_to do |format|
      format.any(:json, :xml) { render request.format.to_sym => collections }
    end
  end

  def rights_list
    apo_object = Dor.find(params[:apo_id], :lightweight => true)

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
    facet_fields = { fields: [facet_field] }
    response = Dor::SearchService.query(
      '*:*',
      {
        rows: 0,
        facets: facet_fields,
        :'facet.prefix' => params[:term].titlecase,
        :'facet.mincount' => 1,
        :'facet.limit' => 15
      }
    )
    result = response.facets.find { |f| f.name == facet_field }.items.map(&:value).sort
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
end
