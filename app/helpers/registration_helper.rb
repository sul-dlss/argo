module RegistrationHelper

  def apo_list(*permission_keys)
    q = 'objectType_t:adminPolicy'
    unless permission_keys.empty?
      q += '(' + permission_keys.flatten.collect { |key| %{apo_register_permissions_t:"#{key}"} }.join(" OR ") + ')'
    end
    result = Dor::SearchService.query(q, :rows => 99999, :fl => ['id','tag_t','dc_title_t']).docs
    result.sort! do |a,b|
      Array(a['tag_t']).include?('AdminPolicy : default') ? -1 : a['dc_title_t'].to_s <=> b['dc_title_t'].to_s
    end
    result
    result.collect! do |doc|
      [doc['dc_title_t'].to_s,doc['id'].to_s]
    end
  end

  def metadata_sources
    [
      ['None','label'],
      ['Symphony','symphony'], 
      ['Metadata Toolkit','mdtoolkit']
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

    doc = Reference.find(druid)
    if doc.nil?
      pdf.text "DRUID #{druid} not found in index", :size => 15, :style => :bold, :align => :center
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
    table_data += ids
    puts "#{druid}: #{table_data.inspect}"
    pdf.table(table_data, :column_widths => [100,224],
      :cell_style => { :borders => [], :padding => 2.pt })

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
