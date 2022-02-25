# frozen_string_literal: true

class StructureSerializer
  HEADERS = %w[resource_label resource_type sequence filename file_label publish
               shelve preserve rights_access rights_download mimetype role].freeze

  def self.as_csv(structural)
    new(structural).as_csv
  end

  def initialize(structural)
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
        yield [resource.label, type(resource), n, file.filename, file.label,
               to_yes_no(file.administrative.publish), to_yes_no(file.administrative.shelve),
               to_yes_no(file.administrative.sdrPreserve), file.access.view,
               file.access.download, file.hasMimeType, file.use]
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
