class RegistrationController < ApplicationController

  def default_html_head
    stylesheet_links << ['registration']
    javascript_includes << ['registration']
  end

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
    format = docs.collect { |doc|
      md_val=doc['administrativeMetadata_metadata_format_t'] ? doc['administrativeMetadata_metadata_format_t'] : doc['metadata_format_t']
      md_val }.flatten.first.to_s
    forms = JSON.parse(RestClient.get('http://lyberapps-prod.stanford.edu/forms.json'))
    result = forms[format.downcase].to_a.sort { |a,b| a[1].casecmp(b[1]) }
    respond_to do |format|
      format.any(:json, :xml) { render request.format.to_sym => result }
    end
  end

  def workflow_list
    docs = Dor::SearchService.query(%{id:"#{params[:apo_id]}"}).docs
    result = docs.collect { |doc| doc['registration_workflow_id_t'] }.compact
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
      solr_doc=Blacklight.solr.find({:q => "id:\"#{col['id']}\"", :rows => 1, :fl => 'id,tag_t,dc_title_t'}).docs
      if solr_doc.first['dc_title_t'] and solr_doc.first['dc_title_t'].first
        res[col['id']]= "#{solr_doc.first['dc_title_t'].first}(#{col['id']})"
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
    found = false
    result = Hash.new

    if adm_xml.xpath('//rightsMetadata/access[@type=\'discover\']/machine/none').length > 0
    # looks for a none tag
      result['world'] = 'World'
      result['stanford'] = 'Stanford'
      result['none'] = 'Citation Only'
      result['dark'] = 'Dark (APO default)'
    elsif adm_xml.xpath('//rightsMetadata/access[@type=\'read\']/machine/group').length > 0
    # looks for a group tag
      result['world'] = 'World'
      result['default'] = 'Stanford (APO default)'
      result['none'] = 'Citation Only'
      result['dark'] = 'Dark'
    elsif adm_xml.xpath('//rightsMetadata/access[@type=\'read\']/machine/world').length > 0
    # looks for a world tag
      result['default'] = 'World (APO default)'
      result['stanford'] = 'Stanford'
      result['none'] = 'Citation Only'
      result['dark'] = 'Dark'
    else
    #if it wasnt stanford or world default rights, there is either no object rights metadata or it doesnt include default rights
      result['world'] = 'World'
      result['stanford'] = 'Stanford'
      result['none'] = 'Citation Only'
      result['dark'] = 'Dark'
    end

    respond_to do |format|
      format.any(:json, :xml) { render request.format.to_sym => result }
    end
  end

  def autocomplete
    response = Dor::SearchService.query('*:*', :rows => 0, :facets => { :fields => [params[:field]] }, :'facet.prefix' => params[:term].titlecase, :'facet.mincount' => 1, :'facet.limit' => 15 )
    result = response.facets.find { |f| f.name == params[:field] }.items.collect { |f| f.value }.sort
    respond_to do |format|
      format.any(:json, :xml) { render request.format.to_sym => result }
    end
  end

end
