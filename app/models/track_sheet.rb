class TrackSheet
  attr_reader :druids

  def initialize(druids)
    @druids = druids
  end

  # @FIXME: This code needs to separate data and query logic from presentation.

  # @param [Array<String>] druids unqualified DRUID identifiers
  # @return [Prawn::Document] PDF document for the DRUIDs
  def generate_tracking_pdf
    # FIXME: why not search for all druids in one query?
    # FIXME: how about a MAX number of druids? And/Or a chunky use of enumeration?
    druids.each { |druid| find_or_create_in_solr_by_id(druid) }
    pdf = Prawn::Document.new(page_size: [5.5.in, 8.5.in])
    pdf.font('Courier')
    druids.each_with_index do |druid, i|
      generate_tracking_sheet(druid, pdf)
      pdf.start_new_page unless i + 1 == druids.length
    end
    pdf
  end

  protected

  # Adds one DRUID page to the PDF document
  # @param [String] druid unqualified DRUID identifier
  # @param [Prawn::Document] pdf document being built (document is modified)
  # @return [Prawn::Document] the same document
  def generate_tracking_sheet(druid, pdf)
    bc_width  = 2.25.in
    bc_height = 0.75.in

    top_margin = pdf.page.size[1] - pdf.bounds.absolute_top

    doc = nil
    begin
      doc = find_or_create_in_solr_by_id(druid)
    rescue
      pdf.text "DRUID #{druid} not found in index", size: 15, style: :bold, align: :center
      return pdf
    end

    barcode = Barby::Code128B.new(druid)
    barcode.annotate_pdf(
      pdf,
      width: bc_width,
      height: bc_height,
      x: (pdf.bounds.width / 2) - (bc_width / 2),
      y: (pdf.bounds.height - bc_height)
    )

    pdf.y -= (bc_height + 0.25.in)
    pdf.text druid, size: 15, style: :bold, align: :center
    pdf.y -= 0.5.in

    pdf.font('Courier', size: 10)
    pdf.table(doc_to_table(doc), column_widths: [100, 224], cell_style: { borders: [], padding: 0.pt })

    pdf.y -= 0.5.in

    pdf.font_size = 14
    pdf.text 'Tracking:'
    pdf.text ' '

    baseline = pdf.y - top_margin - pdf.font.ascender
    pdf.rectangle([0, baseline + pdf.font.ascender], pdf.font.ascender, pdf.font.ascender)
    pdf.indent(pdf.font.ascender + 4.pt) do
      pdf.text 'Scanned by:'
      pdf.indent(pdf.width_of('Scanned by:') + 0.125.in) do
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
    pdf
  end

  # @param [Hash] doc Solr document or to_solr Hash
  # @return [Array<Array<String>>] Complex array suitable for pdf.table()
  def doc_to_table(doc)
    table_data = []
    labels = doc['obj_label_ssim']
    label = (labels.nil? || labels.empty?) ? '' : labels.first
    label = label[0..110] + '...' if label.length > 110
    table_data.push(['Object Label:', label])
    table_data.push(['Project Name:', doc['project_tag_ssim'].to_s]) if doc['project_tag_ssim']

    tags = Array(doc['tag_ssim']).collect { |tag| tag =~ /^Project\s*:/ ? nil : tag.gsub(/\s+/, Prawn::Text::NBSP) }.compact
    table_data.push(['Tags:', tags.join("\n")]) if tags.length > 0
    table_data.push(['Catkey:',    Array(doc['catkey_id_ssim']).join(', ')]) if doc['catkey_id_ssim'].present?
    table_data.push(['Source ID:', Array(doc['source_id_ssim']).first]) if doc['source_id_ssim'].present?
    table_data.push(['Barcode:',   Array(doc['barcode_id_ssim']).first]) if doc['barcode_id_ssim'].present?
    table_data.push(['Date Printed:', Time.now.strftime('%c')])
    table_data
  end

  # @param [String] druid unqualified DRUID identifier
  # @return [Hash] doc from Solr or to_solr
  # @note To the extent we use Solr input filters or copyField(s), the Solr version will differ from the to_solr hash.
  # @note That difference shouldn't be important for the few known fields we use here.
  def find_or_create_in_solr_by_id(druid)
    doc = Dor::SearchService.query(%(id:"druid:#{druid}"), rows: 1)['response']['docs'].first
    return doc unless doc.nil?

    obj = Dor.load_instance "druid:#{druid}"
    solr_doc = obj.to_solr
    Dor::SearchService.solr.add(solr_doc)
    # Dor::SearchService.solr.add(solr_doc, :add_attributes => {:commitWithin => 1000})
    solr_doc
  end
end
