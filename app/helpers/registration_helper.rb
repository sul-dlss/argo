module RegistrationHelper

  def apo_list(*permission_keys)
    q = 'objectType_t:adminPolicy'
    unless permission_keys.empty?
      q += '(' + permission_keys.flatten.collect { |key| %{apo_register_permissions_t:"#{key}"} }.join(" OR ") + ')'
    end
    result = Dor::SearchService.query(q, :rows => 99999, :fl => 'id,tag_t,dc_title_t').docs
    result.sort! do |a,b|
      Array(a['tag_t']).include?('AdminPolicy : default') ? -1 : a['dc_title_t'].to_s <=> b['dc_title_t'].to_s
    end
    result.collect do |doc|
      [Array(doc['dc_title_t']).first,doc['id'].to_s]
    end
  end

  def apo_default_rights_list(*permission_keys)
    q = 'objectType_t:adminPolicy'
    unless permission_keys.empty?
      q += '(' + permission_keys.flatten.collect { |key| %{apo_register_permissions_t:"#{key}"} }.join(" OR ") + ')'
    end
    result = Dor::SearchService.query(q, :rows => 99999, :fl => 'id,tag_t,dc_title_t').docs
    result.sort! do |a,b|
      Array(a['tag_t']).include?('AdminPolicy : default') ? -1 : a['dc_title_t'].to_s <=> b['dc_title_t'].to_s
    end
    #for each apo, fetch the apo object so the rightsMetadata stream can be read, and the default permissions based on the chosen apo can be labeled as (apo default)
    default_rights=Array.new
    result.each do |apo|
      apo_object = Dor.find(apo['id'], :lightweight => true)
      adm_xml = apo_object.defaultObjectRights.ng_xml 
      added=false

      adm_xml.xpath('//rightsMetadata/access[@type=\'read\']/machine/group').each  do |read|
        #if read.value='Stanford'
        apo['rights'] = 'Stanford'+read.name
        added=true
        break
        #end
      end

      adm_xml.xpath('//rightsMetadata/access[@type=\'read\']/machine/world').each do |read|
        apo['rights'] = 'world'
        added=true
        break

      end

      if apo['rights'].nil?
        apo['rights'] = 'dark'
      end
    end
    result.collect do |doc|
      [Array( doc['rights']).first  ,doc['id'].to_s]
    end
  end

  def valid_object_types
    [
      ['Item','item'],
      ['Set','set'],
      ['Collection','collection'],
      ['Workflow Definition','workflow']
    ]
  end

  def valid_rights_options
    [
      ['World','world'],
      ['Stanford','stanford'],
      ['Dark (Preserve Only)','none']
    ]
  end

  def valid_content_types
    [
      'Book (flipbook, ltr)',
      'Book (flipbook, rtl)',
      'Book (image-only)',
      'Image',
      'File',
      'Manuscript (flipbook, ltr)',
      'Manuscript (flipbook, rtl)',
      'Manuscript (image-only)',
      'Map'
    ]
  end

  def metadata_sources
    [
      ['None','none'], #changed from label
      ['Symphony','symphony'], 
      ['Metadata Toolkit','mdtoolkit'],
      ['Label','label']
    ]
  end

  def generate_tracking_pdf(druids)
    pdf = Prawn::Document.new(:page_size => [5.5.in, 8.5.in])
    pdf.font('Courier')
    druids.each_with_index do |druid,i|
      generate_tracking_sheet(druid, pdf)
      pdf.start_new_page unless (i+1 == druids.length)
    end
    return pdf
  end

  def generate_tracking_sheet(druid, pdf)
    bc_width  = 2.25.in
    bc_height = 0.75.in

    top_margin = (pdf.page.size[1] - pdf.bounds.absolute_top)

    doc = Dor::SearchService.query(%{id:"druid:#{druid}"}, :rows => 1).docs.first
    
    if doc.nil?
      begin
         obj = Dor.load_instance 'druid:'+druid
         solr_doc = obj.to_solr
          Dor::SearchService.solr.add(solr_doc, :add_attributes => {:commitWithin => 1000}) unless obj.nil?
          doc=solr_doc
      rescue
        pdf.text "DRUID #{druid} not found in index", :size => 15, :style => :bold, :align => :center
      end
      return
    end

    ids = Array(doc['mods_identifier_t']).collect do |id| 
      result = id.split(/:/,2)
      result[0] = "#{result[0].titleize}:"
      result
    end.reject { |id| id[0] =~ /DRUID/i }

    barcode = Barby::Code128B.new(druid)
    barcode.annotate_pdf(pdf, :width => bc_width, :height => bc_height, 
    :x => ((pdf.bounds.width / 2) - (bc_width / 2)), :y => (pdf.bounds.height - bc_height))

    pdf.y -= (bc_height + 0.25.in)
    pdf.text druid, :size => 15, :style => :bold, :align => :center
    pdf.y -= 0.5.in

    pdf.font('Courier', :size => 10)
    label = doc['obj_label_t'].first
    if label.length > 110
      label = label[0..110] + '...'
    end
    table_data = [['Object Label:',label]]
    if project_name = doc['project_tag_t']
      table_data.push(['Project Name:',project_name.to_s])
    end
    table_data.push(['Date Printed:',Time.now.strftime('%c')])
    if doc['source_id_t'].present?
      table_data.push(["Source ID:",Array(doc['source_id_t']).first])
    end
    table_data += ids
    tags = Array(doc['tag_t']).collect { |tag| tag =~ /^Project\s*:/ ? nil : tag.gsub(/\s+/,  Prawn::Text::NBSP) }.compact
    if tags.length > 0
      table_data.push(["Tags:",tags.join("\n")])
    end
    pdf.table(table_data, :column_widths => [100,224],
    :cell_style => { :borders => [], :padding => 0.pt })

    pdf.y -= 0.5.in

    pdf.font_size = 14
    pdf.text "Tracking:"
    pdf.text " "

    baseline = pdf.y - top_margin - pdf.font.ascender
    pdf.rectangle([0,baseline+pdf.font.ascender],pdf.font.ascender,pdf.font.ascender)
    pdf.indent(pdf.font.ascender + 4.pt) do
      pdf.text "Scanned by:"
      pdf.indent(pdf.width_of("Scanned by:") + 0.125.in) do
        pdf.line 0, baseline, pdf.bounds.width, baseline
      end
    end
    pdf.stroke

    pdf.y -= 0.5.in
    pdf.text('Notes:')
    pdf.stroke do
      while (pdf.y >= pdf.bounds.absolute_bottom)
        baseline = pdf.y - top_margin - pdf.font.height
        pdf.line 0, baseline, pdf.bounds.width, baseline
        pdf.y -= pdf.font.height * 1.5
      end
    end
  end

  def extract_identifiers(xml)
    xml.search('/mods:mods/mods:identifier | /msDesc/msIdentifier/*', { 'mods' => 'http://www.loc.gov/mods/v3' }).collect do |elem|
      unless (elem.text.empty?)
        ["#{(elem['displayLabel'] or elem.name).titleize}:", elem.text]
      end
    end.compact
  end

end
