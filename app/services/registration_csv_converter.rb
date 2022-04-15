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
  #   0: APO (required)
  #   1: Collection
  #   2: Rights (required)
  #   3: Initial Workflow (required)
  #   4: Content Type (required)
  #   5: Project Name
  #   6: Tags (not required, may repeat)
  #   7: Catkey
  #   8: Source ID (required)
  #   9: Label (required if no Catkey)
  def convert
    CSV.parse(csv_string, headers: true).map { |row| convert_row(row) }
  end

  def convert_row(row)
    catalog_links = row['Catkey'] ? [{ catalog: 'symphony', catalogRecordId: row['Catkey'], refresh: true }] : []

    model_params = {
      type: dro_type(row.fetch('Content Type')),
      version: 1,
      label: row['Catkey'] ? row['Label'] : row.fetch('Label'),
      administrative: {
        hasAdminPolicy: row.fetch('APO')
      },
      identification: {
        sourceId: row.fetch('Source ID'),
        catalogLinks: catalog_links
      }
    }

    structural = {}
    structural[:isMemberOf] = [row['Collection']] if row['Collection']
    model_params[:structural] = structural
    model_params[:access] = CocinaDroAccess.from_form_value(row['Rights']).value_or(nil)
    model_params[:administrative][:partOfProject] = row['Project Name'] if row['Project Name'].present?

    tags = []
    tag_count = row.headers.count('Tags')
    tag_count.times { |n| tags << row.field('Tags', n + row.index('Tags')) }
    model = Cocina::Models::RequestDRO.new(model_params)
    Success(model:,
            workflow: row.fetch('Initial Workflow'),
            tags: tags.compact)
  rescue Cocina::Models::ValidationError => e
    Failure(e.message)
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
end
