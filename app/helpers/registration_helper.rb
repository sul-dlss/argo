# Helper methods defined here can be accessed in any controller or view in the application

RubyDorServices.helpers do

  def apo_list(search = nil)
    q = 'object_type_field:adminPolicy'
    q += " dc_title_field:#{search.downcase}*" unless search.to_s.empty?
    result = Dor::SearchService.gsearch(:q => q)['response']['docs']
    result.sort! do |a,b|
      a['tag_field'].include?('AdminPolicy : default') ? -1 : a['dc_title_field'].to_s <=> b['dc_title_field'].to_s
    end
    result.collect! do |doc|
      [doc['dc_title_field'].to_s,doc['PID'].to_s]
    end
  end
  
  def object_location(pid)
    settings.fedora_base.merge("objects/#{pid}").to_s
  end
  
  def metadata_sources
    [
      ['Symphony (catkey)','catkey'], 
      ['Symphony (barcode)','barcode'], 
      ['Metadata Toolkit (druid)','mdtoolkit'], 
      ['None (label only)','label']
    ]
  end

  def generate_tracking_sheet(druid, pdf)
    bc_width  = 2.25.in
    bc_height = 0.75.in
    
    top_margin = (pdf.page.size[1] - pdf.bounds.absolute_top)

    obj = Dor::Base.load_instance("druid:#{druid}")
    xml = Nokogiri::XML(obj.fetch_descMetadata_datastream)
    ids = extract_identifiers(xml).reject { |id| id[0] =~ /DRUID/i }

    barcode = Barby::Code128B.new(druid)
    barcode.annotate_pdf(pdf, :width => bc_width, :height => bc_height, 
      :x => ((pdf.bounds.width / 2) - (bc_width / 2)), :y => (pdf.bounds.height - bc_height))

    pdf.font('Courier', :size => 10)
    pdf.y -= (bc_height + 0.25.in)
    pdf.text druid, :size => 15, :style => :bold, :align => :center
    pdf.y -= 0.5.in


    table_data = [['Object Label:',obj.label]]
    if obj.identity_metadata.tags.find { |tag| tag.value =~ /^Project\s*:\s*(.+)/ }
      table_data.push(['Project Name:',$1])
    end
    table_data.push(['Date Printed',Time.now.strftime('%c')])
    table_data += ids
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