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
        obj=Dor.find(col['id'])
        res[col['id']]= obj.label
      end
      respond_to do |format|
        format.any(:json, :xml) { render request.format.to_sym => res }
      end
    end
  
    def rights_list
      apo_object = Dor.find(params[:apo_id], :lightweight => true)
      #get the xml from the defaultObjectRights datastream
      adm_xml = apo_object.defaultObjectRights.ng_xml 
      found=false
      result=Hash.new
      #looks for <group>stanford</group>
      adm_xml.xpath('//rightsMetadata/access[@type=\'read\']/machine/group').each  do |read|
        result['default']='Stanford (APO default)'
        result['world']='World'
        result['dark']='Dark'
        result['none']='None'
        found=true
      end
      #looks for a world tag
      adm_xml.xpath('//rightsMetadata/access[@type=\'read\']/machine/world').each do |read|
        result['stanford']='Stanford'
        result['default']='World (APO default)'
        result['dark']='Dark'
        result['none']='None'
        found=true
      end
    
      adm_xml.xpath('//rightsMetadata/access[@type=\'discover\']/machine/none').each do |read|
        result['stanford']='Stanford'
        result['world']='World'
        result['none']='None'
        result['dark']='Dark (APO default)'
      end
      #if it wasnt stanford or world default rights, there is either no object rights metadata or it doesnt include default rights
      if not found
        if adm_xml.xpath('//rightsMetadata').length > 0
          result['stanford']='Stanford'
          result['world']='World'
          result['default']='Dark (APO default)'
        else
          result['stanford']='Stanford'
          result['world']='World'
          result['dark']='Dark'
          result['none']='None'
          result['empty']='none (set in Assembly)'
        end
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
