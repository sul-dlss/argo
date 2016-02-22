class RegistrationController < ApplicationController
  include RegistrationHelper

  def form
    redirect_to register_items_url
  end

  def tracksheet
    druids   = Array(params[:druid])
    name     = params[:name] || 'tracksheet'
    sequence = params[:sequence] || 1
    response['content-disposition'] = "attachment; filename=#{name}-#{sequence}.pdf"
    pdf = generate_tracking_pdf(druids)
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
    # This method can be called without an :apo_id when
    # registering a new item, so it must handle this scenario.
    unless params[:apo_id].blank?
      apo_object = Dor.find(params[:apo_id])
      apo_object.administrativeMetadata.ng_xml.search('//registration/collection/@id').each do |node|
        col_id = node.to_s
        col_druid = col_id.gsub(/^druid:/, '')
        col_title_field = SolrDocument::FIELD_TITLE
        # grab the collection title from Solr, or fall back to DOR
        solr_doc = Blacklight.solr.find({:q => "id:\"#{col_id}\"", :rows => 1, :fl => col_title_field}).docs.first
        if solr_doc.present? && solr_doc[col_title_field].present?
          collections[col_id] = "#{short_label(solr_doc[col_title_field], truncate_limit)} (#{col_druid})"
        else
          begin # Title not found in Solr, so check DOR
            collection = find_druid(col_id)
            collections[col_id] = "#{short_label(collection.label, truncate_limit)} (#{col_druid})"
          rescue ActiveFedora::ObjectNotFoundError
            collections[col_id] = "Unknown Collection (#{col_druid})"
          end
        end
      end
    end
    respond_to do |format|
      format.any(:json, :xml) { render request.format.to_sym => collections }
    end
  end

  def rights_list
    result = {}
    # This method can be called without an :apo_id when
    # registering a new item, so it must handle this scenario.
    unless params[:apo_id].blank?
      apo_object = Dor.find(params[:apo_id], :lightweight => true)
      adm_xml = apo_object.defaultObjectRights.ng_xml

      # FIXME: should not be in Controller
      # figure out what the default option (if any) should be
      default_opt = nil
      if !adm_xml.xpath('//rightsMetadata/access[@type=\'read\']/machine/world').empty?
        # readable by world translates to World
        default_opt = 'world'
      elsif !adm_xml.xpath('//rightsMetadata/access[@type=\'read\']/machine/group[text()=\'Stanford\' or text()=\'stanford\']').empty?
        # TODO: this is stupid, should handle "stanford" regardless of the string's case, but the xpath parser doesn't support the lower-case() fn
        # readable by stanford translates to Stanford
        # TODO: found something indicating that xpath might support regex
        default_opt = 'stanford'
      elsif !adm_xml.xpath('//rightsMetadata/access[@type=\'read\']/machine/none').empty?
        # readable by none is either Citation Only (formerly "None") or Dark
        if !adm_xml.xpath('//rightsMetadata/access[@type=\'discover\']/machine/world').empty?
          # discoverable by world but readable by none translates to Citation Only/none
          default_opt = 'none'
        elsif !adm_xml.xpath('//rightsMetadata/access[@type=\'discover\']/machine/none').empty?
          # discoverable by none and readable by none translates to Dark
          default_opt = 'dark'
        end
      end

      # Iterate through the default version of the rights list.  if we found a
      # default option selection, label it in the UI text and key it as
      # 'default' (instead of its own name).  if we didn't find a default
      # option, we'll just return the default list of rights options with no
      # specified selection.
      Constants::DEFAULT_RIGHTS_OPTIONS.each do |val|
        if default_opt == val[1]
          result['default'] = "#{val[0]} (APO default)"
        else
          result[val[1]] = val[0]
        end
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
end
