# encoding: utf-8
module RegistrationHelper

  def apo_list(*permission_keys)
    q = 'objectType_ssim:adminPolicy AND !tag_ssim:"Project : Hydrus"'
    unless permission_keys.empty?
      q += '(' + permission_keys.flatten.collect { |key| %{apo_register_permissions_ssim:"#{key}"} }.join(" OR ") + ')'
    end
    result = Dor::SearchService.query(q, :rows => 99999, :fl => 'id,tag_ssim,dc_title_tesim').docs
    result.sort! do |a,b|
      Array(a['tag_ssim']).include?('AdminPolicy : default') ? -1 : a['dc_title_tesim'].to_s <=> b['dc_title_tesim'].to_s
    end
    result.collect do |doc|
      [Array(doc['dc_title_tesim']).first,doc['id'].to_s]
    end
  end

  def utf_val
    "hello world ©"
  end

  def valid_object_types
    [
      %w(Item item),
      ['Workflow Definition','workflow']
    ]
  end

  def valid_rights_options
    [
      %w(World world),
      %w(Stanford stanford),
      ['Dark (Preserve Only)','dark'],
      %w(None none)
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
      %w(Auto auto),
      %w(None none)
    ]
  end

  def generate_tracking_pdf(druids)
    # FIXME: why not search for all druids in one query?
    druids.each do |druid|
      doc = Dor::SearchService.query(%{id:"druid:#{druid}"}, :rows => 1).docs.first
      next unless doc.nil?
      obj = Dor.load_instance 'druid:'+druid
      solr_doc = obj.to_solr
      Dor::SearchService.solr.add(solr_doc, :add_attributes => {:commitWithin => 1000}) unless obj.nil?
    end
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
        obj = Dor.load_instance "druid:#{druid}"
        solr_doc = obj.to_solr
        Dor::SearchService.solr.add(solr_doc, :add_attributes => {:commitWithin => 1000}) unless obj.nil?
        doc = Dor::SearchService.query(%{id:"druid:#{druid}"}, :rows => 1).docs.first
      rescue
        pdf.text "DRUID #{druid} not found in index", :size => 15, :style => :bold, :align => :center
      end
      return
    end

    barcode = Barby::Code128B.new(druid)
    barcode.annotate_pdf(pdf, :width => bc_width, :height => bc_height,
    :x => ((pdf.bounds.width / 2) - (bc_width / 2)), :y => (pdf.bounds.height - bc_height))

    pdf.y -= (bc_height + 0.25.in)
    pdf.text druid, :size => 15, :style => :bold, :align => :center
    pdf.y -= 0.5.in

    pdf.font('Courier', :size => 10)

    table_data = []

    labels = doc['obj_label_ssim']
    label = (labels.nil? || labels.empty?) ? '' : labels.first
    label = label[0..110] + '...' if label.length > 110
    table_data.push(['Object Label:', label])

    if project_name = doc['project_tag_ssim']
      table_data.push(['Project Name:', project_name.to_s])
    end
    
    tags = Array(doc['tag_ssim']).collect { |tag| tag =~ /^Project\s*:/ ? nil : tag.gsub(/\s+/,  Prawn::Text::NBSP) }.compact
    table_data.push(["Tags:", tags.join("\n")]) if tags.length > 0
    table_data.push(["Catkey:", Array(doc['catkey_id_ssim']).join(", ")]) if doc['catkey_id_ssim'].present?
    table_data.push(["Source ID:", Array(doc['source_id_ssim']).first]) if doc['source_id_ssim'].present?
    table_data.push(["Barcode:", Array(doc['barcode_id_ssim']).first]) if doc['barcode_id_ssim'].present?
    table_data.push(["Date Printed:", Time.now.strftime('%c')])

    pdf.table(table_data, :column_widths => [100,224], :cell_style => { :borders => [], :padding => 0.pt })

    pdf.y -= 0.5.in

    pdf.font_size = 14
    pdf.text "Tracking:"
    pdf.text " "

    baseline = pdf.y - top_margin - pdf.font.ascender
    pdf.rectangle([0, baseline+pdf.font.ascender], pdf.font.ascender, pdf.font.ascender)
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
        ["#{(elem['displayLabel'] || elem.name).titleize}:", elem.text]
      end
    end.compact
  end

end
