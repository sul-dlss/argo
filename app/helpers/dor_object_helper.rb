module DorObjectHelper
  # Metadata helpers
  def retrieve_terms doc
    terms = {
      :creator   => { :selector => ['public_dc_creator_t', 'mods_creator_t', 'mods_name_t', 'dc_creator_t'] },
      :title     => { :selector => ['public_dc_title_t', 'mods_title_t', 'dc_title_t', 'obj_label_t'], :combiner => lambda { |s| s.join(' -- ') } },
      :place     => { :selector => ['mods_originInfo_place_placeTerm_t'] },
      :publisher => { :selector => ['public_dc_publisher_t', 'mods_originInfo_publisher_t', 'dc_publisher_t'] },
      :date      => { :selector => ['public_dc_date_t', 'mods_dateissued_t', 'mods_datecreated_t', 'dc_date_t'] }
    }
    result = {}
    terms.each_pair do |term,finder|
      finder[:selector].each do |key|
        if doc[key].present?
          val = doc[key]
          com = finder[:combiner]
          result[term] = com ? com.call(val) : val.first
          break
        end
      end
    end
    result
  end
  
  def render_citation doc
    terms = retrieve_terms(doc)
    result = ''
    result += "#{terms[:creator].html_safe} " if terms[:creator].present?
    result += "<em>#{terms[:title].html_safe}</em>" if terms[:title].present?
    origin_info = terms.values_at(:publisher, :place, :date).compact.join(', ')
    result += ": #{origin_info.html_safe}" if origin_info.present?
    result.html_safe
  end
	  def render_embargo_date_reset(pid, current_user)
				#	 new_date=Datetime.parse(new_date)
				#		if(new_date.past?)
			#				raise 'The new date must be in the future!'
			#			end
						if is_permitted(current_user, :modify, pid)	
						  form_tag embargo_update_item_url(pid), :class => 'dialogLink' do
						  button_tag("Change Embargo", :type => 'submit')
						 end
					 else
						 ''
	       end
			end
	def is_permitted(current_user, operation, pid)
		return true
	end
  def render_datetime(datetime)
    if datetime.nil?
      ''
    else

      #this needs to use the timezone set in config.time_zone
      begin
        zone = ActiveSupport::TimeZone.new("Pacific Time (US & Canada)")
        d = datetime.is_a?(Time) ? datetime : DateTime.parse(datetime).in_time_zone(zone)
        I18n.l(d)
      rescue
        d = datetime.is_a?(Time) ? datetime : Time.parse(datetime.to_s)
        d.strftime('%Y-%m-%d %I:%M%p')
      end
    
    end
  end
  
  def render_events doc, obj
    events = structure_from_solr(doc,'event')
    unless events.empty?
      events = events.event.collect do |event|
        { :when => render_datetime(event.when), :who => event.who, :what => event.message }
      end
    end
    render :partial => 'catalog/_show_partials/events', :locals => { :document => doc, :object => obj, :events => events }
  end
  
  def render_milestones doc, obj
    milestones = SolrDocument::get_milestones(doc)
    render :partial => 'catalog/_show_partials/milestones', :locals => { :document => doc, :object => obj, :milestones => milestones }
  end
  
  def render_status (doc)
    status = 0
    version = ''
    status_hash={
      0 => version + ' ',
      1 => version + ' Registered',
      2 => version + ' In process',
      3 => version + ' In process (described)',
      4 => version + ' In process (described, published)',
      5 => version + ' In process (described, published, deposited)',
      6 => version + ' Accessioned',
      7 => version + ' Accessioned (indexed)',
      8 => version + ' Accessioned (indexed, ingested)'
      }           
    status_time=nil
    lifecycle_field = doc.has_key?('lifecycle_display') ? 'lifecycle_display' : 'lifecycle_facet'
    Array(doc[lifecycle_field]).each do |m| 
      (name,time) = m.split(/:/,2)
      case name
      when 'registered'
        if status<1
          status=1
          status_time=time
        end        
      when 'submitted'
        if status<2
          status=2
          status_time=time
        end
      when 'described'
        if status<3
          status=3
          status_time=time
        end
      when 'published'
        if status<4
          status=4
          status_time=time
        end
      when 'deposited'
        if status<5
          status=5
          status_time=time
        end
      when 'accessioned'
        if status<6
          status=6
          status_time=time
        end
      when 'indexed'
        if status<7
          status=7
          status_time=time
        end
      when 'shelved'
        if status<8
          status=8
          status_time=time
        end
    end
  end
  embargo=''
  if(doc.has_key?('embargoMetadata_t'))
    embargo_data=doc['embargoMetadata_t']
    text=embargo_data.split.first
    date=embargo_data.split.last
    
    if text == 'released'
      #do nothing at the moment, we arent displaying these
    else
      embargo= ' (embargoed until '+render_datetime(date.to_s)+')' 
      #add a date picker and button to change the embargo date for those who should be able to.
      embargo+=render :partial => 'items/embargo_form'
      
    end
  end
    result=status_hash[status].to_s+' '+render_datetime(status_time).to_s+embargo
    result=result.html_safe
  end
  
  def render_workflows doc, obj
    workflows = {}
    Array(doc[ActiveFedora::SolrService.solr_name('workflow_status', :string, :displayable)]).each do |line|
      (wf,status,errors) = line.split(/\|/)
      workflows[wf] = { :status => status, :errors => errors.to_i }
    end
    render :partial => 'catalog/_show_partials/workflows', :locals => { :document => doc, :object => obj, :workflows => workflows }
  end
  #this should be in a config file
  def is_admin? groups
  if groups.include? "workgroup:dlss:dor-admin"
  	return true
  end
  false
  end
  # Datastream helpers
  CONTROL_GROUP_TEXT = { 'X' => 'inline', 'M' => 'managed', 'R' => 'redirect', 'E' => 'external' }
  def parse_specs spec_string
    Hash[[:dsid,:control_group,:mime_type,:version,:size,:label].zip(spec_string.split(/\|/))]
  end
  
  def render_ds_control_group doc, specs
    cg = specs[:control_group] || 'X'
    "#{cg}/#{CONTROL_GROUP_TEXT[cg]}"
  end
  
  def render_ds_id doc, specs
    link_to specs[:dsid], ds_aspect_view_catalog_path(doc['id'], specs[:dsid]), :class => 'dialogLink', :title => specs[:dsid]
  end
  
  def render_ds_mime_type doc, specs
    specs[:mime_type]
  end
  
  def render_ds_version doc, specs
    "v#{specs[:version]}"
  end
  
  def render_ds_size doc, specs
    val = specs[:size].to_i.bytestring('%.1f%s').downcase
    val.sub(/\.?0+([a-z]?b)$/,'\1')
  end
  
  def render_ds_label doc, specs
    specs[:label]
  end

  def render_ds_profile_header ds
    dscd = ds.createDate
    if dscd.is_a?(Time)
      dscd = dscd.xmlschema
    end
    %{<foxml:datastream ID="#{ds.dsid}" STATE="#{ds.state}" CONTROL_GROUP="#{ds.controlGroup}" VERSIONABLE="#{ds.versionable}">\n  <foxml:datastreamVersion ID="#{ds.dsVersionID}" LABEL="#{ds.label}" CREATED="#{dscd}" MIMETYPE="#{ds.mimeType}">}
  end
  
end
