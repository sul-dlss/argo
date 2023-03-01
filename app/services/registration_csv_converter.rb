# frozen_string_literal: true

# Convert CSV to JSON for registration
class RegistrationCsvConverter
  include Dry::Monads[:result]

  CONTENT_TYPES = [Cocina::Models::ObjectType.book,
    Cocina::Models::ObjectType.document,
    Cocina::Models::ObjectType.file,
    Cocina::Models::ObjectType.geo,
    Cocina::Models::ObjectType.image,
    Cocina::Models::ObjectType.map,
    Cocina::Models::ObjectType.media,
    Cocina::Models::ObjectType.three_dimensional,
    Cocina::Models::ObjectType.webarchive_binary,
    Cocina::Models::ObjectType.webarchive_seed].freeze

  # @param [String] csv_string CSV string
  # @return [Array<Result>] a list of registration requests suitable for passing off to dor-services-client
  def self.convert(csv_string:, params: {})
    new(csv_string:, params:).convert
  end

  attr_reader :csv_string, :params

  # @param [String] csv_string CSV string
  # @param [Hash] params that can be used instead of CSV columns. Keys are same as column headers.
  def initialize(csv_string:, params:)
    @csv_string = csv_string
    @params = params
  end

  # @return [Result] an array of dry-monad results
  # Columns:
  #   0: administrative_policy_object (required)
  #   1: collection (optional)
  #   2: initial_workflow (required)
  #   3: content_type (required)
  #   4: reading_order (required if "content_type" is "book" or "image")
  #   5: source_id (required)
  #   6: catkey or folio_id (optional)
  #   7: barcode (optional)
  #   8: label (required unless a catkey or folio_id have been entered)
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
    model = Cocina::Models::RequestDRO.new(model_params(row))
    Success(model:,
      workflow: params[:initial_workflow] || row.fetch("initial_workflow"),
      tags: tags(row))
  rescue Cocina::Models::ValidationError => e
    Failure(e)
  end

  def model_params(row)
    model_params = {
      type: dro_type(params[:content_type] || row.fetch("content_type")),
      version: 1,
      label: row[catalog_record_id_column] ? row["label"] : row.fetch("label"),
      administrative: {
        hasAdminPolicy: params[:administrative_policy_object] || row.fetch("administrative_policy_object")
      },
      identification: {
        sourceId: row.fetch("source_id"),
        barcode: row["barcode"],
        catalogLinks: catalog_links(row)
      }.compact
    }

    model_params[:structural] = structural(row)
    model_params[:access] = access(row)
    project_name = params[:project_name] || row["project_name"]
    model_params[:administrative][:partOfProject] = project_name if project_name.present?
    model_params
  end

  def catalog_links(row)
    row[catalog_record_id_column] ? [{catalog: CatalogRecordId.type, catalogRecordId: row[catalog_record_id_column], refresh: true}] : []
  end

  def catalog_record_id_column
    CatalogRecordId.label.downcase.tr(" ", "_")
  end

  def tags(row)
    tags = params[:tags] || []
    if tags.empty?
      tag_count = row.headers.count("tags")
      tag_count.times { |n| tags << row.field("tags", n + row.index("tags")) }
    end
    tags.compact
  end

  def dro_type(content_type)
    # for CSV registration, we already have the URI
    return content_type if CONTENT_TYPES.include?(content_type)

    case content_type.downcase
    when "image"
      Cocina::Models::ObjectType.image
    when "3d"
      Cocina::Models::ObjectType.three_dimensional
    when "map"
      Cocina::Models::ObjectType.map
    when "media"
      Cocina::Models::ObjectType.media
    when "document"
      Cocina::Models::ObjectType.document
    when /^manuscript/
      Cocina::Models::ObjectType.manuscript
    when "book", "book (ltr)", "book (rtl)"
      Cocina::Models::ObjectType.book
    when "geo"
      Cocina::Models::ObjectType.geo
    when "webarchive-seed"
      Cocina::Models::ObjectType.webarchive_seed
    when "webarchive-binary"
      Cocina::Models::ObjectType.webarchive_binary
    else
      Cocina::Models::ObjectType.object
    end
  end

  def structural(row)
    {}.tap do |structural|
      collection = params[:collection] || row["collection"]
      structural[:isMemberOf] = [collection] if collection
      reading_order = params[:reading_order] || row["reading_order"]
      structural[:hasMemberOrders] = [{viewingDirection: reading_order}] if reading_order.present?
    end
  end

  def access(row)
    {}.tap do |access|
      access[:view] = params[:rights_view] || row["rights_view"]
      access[:download] = params[:rights_download] || row["rights_download"] || ("none" if %w[citation-only dark].include? access[:view])
      access[:location] = (params[:rights_location] || row.fetch("rights_location")) if [access[:view], access[:download]].include?("location-based")
      cdl = params[:rights_controlledDigitalLending] || row["rights_controlledDigitalLending"]
      access[:controlledDigitalLending] = ActiveModel::Type::Boolean.new.cast(cdl) if cdl.present?
    end.compact
  end
end
