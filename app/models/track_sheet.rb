# frozen_string_literal: true

class TrackSheet
  # Directory containing the vendored TrueType fonts used to render the PDF.
  # A TTF font is required (instead of Prawn's built-in AFM fonts) so that
  # titles and other metadata containing UTF-8 characters can be rendered
  # without raising Prawn::Errors::IncompatibleStringEncoding.
  FONT_DIR = Rails.root.join('vendor/fonts')

  # Pan-Unicode font used in place of the built-in "Courier" AFM font. GNU
  # Unifont covers the entire Basic Multilingual Plane in a single TrueType
  # file (Latin, Cyrillic, Greek, Arabic, CJK, Hangul, Kana, etc.), so titles
  # and metadata in any of those scripts render rather than dropping out. It is
  # a 16px bitmap font, so glyphs render "chunky"; that is an accepted tradeoff
  # for universal coverage on this utilitarian tracking sheet. Its combining
  # marks are zero-advance, so diacritics and the ALA-LC "i͡a" tie (U+0361)
  # overprint their base characters. Unifont ships a single weight, so every
  # style variant below points at the same file.
  FONT_FAMILY = 'Unifont'

  attr_reader :druids

  # @param [Array<String>] druids a list of non-namespaced druids
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
    register_fonts(pdf)
    pdf.font(FONT_FAMILY)
    druids.each_with_index do |druid, i|
      generate_tracking_sheet(druid, pdf)
      pdf.start_new_page unless i + 1 == druids.length
    end
    pdf
  end

  private

  # Registers the vendored TrueType font family with the PDF document so that
  # UTF-8 text can be rendered.
  # @param [Prawn::Document] pdf document being built (document is modified)
  def register_fonts(pdf)
    unifont = FONT_DIR.join('unifont-15.0.06.ttf').to_s
    pdf.font_families.update(
      FONT_FAMILY => { normal: unifont, bold: unifont, italic: unifont, bold_italic: unifont }
    )
  end

  # Adds one DRUID page to the PDF document
  # @param [String] druid unqualified DRUID identifier
  # @param [Prawn::Document] pdf document being built (document is modified)
  # @return [Prawn::Document] the same document
  def generate_tracking_sheet(druid, pdf)
    bc_width = 2.25.in
    bc_height = 0.75.in

    top_margin = pdf.page.size[1] - pdf.bounds.absolute_top

    doc = nil
    begin
      doc = find_or_create_in_solr_by_id(druid)
    rescue StandardError
      pdf.text "DRUID #{druid} not found in index", size: 15, style: :bold, align: :center
      return pdf
    end

    barcode = Barby::Code128B.new(druid.delete_prefix('druid:'))
    barcode.annotate_pdf(
      pdf,
      width: bc_width,
      height: bc_height,
      x: (pdf.bounds.width / 2) - (bc_width / 2),
      y: (pdf.bounds.height - bc_height)
    )

    pdf.y -= (bc_height + 0.25.in)
    pdf.text druid.delete_prefix('druid:'), size: 15, style: :bold, align: :center
    pdf.y -= 0.5.in

    pdf.font(FONT_FAMILY, size: 10)
    pdf.table(doc_to_table(doc), column_widths: [120, 204], cell_style: { borders: [], padding: [0, 6, 0, 0] })

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
      while pdf.y >= pdf.bounds.absolute_bottom
        baseline = pdf.y - top_margin - pdf.font.height
        pdf.line 0, baseline, pdf.bounds.width, baseline
        pdf.y -= pdf.font.height * 1.5
      end
    end
    pdf
  end

  # @param [Solr Document] doc Solr document
  # @return [Array<Array<String>>] Complex array suitable for pdf.table()
  def doc_to_table(solr_doc)
    table_data = []
    title = normalize(solr_doc.title_display).truncate(110)
    table_data.push(['Object Title:', title])
    table_data.push(['Project Name:', normalize(solr_doc.project_tag)]) if solr_doc.project_tag

    tags = solr_doc.tags.filter_map do |tag|
      /^Project\s*:/.match?(tag) ? nil : normalize(tag).gsub(/\s+/, Prawn::Text::NBSP)
    end
    table_data.push(['Tags:', tags.join("\n")]) unless tags.empty?
    table_data.push(["#{CatalogRecordId.label}:", solr_doc.catalog_record_id]) if solr_doc.catalog_record_id.present?
    table_data.push(['Source ID:', solr_doc.source_id]) if solr_doc.source_id.present?
    table_data.push(['Barcode:', solr_doc.barcode]) if solr_doc.barcode.present?
    table_data.push(['Date Printed:', Time.zone.now.strftime('%c')])
    table_data
  end

  # Normalizes text to Unicode NFC (canonical composition) so that composed
  # diacritics (e.g. "e" + combining acute) render as a single glyph in the PDF
  # rather than as a base letter with a separately positioned combining mark.
  # @param [String, nil] value
  # @return [String]
  def normalize(value) = value.to_s.unicode_normalize(:nfc)

  # @param [String] druid unqualified DRUID identifier
  # @return [SolrDocument] SolrDocument build from hash of solr query
  # @note To the extent we use Solr input filters or copyField(s), the Solr version will differ from the to_solr hash.
  # @note That difference shouldn't be important for the few known fields we use here.
  def find_or_create_in_solr_by_id(druid)
    namespaced_druid = Druid.new(druid).with_namespace
    doc = SearchService.query(%(id:"#{namespaced_druid}"), rows: 1)['response']['docs'].first
    return SolrDocument.new(doc) unless doc.nil?

    Dor::Services::Client.object(namespaced_druid).reindex
    SolrDocument.new(SearchService.query(%(id:"#{namespaced_druid}"), rows: 1)['response']['docs'].first)
  end
end
