# frozen_string_literal: true

class StructureSerializer
  def self.as_csv(structural)
    attributes = %w[resource_label resource_type sequence filename file_label publish shelve preserve rights_access rights_download mimetype role]

    CSV.generate(headers: true) do |csv|
      csv << attributes
      Array(structural.contains).each.with_index(1) do |resource, n|
        resource.structural.contains.each do |file|
          csv << [resource.label, type(resource), n, file.filename, file.label,
                  to_yes_no(file.administrative.publish), to_yes_no(file.administrative.shelve),
                  to_yes_no(file.administrative.sdrPreserve), file.access.view,
                  file.access.download, file.hasMimeType, file.use]
        end
      end
    end
  end

  def self.to_yes_no(bool)
    bool ? 'yes' : 'no'
  end
  private_class_method :to_yes_no

  # Provide a shortname version of the resource type
  def self.type(resource)
    resource.type.delete_prefix('https://cocina.sul.stanford.edu/models/resources/')
  end
  private_class_method :type
end
