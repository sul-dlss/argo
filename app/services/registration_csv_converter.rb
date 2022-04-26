# frozen_string_literal: true

# Convert CSV to JSON for registration
class RegistrationCsvConverter
  include Dry::Monads[:result]

  # @param [String] csv_string CSV string
  # @return [Array<Result>] a list of registration requests suitable for passing off to dor-services-client
  def self.convert(csv_string:)
    new(csv_string:).convert
  end

  attr_reader :csv_string

  # @param [String] csv_string CSV string
  def initialize(csv_string:)
    @csv_string = csv_string
  end

  # @return [Result] an array of dry-monad results
  # Columns:
  #   0: administrative_policy_object (required)
  #   1: collection (optional)
  #   2: initial_workflow (required)
  #   3: content_type (required)
  #   4: reading_order (required if "content_type" is "book" or "image")
  #   5: source_id (required)
  #   6: catkey (optional)
  #   7: barcode (optional)
  #   8: label (required unless a catkey has been entered)
  #   9: rights_view (required)
  #  10: rights_download (required)
  #  11: rights_location (required if "view" or "download" uses "location-based")
  #  12: rights_controlledDigitalLending (optional: "true" is valid only when "view" is "stanford" and "download" is "none")
  #  13: project_name (optional)
  #  14: tags (optional, may repeat)

  def convert
    CSV.parse(csv_string, headers: true).map { |row| convert_row(row) }
  end

  def convert_row(row)
    catalog_links = row['catkey'] ? [{ catalog: 'symphony', catalogRecordId: row['catkey'], refresh: true }] : []

    model_params = {
      type: dro_type(row.fetch('content_type')),
      version: 1,
      label: row['catkey'] ? row['label'] : row.fetch('label'),
      administrative: {
        hasAdminPolicy: row.fetch('administrative_policy_object')
      },
      identification: {
        sourceId: row.fetch('source_id'),
        barcode: row['barcode'],
        catalogLinks: catalog_links
      }
    }

    model_params[:structural] = structural(row)
    model_params[:access] = access(row)
    model_params[:administrative][:partOfProject] = row['project_name'] if row['project_name'].present?

    tags = []
    tag_count = row.headers.count('tags')
    tag_count.times { |n| tags << row.field('tags', n + row.index('tags')) }
    model = Cocina::Models::RequestDRO.new(model_params)
    Success(model:,
            workflow: row.fetch('initial_workflow'),
            tags: tags.compact)
  rescue Cocina::Models::ValidationError => e
    Failure(e)
  end

  def dro_type(content_type)
    case content_type
    when 'Image'
      Cocina::Models::ObjectType.image
    when '3D'
      Cocina::Models::ObjectType.three_dimensional
    when 'Map'
      Cocina::Models::ObjectType.map
    when 'Media'
      Cocina::Models::ObjectType.media
    when 'Document'
      Cocina::Models::ObjectType.document
    when /^Manuscript/
      Cocina::Models::ObjectType.manuscript
    when 'Book (ltr)', 'Book (rtl)'
      Cocina::Models::ObjectType.book
    else
      Cocina::Models::ObjectType.object
    end
  end

  def structural(row)
    {}.tap do |structural|
      structural[:isMemberOf] = [row['collection']] if row['collection']
      structural[:hasMemberOrders] = [{ viewingDirection: row['reading_order'] }] if row['reading_order'].present?
    end
  end

  def access(row)
    {}.tap do |access|
      access[:view] = row.fetch('rights_view')
      access[:download] = row.fetch('rights_download')
      access[:location] = row.fetch('rights_location') if [access[:view], access[:download]].include?('location-based')
      access[:controlledDigitalLending] = row['rights_controlledDigitalLending'].presence || 'false'
    end
  end
end
