class RegistrationController < ApplicationController

  def form
    redirect_to register_items_url
  end

  def tracksheet
    druids = Array(params[:druid])
    name = params[:name] || 'tracksheet'
    sequence = params[:sequence] || 1
    response['content-disposition'] = "attachment; filename=#{name}-#{sequence}.pdf"
    pdf = help.generate_tracking_pdf(druids)
    render :text => pdf.render, :content_type => :pdf
  end

  def form_list
    docs = Dor::SearchService.query(%{id:"#{params[:apo_id]}"}).docs
    md_format = docs.collect { |doc| doc['metadata_format_ssim'] }.flatten.first.to_s
    forms = JSON.parse(RestClient.get('http://lyberapps-prod.stanford.edu/forms.json'))
    result = forms[md_format.downcase].to_a.sort { |a,b| a[1].casecmp(b[1]) }
    respond_to do |format|
      format.any(:json, :xml) { render request.format.to_sym => result }
    end
  end

  def workflow_list
    docs = Dor::SearchService.query(%{id:"#{params[:apo_id]}"}).docs
    result = docs.collect { |doc| doc['registration_workflow_id_ssim'] }.compact
    apo_object = Dor.find(params[:apo_id], :lightweight => true)
    adm_xml = apo_object.administrativeMetadata.ng_xml
    adm_xml.search('//registration/workflow').each do |wf|
      result << wf['id']
    end

    respond_to do |format|
      format.any(:json, :xml) { render request.format.to_sym => result.flatten.sort }
    end
  end

  def collection_list
    res={''=>'None'}
    apo_object = Dor.find(params[:apo_id], :lightweight => true)
    adm_xml = apo_object.administrativeMetadata.ng_xml
    adm_xml.search('//registration/collection').each do |col|
      solr_doc=Blacklight.solr.find({:q => "id:\"#{col['id']}\"", :rows => 1, :fl => 'id,tag_ssim,dc_title_tesim'}).docs
      if solr_doc.first['dc_title_tesim'] && solr_doc.first['dc_title_tesim'].first
        res[col['id']]= "#{solr_doc.first['dc_title_tesim'].first}(#{col['id']})"
      else
        res[col['id']]= "#{col['id']}"
      end
    end
    respond_to do |format|
      format.any(:json, :xml) { render request.format.to_sym => res }
    end
  end

  def rights_list
    apo_object = Dor.find(params[:apo_id], :lightweight => true)
    adm_xml = apo_object.defaultObjectRights.ng_xml

    # figure out what the default option (if any) should be
    default_opt = nil
    if adm_xml.xpath('//rightsMetadata/access[@type=\'read\']/machine/world').length > 0
      # readable by world translates to World
      default_opt = 'world'
    elsif adm_xml.xpath('//rightsMetadata/access[@type=\'read\']/machine/group[text()=\'Stanford\' or text()=\'stanford\']').length > 0
      #TODO: this is stupid, should handle "stanford" regardless of the string's case, but the xpath parser doesn't support the lower-case() fn
      # readable by stanford translates to Stanford
      #TODO: found something indicating that xpath might support regex
      default_opt = 'stanford'
    elsif adm_xml.xpath('//rightsMetadata/access[@type=\'read\']/machine/none').length > 0
      # readable by none is either Citation Only (formerly "None") or Dark
      if adm_xml.xpath('//rightsMetadata/access[@type=\'discover\']/machine/world').length > 0
        # discoverable by world but readable by none translates to Citation Only/none
        default_opt = 'none'
      elsif adm_xml.xpath('//rightsMetadata/access[@type=\'discover\']/machine/none').length > 0
        # discoverable by none and readable by none translates to Dark
        default_opt = 'dark'
      end
    end

    # iterate through the default version of the rights list.  if we found a default option
    # selection, label it in the UI text and key it as 'default' (instead of its own name).  if
    # we didn't find a default option, we'll just return the default list of rights options with no
    # specified selection.
    result = Hash.new
    { 'world' => 'World', 'stanford' => 'Stanford', 'none' => 'Citation Only', 'dark' => 'Dark'}.each do |key, val|
      if default_opt == key
        result['default'] = "#{val} (APO default)"
      else
        result[key] = val
      end
    end

    respond_to do |format|
      format.any(:json, :xml) { render request.format.to_sym => result }
    end
  end

  def autocomplete
    response = Dor::SearchService.query('*:*', :rows => 0, :facets => { :fields => [params[:field]] }, :'facet.prefix' => params[:term].titlecase, :'facet.mincount' => 1, :'facet.limit' => 15 )
    result = response.facets.find { |f| f.name == params[:field] }.items.collect(&:value).sort
    respond_to do |format|
      format.any(:json, :xml) { render request.format.to_sym => result }
    end
  end

end
