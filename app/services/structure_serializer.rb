# frozen_string_literal: true

class StructureSerializer
  HEADERS = %w[druid resource_label resource_type sequence filename file_label publish
               shelve preserve rights_view rights_download rights_location mimetype
               role file_language].freeze

  def self.as_csv(druid, structural)
    new(druid, structural).as_csv
  end

  def initialize(druid, structural)
    @druid = Druid.new(druid).without_namespace
    @structural = structural
  end

  def as_csv
    CSV.generate(headers: true) do |csv|
      csv << HEADERS
      rows do |row|
        csv << row
      end
    end
  end

  def rows
    Array(structural.contains).each.with_index(1) do |resource, n|
      resource.structural.contains.each do |file|
        yield [@druid, resource.label, type(resource), n, file.filename, file.label,
               to_yes_no(file.administrative.publish), to_yes_no(file.administrative.shelve),
               to_yes_no(file.administrative.sdrPreserve), file.access.view,
               file.access.download, file.access.location, file.hasMimeType, file.use,
               file.languageTag]
      end
    end
  end

  private

  attr_reader :structural

  def to_yes_no(bool)
    bool ? 'yes' : 'no'
  end

  # Provide a shortname version of the resource type
  def type(resource)
    resource.type.delete_prefix('https://cocina.sul.stanford.edu/models/resources/')
  end
end
